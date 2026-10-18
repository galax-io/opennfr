#!/usr/bin/env bash
#
# check-linkage.sh — verify the issue ↔ PR ↔ milestone contract (see AGENTS.md "Milestones (ALWAYS)").
# Run `scripts/check-linkage.sh --help` for full usage.

set -euo pipefail

usage() {
  cat <<'EOF'
check-linkage.sh — verify the issue <-> PR <-> milestone contract (see AGENTS.md "Milestones (ALWAYS)").

What each entity owes (this script enforces it):
  Issue      belongs to exactly one milestone; closed only when its fix is on main.
  PR         carries its milestone + a real closing link (Closes #<issue>) for every issue it
             closes; every linked issue sits in that same milestone. A PR may close several.
  Milestone  one release (vX.Y.Z); tag only when every issue is closed and every PR merged.
  Every PR   of a product repository links a feature of the backlog: "Part of <backlog>#N" (or a
             closing link) to an issue whose milestone says "Release: business". A bot's PR (bot
             author, or a dependabot/ or update/ branch) and the backlog's own PRs are exempt.
             Maintenance with no feature of its own links the standing feature of the active
             business milestone, the issue with the label standing.
  Feature    an issue in the backlog repository whose milestone says "Release: business" on a
             line of its own. A PR writes "Part of owner/repo#N" for it; the same-milestone
             rule is skipped for that link. The PR still carries its own version milestone.

Usage:
  scripts/check-linkage.sh --pr <N>          # GATE one PR: milestone + Closes #issue + same milestone
  scripts/check-linkage.sh --for-tag vX.Y.Z  # GATE a release: tag-readiness of that version's milestone
  scripts/check-linkage.sh [milestone]       # audit a milestone (default: lowest-numbered open)
  scripts/check-linkage.sh --tag [ms]        # also assert tag-readiness (all issues closed, all PRs merged)
  scripts/check-linkage.sh --help

Env:
  REPO=owner/name          # override repo (default: gh repo view of the current checkout)
  BACKLOG_REPO=owner/name  # the repository whose business milestones hold features
                           # (default: galax-io/galaxio-sdlc-backlog)
  BACKLOG_READ_TOKEN=token # a read-only token for the backlog repository (Issues and Metadata). The
                           # backlog is private, so the job's own token cannot read it; this one is used
                           # for calls about the backlog and for nothing else.
  FEATURE_LINK=required|optional   # required (default): a PR without a feature of the backlog fails
                           # the gate and warns in the audit. optional only for a repository not yet on the rule.

Exit: 0 all rules hold | 1 at least one violation | 2 usage/prereq error.
EOF
}

for bin in gh jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "error: '$bin' not found on PATH" >&2; exit 2; }
done

REPO="${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
[ -n "$REPO" ] || { echo "error: cannot determine repo — run inside a GitHub checkout or set REPO=owner/name" >&2; exit 2; }

BACKLOG_REPO="${BACKLOG_REPO:-galax-io/galaxio-sdlc-backlog}"
FEATURE_LINK="${FEATURE_LINK:-required}"
case "$FEATURE_LINK" in required|optional) ;; *) echo "error: FEATURE_LINK must be required or optional, not '$FEATURE_LINK'" >&2; exit 2 ;; esac

TAG_MODE=0
MS=""
PR_NUM=""
FOR_TAG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tag)      TAG_MODE=1 ;;
    --pr)       shift; PR_NUM="${1:-}"
                [[ "$PR_NUM" =~ ^[0-9]+$ ]] || { echo "error: --pr needs a numeric PR id" >&2; exit 2; } ;;
    --for-tag)  shift; FOR_TAG="${1:-}"
                [[ "$FOR_TAG" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "error: --for-tag needs vX.Y.Z" >&2; exit 2; } ;;
    --help|-h)  usage; exit 0 ;;
    [0-9]*)     MS="$1" ;;
    *)          echo "error: unknown argument '$1'" >&2; usage; exit 2 ;;
  esac
  shift
done

# "Part of owner/repo#N" at the start of a line: the link a PR writes for a feature of the backlog.
gh_for() { # owner/repo, gh arguments: gh, with BACKLOG_READ_TOKEN when the repository is the backlog
  local repo="$1"; shift
  if [ "$repo" = "$BACKLOG_REPO" ] && [ -n "${BACKLOG_READ_TOKEN:-}" ]; then GH_TOKEN="$BACKLOG_READ_TOKEN" gh "$@"; else gh "$@"; fi
}
BACKLOG_SEEN=""
backlog_readable() { # whether this job can read the backlog repository (asked once)
  if [ -z "$BACKLOG_SEEN" ]; then
    if gh_for "$BACKLOG_REPO" api "repos/$BACKLOG_REPO" --silent >/dev/null 2>&1; then BACKLOG_SEEN=yes; else BACKLOG_SEEN=no; fi
  fi
  [ "$BACKLOG_SEEN" = yes ]
}
cannot_read_backlog() { # text of the failure that names what is missing
  printf 'cannot read the backlog %s with this job'"'"'s token, so a feature link cannot be checked: give the job BACKLOG_READ_TOKEN, a read-only token for %s (Issues and Metadata)' "$BACKLOG_REPO" "$BACKLOG_REPO"
}
feature_ms() { # owner/repo#N -> the business milestone's title when the issue is a feature of the backlog
  [ "${1%#*}" = "$BACKLOG_REPO" ] || return 0
  gh_for "${1%#*}" issue view "${1##*#}" --repo "${1%#*}" --json milestone -q '
    select(.milestone != null and ((.milestone.description // "")
      | test("(^|\n)[ \t]*Release:[ \t]*business[ \t]*\r?(\n|$)"; "i"))) | .milestone.title' 2>/dev/null || true
}
part_of_refs() { # pr-json -> owner/repo#N of every "Part of" line that names a repository
  jq -r '.body // ""' <<<"$1" \
    | grep -iE '^[[:space:]]*part of +[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+' \
    | grep -oE '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+' || true
}
closes_refs() { # pr-json -> owner/repo#N of every closing keyword that names a repository
  jq -r '.body // ""' <<<"$1" \
    | grep -oiE '(^|[^[:alnum:]_])(close[sd]?|fix(e[sd])?|resolve[sd]?):? +[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+' \
    | grep -oE '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+' || true
}
is_bot_pr() { # pr-json -> succeeds when a bot opened it: a bot author, or Dependabot's or Scala Steward's branch
  jq -e '(.author.is_bot == true) or ((.author.login // "") | test("\\[bot\\]$|^app/")) or ((.headRefName // "") | test("^(dependabot|update)/"))' <<<"$1" >/dev/null 2>&1
}
feature_refs() { # pr-json -> every Part of / closing link that is a feature of the backlog
  local r
  { part_of_refs "$1"; closes_refs "$1"; } | awk 'NF && !seen[$0]++' | while read -r r; do
    [ -z "$(feature_ms "$r")" ] || echo "$r"
  done
}
has_feature_link() { # pr-json -> succeeds when it links a feature of the backlog
  local r
  for r in $(part_of_refs "$1"); do [ -z "$(feature_ms "$r")" ] || return 0; done
  return 1
}

# Gate one PR (the merge gate). Fails if the PR is missing a milestone, closes no
# issue, or closes an issue in a different milestone. Strict: requires a registered
# GitHub closing link (no body-text fallback — that lenient path is audit-mode only).
if [ -n "$PR_NUM" ]; then
  pj=$(gh pr view "$PR_NUM" --repo "$REPO" --json number,title,state,milestone,closingIssuesReferences,body,author,headRefName) \
    || { echo "error: PR #$PR_NUM not found in $REPO" >&2; exit 2; }
  p_title=$(jq -r '.title' <<<"$pj")
  p_ms=$(jq -r '.milestone.title // ""' <<<"$pj")
  p_closes=$(jq -r '.closingIssuesReferences[]?.number' <<<"$pj")
  e=0
  printf 'PR #%s  %s\n' "$PR_NUM" "$p_title"
  if [ -z "$p_ms" ]; then printf '  ✗ no milestone — assign one (gh pr edit %s --milestone "…")\n' "$PR_NUM"; e=1
  else printf '  ✓ milestone: %s\n' "$p_ms"; fi
  f_linked=0
  for r in $(feature_refs "$pj"); do
    f=$(feature_ms "$r")
    [ -z "$f" ] || { printf '  ✓ links %s (feature of business milestone "%s")\n' "$r" "$f"; f_linked=1; }
  done
  # Every PR belongs to a feature of the backlog; the backlog's own PRs and bots' are exempt.
  if [ "$FEATURE_LINK" = required ] && [ "$REPO" != "$BACKLOG_REPO" ] && [ "$f_linked" = 0 ] && ! { [ -n "$({ part_of_refs "$pj"; closes_refs "$pj"; } | grep -F "$BACKLOG_REPO#" || true)" ] && ! backlog_readable; }; then
    if is_bot_pr "$pj"; then printf '  ✓ a bot'"'"'s PR needs no feature of the backlog\n'
    else
      printf '  ✗ links no feature of the backlog — add "Part of %s#<feature>" (maintenance with no feature of its own: the standing feature of the active business milestone, the issue with the label standing)\n' "$BACKLOG_REPO"; e=1
    fi
  fi
  unread=0
  if [ "$f_linked" = 0 ] && [ -n "$({ part_of_refs "$pj"; closes_refs "$pj"; } | grep -F "$BACKLOG_REPO#" || true)" ] && ! backlog_readable; then
    printf '  ✗ links the backlog, but %s\n' "$(cannot_read_backlog)"; e=1; unread=1
  fi
  if [ "$unread" = 1 ]; then :
  elif [ -z "$p_closes" ] && [ "$f_linked" = 1 ]; then :
  elif [ -z "$p_closes" ]; then
    printf '  ✗ closes no issue — add "Closes #<issue>" to the PR body\n'; e=1
  else
    for i in $p_closes; do
      i_ms=$(gh issue view "$i" --repo "$REPO" --json milestone -q '.milestone.title // ""' 2>/dev/null || echo "")
      if [ "$i_ms" = "$p_ms" ]; then printf '  ✓ closes #%s (same milestone)\n' "$i"
      else printf '  ✗ closes #%s but its milestone is "%s", not "%s"\n' "$i" "${i_ms:-none}" "$p_ms"; e=1; fi
    done
  fi
  if [ "$e" = 0 ]; then printf 'PASS: PR #%s is well-formed.\n' "$PR_NUM"; exit 0; fi
  printf 'FAIL: PR #%s is malformed — fix the above before merge.\n' "$PR_NUM"; exit 1
fi

# Map a release version (vX.Y.Z) to its milestone, then assert tag-readiness on it.
# Patch versions map to the vX.Y.0 milestone (e.g. v1.23.1 -> "v1.23.0 …").
if [ -n "$FOR_TAG" ]; then
  v="${FOR_TAG#v}"; minor="v${v%.*}.0"
  MS=$(gh api "repos/$REPO/milestones?state=all&per_page=100" \
        | jq -r --arg t "$minor" 'map(select(.title | startswith($t))) | .[0].number // empty')
  [ -n "$MS" ] || { echo "error: no milestone whose title starts with '$minor' for tag $FOR_TAG" >&2; exit 2; }
  TAG_MODE=1
fi

# Default to the lowest-numbered open milestone (the "active" one).
if [ -z "$MS" ]; then
  MS=$(gh api "repos/$REPO/milestones?state=open&per_page=100" --jq 'sort_by(.number) | .[0].number // empty')
  [ -n "$MS" ] || { echo "error: no open milestone found in $REPO" >&2; exit 2; }
fi

ms_json=$(gh api "repos/$REPO/milestones/$MS") || { echo "error: milestone #$MS not found in $REPO" >&2; exit 2; }
ms_title=$(jq -r '.title' <<<"$ms_json")
ms_state=$(jq -r '.state' <<<"$ms_json")

errors=0
warns=0
err()  { printf '  ✗ %s\n' "$1"; errors=$((errors + 1)); }
warn() { printf '  ! %s\n' "$1"; warns=$((warns + 1)); }
ok()   { printf '  ✓ %s\n' "$1"; }

printf 'Repo:      %s\n' "$REPO"
printf 'Milestone: #%s  %s  (%s)\n' "$MS" "$ms_title" "$ms_state"
[ "$TAG_MODE" = 1 ] && printf 'Mode:      tag-readiness\n'
printf '\n'

# All issues + PRs carrying this milestone (REST returns both; PRs carry a .pull_request key).
items=$(gh api --paginate --slurp "repos/$REPO/issues?milestone=$MS&state=all&per_page=100" | jq 'add')

pr_numbers=$(jq -r '.[] | select(.pull_request != null) | .number' <<<"$items")
issue_numbers=$(jq -r '.[] | select(.pull_request == null) | .number' <<<"$items")

linked_issues=" "   # space-delimited set of issue numbers a PR points at

printf 'Pull requests\n'
if [ -z "$pr_numbers" ]; then
  warn "no PRs carry milestone #$MS yet"
fi
for pr in $pr_numbers; do
  pr_json=$(gh pr view "$pr" --repo "$REPO" --json number,title,state,milestone,closingIssuesReferences,body,author,headRefName)
  pr_state=$(jq -r '.state' <<<"$pr_json")
  pr_title=$(jq -r '.title' <<<"$pr_json")

  # Real GitHub closing links, plus a text fallback for Closes/Fixes/Resolves #N in the body.
  ref_nums=$(jq -r '.closingIssuesReferences[]?.number' <<<"$pr_json")
  if [ -z "$ref_nums" ]; then
    ref_nums=$(jq -r '.body // ""' <<<"$pr_json" \
      | grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?) +#[0-9]+' \
      | grep -oE '[0-9]+' || true)
    [ -n "$ref_nums" ] && warn "PR #$pr links via body text only (not a registered GitHub closing link): $pr_title"
  fi

  if [ "$FEATURE_LINK" = required ] && [ "$REPO" != "$BACKLOG_REPO" ] && ! is_bot_pr "$pr_json" \
     && [ -z "$(feature_refs "$pr_json")" ]; then
    warn "PR #$pr links no feature of the backlog (Part of $BACKLOG_REPO#N): $pr_title"
  fi

  if [ -z "$ref_nums" ] && has_feature_link "$pr_json"; then
    if [ "$TAG_MODE" = 1 ] && [ "$pr_state" != "MERGED" ]; then
      err "PR #$pr is $pr_state — must be MERGED before tagging: $pr_title"
    else
      ok "PR #$pr ($pr_state) → links a backlog feature"
    fi
    continue
  fi

  if [ -z "$ref_nums" ]; then
    err "PR #$pr ($pr_state) closes no issue — add 'Closes #<issue>': $pr_title"
    continue
  fi

  for ri in $ref_nums; do
    linked_issues="$linked_issues$ri "
    ri_ms=$(gh issue view "$ri" --repo "$REPO" --json milestone -q '.milestone.title // ""' 2>/dev/null || echo "")
    if [ "$ri_ms" != "$ms_title" ]; then
      err "PR #$pr closes issue #$ri but that issue's milestone is '${ri_ms:-none}', not '$ms_title'"
    fi
  done

  if [ "$TAG_MODE" = 1 ] && [ "$pr_state" != "MERGED" ]; then
    err "PR #$pr is $pr_state — must be MERGED before tagging: $pr_title"
  else
    ok "PR #$pr ($pr_state) → closes #$(echo "$ref_nums" | paste -sd, -)"
  fi
done

printf '\nIssues\n'
if [ -z "$issue_numbers" ]; then
  warn "no issues carry milestone #$MS"
fi
for is in $issue_numbers; do
  is_state=$(jq -r --argjson n "$is" '.[] | select(.number == $n) | .state' <<<"$items")
  case "$linked_issues" in
    *" $is "*) linked="linked" ;;
    *)         linked="" ;;
  esac

  if [ "$TAG_MODE" = 1 ] && [ "$is_state" != "closed" ]; then
    err "issue #$is is $is_state — must be closed before tagging"
  elif [ -z "$linked" ]; then
    warn "issue #$is ($is_state) has no PR closing it"
  else
    ok "issue #$is ($is_state) ← linked"
  fi
done

printf '\n'
if [ "$errors" -gt 0 ]; then
  printf 'FAIL: %d error(s), %d warning(s).\n' "$errors" "$warns"
  exit 1
fi
printf 'PASS: 0 errors, %d warning(s).\n' "$warns"
[ "$TAG_MODE" = 1 ] && printf 'Milestone #%s is tag-ready.\n' "$MS"
exit 0
