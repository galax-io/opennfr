#!/usr/bin/env bash
#
# verify.sh — the "green per commit" gate for this repository.
#
# There is no code here yet, so this checks the only things that can currently be
# wrong: that the sketches still parse, that the notes do not link into the void,
# and that the docs stayed in English (see docs/adr/0001-terminology.md).
#
# The schema gate validates examples/ against schema/opennfr.io/v1/. The sketches
# under docs/examples/ are outside it on purpose — see AGENTS.md > Test Model.
#
# Constitution III (No Silent Green) binds this file to itself: a section that cannot
# run reports FAIL, never ok and never a bare skip, and a section that scanned nothing
# says so. A gate that excuses itself is indistinguishable from a gate that passed.
#
# Usage: bash scripts/verify.sh

set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"

fail=0
section() { printf '\n== %s\n' "$1"; }
ok()      { printf '  ok    %s\n' "$1"; }
bad()     { printf '  FAIL  %s\n' "$1"; fail=1; }

# ---------------------------------------------------------------------------
section "Documents parse, map onto JSON, and satisfy their schema"
# One implementation, two callers: scripts/opennfr_check.py is what the conformance
# corpus calls too. A corpus asserting against its own copy of these rules would prove
# nothing about the gate that actually runs, and two copies drift — which is the failure
# this repository exists to prevent, reproduced inside its own tooling.
#
# Exit codes from the module: 0 passed, 1 a document failed, 2 THE CHECK COULD NOT RUN.
# The third is why there is no skip branch anywhere below.
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the document gate cannot run"
else
  python3 scripts/opennfr_check.py \
      'examples/*.yaml' 'mappings/*.yaml' 'conformance/**/*.yaml'
  case $? in
    0) : ;;
    1) fail=1 ;;
    *) bad "the document gate could not run" ;;
  esac
fi

# ---------------------------------------------------------------------------
section "Sketches parse and map onto JSON"
# The sketches under docs/examples/ are held to ADR-0002 D16 like everything else, and
# deliberately NOT to the schema: they illustrate constructs the format does not have,
# so validating them would make them useless. Nothing else may opt out — see
# AGENTS.md > Test Model.
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the sketch gate cannot run"
else
  python3 scripts/opennfr_check.py --no-schema 'docs/**/*.yaml'
  case $? in
    0) : ;;
    1) fail=1 ;;
    *) bad "the sketch gate could not run" ;;
  esac
fi

# ---------------------------------------------------------------------------
section "Internal markdown links resolve"
missing=0
found=0
while IFS= read -r line; do
  found=$((found + 1))
  src="${line%%:*}"
  target="${line#*:}"
  base="$(dirname "$src")"
  path="${target%%#*}"
  [ -z "$path" ] && continue                      # pure anchor, same file
  case "$path" in *'<'*|*'>'*|*'{'*) continue ;; esac   # placeholder, e.g. specs/001-<feature>/
  if [ ! -e "$base/$path" ]; then
    bad "$src -> $target"
    missing=1
  fi
done < <(
  grep -rn --include='*.md' -oE '\]\([^)]+\)' . \
    | grep -v '^\./\.' \
    | sed -E 's/^([^:]+):[0-9]+:\]\((.*)\)$/\1:\2/' \
    | grep -vE ':(https?|mailto):'
)
# Zero links means the extraction above stopped working, not that the docs are clean.
if [ "$found" -eq 0 ]; then
  bad "no markdown links found — the link extraction is broken"
elif [ "$missing" -eq 0 ]; then
  ok "no dangling internal links ($found checked)"
fi

# ---------------------------------------------------------------------------
section "Docs are English"
# ADR-0001 settled on English for everything published. Cyrillic left in a file
# means a translation was missed, which is silent until someone outside reads it.
#
# This was `grep -rlP` until it turned out that `-P` is a GNU extension. BSD grep on
# macOS answers "invalid option -- P", `2>/dev/null` swallowed that, `|| true` swallowed
# the exit status, and an empty result read as a clean scan: the check reported ok on
# every Mac without ever having run once. Python carries no such dialect, and the rest
# of this file already reaches for it whenever a check stops being one grep long.
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the English scan cannot run"
else
  python3 - <<'ENGLISH' || fail=1
import re, subprocess, sys

# What the repository carries or is about to: tracked files plus untracked ones git
# would accept. Ignored paths stay out — .claude/worktrees/ holds entire checkouts of
# other branches — and an unstaged draft stays in, which is where the Cyrillic that
# exposed this check being broken was sitting.
def git(*flags):
    out = subprocess.run(["git", "ls-files", "-z", *flags, "--", "*.md", "*.yaml"],
                         capture_output=True, check=True).stdout
    return {f for f in out.decode("utf-8").split("\0") if f}

try:
    listed = git("--cached", "--others", "--exclude-standard")
    # A file deleted from the worktree is still in the index. It has no content to
    # read, so it is removed by name rather than left to fail as unreadable — which
    # keeps that FAIL meaning what it says.
    listed -= git("--deleted")
except (OSError, subprocess.CalledProcessError) as e:
    print(f"  FAIL  cannot enumerate files ({e}) — the English scan cannot run")
    sys.exit(1)

files = sorted(listed)
if not files:
    print("  FAIL  no .md or .yaml file found to scan")
    sys.exit(1)

cyrillic = re.compile(r"[\u0400-\u04FF]")   # the Cyrillic block, as the grep matched
rc = 0
for f in files:
    try:
        text = open(f, encoding="utf-8").read()
    except (OSError, UnicodeDecodeError) as e:
        print(f"  FAIL  {f}: cannot be read as UTF-8 ({e})")
        rc = 1
        continue
    for n, line in enumerate(text.splitlines(), 1):
        if cyrillic.search(line):
            print(f"  FAIL  non-English text in {f}:{n}")
            rc = 1
            break                            # one line per file is enough to act on
if rc == 0:
    print(f"  ok    no non-English text in {len(files)} files")
sys.exit(rc)
ENGLISH
fi

# ---------------------------------------------------------------------------
section "Examples are labelled as sketches"
# Nothing validates the examples, so each one must say so — otherwise a reader
# mistakes an illustration for syntax.
sketches=0
for f in docs/examples/*.yaml; do
  [ -e "$f" ] || continue
  sketches=$((sketches + 1))
  if head -6 "$f" | grep -qi 'sketch'; then
    ok "$f"
  else
    bad "$f does not announce itself as a sketch in its first 6 lines"
  fi
done
[ "$sketches" -gt 0 ] || bad "docs/examples/ holds no sketch to check"

# ---------------------------------------------------------------------------
printf '\n'
if [ "$fail" -ne 0 ]; then
  printf 'FAIL\n'
  exit 1
fi
printf 'PASS\n'
