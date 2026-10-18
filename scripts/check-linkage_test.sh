#!/usr/bin/env bash
#
# check-linkage_test.sh — tests for scripts/check-linkage.sh.
#
# Hermetic: a stub `gh` sits first on PATH and answers, from fixture files, the
# only calls the script makes, so there is no network and no credentials. What is
# under test is the rule for a link to a backlog feature (an issue whose milestone
# says "Release: business") and the rules it must not disturb.

# shellcheck disable=SC2046
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/check-linkage.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

command -v jq >/dev/null 2>&1 || { echo "error: 'jq' not found on PATH" >&2; exit 2; }

pass=0; fail=0
ok()  { printf '  ✓ %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  ✗ %s\n     %s\n' "$1" "$2"; fail=$((fail + 1)); }
check() { # description, condition-exit-code, detail
  if [ "$2" -eq 0 ]; then ok "$1"; else bad "$1" "$3"; fi
}

# The stub: fixtures live in $FIXTURES (items.ndjson, pr-<N>.json,
# issue-<owner>_<repo>-<N>.json). An unknown call is logged to unexpected.log.
bin="$tmp/bin"; mkdir -p "$bin"
cat > "$bin/gh" <<'STUB'
#!/usr/bin/env bash
fx="${FIXTURES:?}"
unexpected() { echo "gh $*" >> "$fx/unexpected.log"; echo "stub gh: unexpected call: gh $*" >&2; exit 99; }
all="$*"
echo "GH_TOKEN=${GH_TOKEN:-} gh $all" >> "$fx/ghcalls.log"
# a private backlog: only its own token reads it (fixture file backlog-hidden)
backlog_denied() { [ -e "$fx/backlog-hidden" ] && [ "${GH_TOKEN:-}" != "backlog-secret" ]; }
not_found() { echo "gh: Not Found (HTTP 404)" >&2; exit 1; }
cmd="${1:-}"; [ $# -gt 0 ] && shift
expr=""; repo=""; positional=()
while [ $# -gt 0 ]; do
  case "$1" in
    --jq|-q)            shift; expr="${1:-}" ;;
    --paginate|--slurp) ;;
    --repo)             shift; repo="${1:-}" ;;
    --json)             shift ;;
    *)                  positional+=("$1") ;;
  esac
  shift
done
reply() { if [ -n "$expr" ]; then jq -r "$expr" "$1"; else cat "$1"; fi; }
case "$cmd" in
  api)
    case "${positional[0]:-}" in
      "repos/$BACKLOG_REPO") backlog_denied && not_found; echo '{"private":true}' ;;
      "repos/$REPO/milestones?state=open&per_page=100") echo '[{"number":8,"title":"v0.8.0"}]' | jq -r "${expr:-.}" ;;
      "repos/$REPO/milestones/8") echo '{"title":"v0.8.0","state":"open"}' ;;
      "repos/$REPO/issues?milestone=8&state=all&per_page=100") jq -sc '[.]' "$fx/items.ndjson" ;;
      *) unexpected "$all" ;;
    esac ;;
  pr)
    [ "${positional[0]:-}" = view ] && [ "$repo" = "$REPO" ] && [ -f "$fx/pr-${positional[1]:-}.json" ] || unexpected "$all"
    reply "$fx/pr-${positional[1]}.json" ;;
  issue)
    [ "$repo" = "$BACKLOG_REPO" ] && backlog_denied && not_found
    f="$fx/issue-${repo//\//_}-${positional[1]:-}.json"
    [ "${positional[0]:-}" = view ] && [ -f "$f" ] || unexpected "$all"
    reply "$f" ;;
  *) unexpected "$all" ;;
esac
STUB
chmod +x "$bin/gh"

REPO=galax-io/test
BACKLOG=galax-io/backlog
BUSINESS='Release: business'
new_case() { fx="$tmp/fx-$1"; mkdir -p "$fx"; : > "$fx/items.ndjson"; }
issue_in() { # owner/repo, number, milestone title, [milestone description]
  jq -nc --arg ms "$3" --arg desc "${4:-}" '{milestone: (if $ms == "" then null else {title: $ms, description: $desc} end)}' \
    > "$fx/issue-${1//\//_}-$2.json"
}
add_issue() { printf '{"number":%s,"state":"%s"}\n' "$1" "$2" >> "$fx/items.ndjson"; issue_in "$REPO" "$1" v0.8.0; }
pr_json() { # number, state, closing number or "", body, milestone title or "", [author login], [head ref], [is_bot]
  jq -nc --argjson n "$1" --arg state "$2" --arg link "$3" --arg body "$4" --arg ms "$5" \
    --arg login "${6:-someone}" --arg head "${7:-feat/x}" --argjson bot "${8:-false}" '{
    number: $n, title: "PR \($n)", state: $state, body: $body, baseRefName: "main",
    author: {login: $login, is_bot: $bot}, headRefName: $head,
    milestone: (if $ms == "" then null else {title: $ms} end),
    closingIssuesReferences: [$link | select(. != "") | {number: tonumber}]
  }' > "$fx/pr-$1.json"
}
add_pr() { # number, state, closing number or "", [body] — a PR in v0.8.0
  local rest=closed; [ "$2" = OPEN ] && rest=open
  printf '{"number":%s,"state":"%s","pull_request":{}}\n' "$1" "$rest" >> "$fx/items.ndjson"
  pr_json "$1" "$2" "$3" "${4:-}" v0.8.0
}
run() { # the older cases do not test the feature rule
  out="$(PATH="$bin:$PATH" REPO="$REPO" BACKLOG_REPO="$BACKLOG" FEATURE_LINK=optional FIXTURES="$fx" bash "$script" "$@" 2>&1)"; rc=$?
}
run_strict() { # FEATURE_LINK left at its default (required)
  out="$(PATH="$bin:$PATH" REPO="$REPO" BACKLOG_REPO="$BACKLOG" FIXTURES="$fx" bash "$script" "$@" 2>&1)"; rc=$?
}
MSG='links no feature of the backlog'
has() { grep -qF -- "$1" <<<"$out"; }
only_known_calls() { [ ! -s "$fx/unexpected.log" ]; }

echo "check-linkage.sh"

# Existing behaviour
new_case gate-close
add_issue 1 open
pr_json 3 OPEN 1 "Closes #1" v0.8.0
run --pr 3
check "gate: Closes an issue of the same milestone passes" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case gate-close-other
issue_in "$REPO" 1 v0.7.0
pr_json 3 OPEN 1 "Closes #1" v0.8.0
run --pr 3
check "gate: Closes an issue of another milestone fails" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case gate-no-link
pr_json 3 OPEN "" "nothing" v0.8.0
run --pr 3
check "gate: a PR that closes nothing fails" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"

# 1. a PR with a version milestone may link a feature of the backlog
new_case gate-feature
pr_json 3 OPEN "" "Part of $BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run --pr 3
check "gate: Part of a backlog feature passes" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"
check "gate: it names the business milestone" $(has "✓ links $BACKLOG#30 (feature of business milestone \"M1 — first run\")" && echo 0 || echo 1) "out=$out"
check "gate: only known calls" $(only_known_calls && echo 0 || echo 1) "$(cat "$fx/unexpected.log" 2>&1)"

# 2. the marker among other lines, any case
new_case gate-feature-multiline
pr_json 3 OPEN "" "Part of $BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' $'First run.\nrelease: Business\nDue: autumn'
run --pr 3
check "gate: the marker on its own line of a longer description counts" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

# 3. a backlog issue in an ordinary milestone is not a feature
new_case gate-backlog-plain
pr_json 3 OPEN "" "Part of $BACKLOG#31" v0.8.0
issue_in "$BACKLOG" 31 'v0.7.0' 'Tooling of the backlog itself.'
run --pr 3
check "gate: an ordinary backlog milestone still has to match" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"

# 4. the marker only counts in the backlog repository
new_case gate-marker-elsewhere
pr_json 3 OPEN "" "Part of $REPO#1" v0.8.0
issue_in "$REPO" 1 'M1 — first run' "$BUSINESS"
run --pr 3
check "gate: the marker in another repository makes no feature" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"

# 5. no milestone on the backlog issue
new_case gate-feature-no-milestone
pr_json 3 OPEN "" "Part of $BACKLOG#32" v0.8.0
issue_in "$BACKLOG" 32 ""
run --pr 3
check "gate: a backlog issue without a milestone fails" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"

# 6. the PR still needs its own milestone
new_case gate-feature-no-pr-milestone
pr_json 3 OPEN "" "Part of $BACKLOG#30" ""
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run --pr 3
check "gate: a feature link does not replace the PR's milestone" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"
check "gate: it says to assign one" $(has '✗ no milestone' && echo 0 || echo 1) "out=$out"

# 7. a feature link beside a closing link keeps the closing rule
new_case gate-feature-and-close
issue_in "$REPO" 1 v0.7.0
pr_json 3 OPEN 1 $'Closes #1\nPart of '"$BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run --pr 3
check "gate: the closing link is still checked beside a feature link" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"

# 8. audit: a PR of the milestone that links a feature is not an error
new_case audit-feature
add_issue 1 open
add_pr 2 OPEN "" "Part of $BACKLOG#30"
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run
check "audit: linking a backlog feature passes" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case audit-nolink
add_issue 1 open
add_pr 2 OPEN "" "nothing"
run
check "audit: a PR with no link still fails" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"

# 9. tag: a merged PR of a feature does not block the tag
new_case tag-feature
add_issue 1 closed
add_pr 2 MERGED 1 "Closes #1"
add_pr 3 MERGED "" "Part of $BACKLOG#30"
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run --tag
check "tag: a merged PR that links a feature does not block the tag" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

# Every PR links a feature of the backlog (FEATURE_LINK=required, the default)
new_case strict-none
issue_in "$REPO" 1 v0.8.0
pr_json 3 OPEN 1 "Closes #1" v0.8.0
run_strict --pr 3
check "strict gate: a closing link without a feature fails" $([ "$rc" -eq 1 ] && has "✗ $MSG" && echo 0 || echo 1) "rc=$rc out=$out"
check "strict gate: the message names the standing feature" $(has 'the standing feature of the active business milestone, the issue with the label standing)' && echo 0 || echo 1) "out=$out"

new_case strict-part-of
pr_json 3 OPEN "" "Part of $BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run_strict --pr 3
check "strict gate: Part of a feature passes" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case strict-both
issue_in "$REPO" 1 v0.8.0
pr_json 3 OPEN 1 $'Closes #1\nPart of '"$BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run_strict --pr 3
check "strict gate: a feature beside a closing link passes" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case strict-closes-feature
pr_json 3 OPEN "" "Closes $BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run_strict --pr 3
check "strict gate: a closing link to a feature is seen" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case strict-bot
issue_in "$REPO" 1 v0.8.0
pr_json 3 OPEN 1 "Closes #1" v0.8.0 "dependabot[bot]" "chore/x" true
run_strict --pr 3
check "strict gate: a bot author is exempt" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case strict-bot-branch
issue_in "$REPO" 1 v0.8.0
pr_json 3 OPEN 1 "Closes #1" v0.8.0 "someone" "dependabot/npm/x"
run_strict --pr 3
check "strict gate: a dependabot/ branch is exempt" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case strict-update-branch
issue_in "$REPO" 1 v0.8.0
pr_json 3 OPEN 1 "Closes #1" v0.8.0 "someone" "update/lib-1.2"
run_strict --pr 3
check "strict gate: an update/ branch is exempt" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case strict-backlog-repo
pr_json 3 OPEN "" "nothing" v0.8.0
out="$(PATH="$bin:$PATH" REPO="$BACKLOG" BACKLOG_REPO="$BACKLOG" FIXTURES="$fx" bash "$script" --pr 3 2>&1)"; rc=$?
check "strict gate: a PR of the backlog repository is exempt from the feature rule" $(has "$MSG" && echo 1 || echo 0) "out=$out"

new_case strict-bad-env
out="$(PATH="$bin:$PATH" REPO="$REPO" BACKLOG_REPO="$BACKLOG" FEATURE_LINK=maybe FIXTURES="$fx" bash "$script" --pr 3 2>&1)"; rc=$?
check "FEATURE_LINK other than required or optional exits 2" $([ "$rc" -eq 2 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case strict-optional
issue_in "$REPO" 1 v0.8.0
pr_json 3 OPEN 1 "Closes #1" v0.8.0
run --pr 3
check "gate: FEATURE_LINK=optional lets a PR without a feature pass" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

new_case strict-audit
add_issue 1 open
add_pr 2 OPEN 1 "Closes #1"
run_strict
check "audit: a PR without a feature only warns" $([ "$rc" -eq 0 ] && has "! PR #2 $MSG" && echo 0 || echo 1) "rc=$rc out=$out"

# The private backlog: read with BACKLOG_READ_TOKEN, and only for calls about the backlog
new_case strict-hidden
pr_json 3 OPEN "" "Part of $BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
: > "$fx/backlog-hidden"
run_strict --pr 3
check "hidden: a backlog the token cannot read fails the gate" $([ "$rc" -eq 1 ] && echo 0 || echo 1) "rc=$rc out=$out"
check "hidden: it names the missing token" $(has "cannot read the backlog $BACKLOG" && has 'BACKLOG_READ_TOKEN' && echo 0 || echo 1) "out=$out"
check "hidden: it does not claim the PR links no feature" $(! has 'links no feature of the backlog' && echo 0 || echo 1) "out=$out"

new_case strict-token
pr_json 3 OPEN "" "Part of $BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
: > "$fx/backlog-hidden"
out="$(PATH="$bin:$PATH" REPO="$REPO" BACKLOG_REPO="$BACKLOG" GH_TOKEN=job-token BACKLOG_READ_TOKEN=backlog-secret FIXTURES="$fx" bash "$script" --pr 3 2>&1)"; rc=$?
check "token: with BACKLOG_READ_TOKEN the feature is seen and the gate passes" $([ "$rc" -eq 0 ] && has "✓ links $BACKLOG#30 (feature of business milestone" && echo 0 || echo 1) "rc=$rc out=$out"
check "token: the backlog token is used for calls about the backlog" $(grep -q "GH_TOKEN=backlog-secret gh .*$BACKLOG" "$fx/ghcalls.log" && echo 0 || echo 1) "$(cat "$fx/ghcalls.log")"
check "token: the backlog token never reaches a call about this repository" $(! grep "GH_TOKEN=backlog-secret" "$fx/ghcalls.log" | grep -v "$BACKLOG" | grep -q . && echo 0 || echo 1) "$(grep backlog-secret "$fx/ghcalls.log")"
check "token: the job's own token still reads the pull request" $(grep -q "GH_TOKEN=job-token gh pr view" "$fx/ghcalls.log" && echo 0 || echo 1) "$(cat "$fx/ghcalls.log")"

new_case strict-readable
pr_json 3 OPEN "" "Part of $BACKLOG#30" v0.8.0
issue_in "$BACKLOG" 30 'M1 — first run' "$BUSINESS"
run_strict --pr 3
check "readable: without BACKLOG_READ_TOKEN a readable backlog is read with the job's token" $([ "$rc" -eq 0 ] && echo 0 || echo 1) "rc=$rc out=$out"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
