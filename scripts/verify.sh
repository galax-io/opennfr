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
# Usage: bash scripts/verify.sh

set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"

fail=0
section() { printf '\n== %s\n' "$1"; }
ok()      { printf '  ok    %s\n' "$1"; }
bad()     { printf '  FAIL  %s\n' "$1"; fail=1; }

# ---------------------------------------------------------------------------
section "YAML sketches parse"
if ! command -v python3 >/dev/null 2>&1; then
  printf '  skip  python3 not found\n'
else
  python3 - <<'PY'
import glob, sys
try:
    import yaml
except ImportError:
    print("  skip  PyYAML not installed (pip install pyyaml)")
    sys.exit(0)
rc = 0
for f in sorted(glob.glob("examples/*.yaml") + glob.glob("docs/**/*.yaml", recursive=True)):
    try:
        list(yaml.safe_load_all(open(f, encoding="utf-8")))
        print(f"  ok    {f}")
    except Exception as e:
        print(f"  FAIL  {f}: {e}")
        rc = 1
sys.exit(rc)
PY
  [ $? -eq 0 ] || fail=1
fi

# ---------------------------------------------------------------------------
section "Sketches map one-to-one onto JSON"
# ADR-0002 D16: every object must map onto JSON, and anchors, aliases and merge
# keys are forbidden outright. Both checks have to happen before safe_load_all
# resolves them away: by the time it returns, an alias is an ordinary dict.
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'JSONABLE' || fail=1
import glob, math, sys
try:
    import yaml
except ImportError:
    print("  FAIL  PyYAML not installed (pip install pyyaml)"); sys.exit(1)
rc = 0
def scan_events(f):
    """Anchors, aliases and merge keys, caught at the event level."""
    global rc
    for ev in yaml.parse(open(f, encoding="utf-8")):
        if isinstance(ev, yaml.AliasEvent):
            print(f"  FAIL  {f}: alias *{ev.anchor} — ADR-0002 D16 forbids aliases"); rc = 1
        elif getattr(ev, "anchor", None):
            print(f"  FAIL  {f}: anchor &{ev.anchor} — ADR-0002 D16 forbids anchors"); rc = 1
        elif isinstance(ev, yaml.ScalarEvent) and ev.value == "<<":
            print(f"  FAIL  {f}: merge key << — ADR-0002 D16 forbids merge keys"); rc = 1
def walk(v, path, f):
    global rc
    if v is None or isinstance(v, (bool, str, int)):
        return
    if isinstance(v, float):
        if not math.isfinite(v):
            print(f"  FAIL  {f}: {path}: {v!r} has no JSON representation"); rc = 1
        return
    if isinstance(v, dict):
        for k, x in v.items():
            if not isinstance(k, str):
                print(f"  FAIL  {f}: {path}: non-string key {k!r}"); rc = 1
            walk(x, f"{path}/{k}", f)
        return
    if isinstance(v, list):
        for i, x in enumerate(v):
            walk(x, f"{path}/{i}", f)
        return
    print(f"  FAIL  {f}: {path}: {type(v).__name__} has no JSON equivalent ({v!r})")
    rc = 1
for f in sorted(glob.glob("examples/*.yaml") + glob.glob("docs/examples/**/*.yaml", recursive=True)):
    before = rc
    scan_events(f)
    for doc in yaml.safe_load_all(open(f, encoding="utf-8")):
        walk(doc, "", f)
    if rc == before:
        print(f"  ok    {f}")
sys.exit(rc)
JSONABLE
fi

section "Examples validate against the schema"
# The real gate. Every document in examples/ must satisfy the schema. The
# sketches under docs/examples/ are deliberately outside it — see AGENTS.md >
# Test Model — because they illustrate ideas the format does not have.
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the schema gate cannot run"
else
  python3 - <<'SCHEMA' || fail=1
import glob, json, sys
try:
    import yaml
    from jsonschema import Draft202012Validator
except ImportError as e:
    # A gate that skips itself reads exactly like a passing one.
    print(f"  FAIL  {e.name} not installed (pip install jsonschema pyyaml)")
    sys.exit(1)
schema = json.load(open("schema/opennfr.io/v1/requirementset.schema.json", encoding="utf-8"))
Draft202012Validator.check_schema(schema)
v = Draft202012Validator(schema)
rc = 0
files = sorted(glob.glob("examples/*.yaml"))
if not files:
    print("  FAIL  examples/ holds no document to validate")
    sys.exit(1)
for f in files:
    docs = [d for d in yaml.safe_load_all(open(f, encoding="utf-8"))]
    if not docs or all(d is None for d in docs):
        print(f"  FAIL  {f}: no document — a published example may not be empty")
        rc = 1
        continue
    for doc in docs:
        if not isinstance(doc, dict):
            print(f"  FAIL  {f}: top level is {type(doc).__name__}, expected a mapping")
            rc = 1
            continue
        kind = doc.get("kind")
        if kind != "RequirementSet":
            print(f"  FAIL  {f}: kind {kind!r} has no schema yet — move it out of examples/")
            rc = 1
            continue
        errs = sorted(v.iter_errors(doc), key=lambda e: list(e.path))
        for e in errs:
            where = "/".join(map(str, e.path)) or "(root)"
            print(f"  FAIL  {f}: {where}: {e.message}")
        # criterionId is the name if set, otherwise the aggregation. The schema
        # cannot express that fallback, so uniqueness is checked here.
        for r in doc.get("spec", {}).get("requirements", []) or []:
            for section in ("criteria", "guards"):
                seen = set()
                for p in r.get(section, []) or []:
                    cid = p.get("name") or p.get("aggregation")
                    if cid in seen:
                        print(f"  FAIL  {f}: {r.get('name')}/{section}: duplicate criterionId {cid!r}")
                        errs = errs or [1]
                        rc = 1
                    seen.add(cid)
        if errs:
            rc = 1
        else:
            print(f"  ok    {f}  [{kind}]")
sys.exit(rc)
SCHEMA
fi

# ---------------------------------------------------------------------------
section "Internal markdown links resolve"
missing=0
while IFS= read -r line; do
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
[ "$missing" -eq 0 ] && ok "no dangling internal links"

# ---------------------------------------------------------------------------
section "Docs are English"
# ADR-0001 settled on English for everything published. Cyrillic left in a file
# means a translation was missed, which is silent until someone outside reads it.
cyr=$(grep -rlP '[\x{0400}-\x{04FF}]' --include='*.md' --include='*.yaml' . 2>/dev/null | grep -v '^\./\.git/' || true)
if [ -n "$cyr" ]; then
  while IFS= read -r f; do bad "non-English text in $f"; done <<<"$cyr"
else
  ok "no non-English text in docs"
fi

# ---------------------------------------------------------------------------
section "Examples are labelled as sketches"
# Nothing validates the examples, so each one must say so — otherwise a reader
# mistakes an illustration for syntax.
for f in docs/examples/*.yaml; do
  [ -e "$f" ] || continue
  if head -6 "$f" | grep -qi 'sketch'; then
    ok "$f"
  else
    bad "$f does not announce itself as a sketch in its first 6 lines"
  fi
done

# ---------------------------------------------------------------------------
printf '\n'
if [ "$fail" -ne 0 ]; then
  printf 'FAIL\n'
  exit 1
fi
printf 'PASS\n'
