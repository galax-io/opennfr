#!/usr/bin/env bash
#
# verify.sh — the "green per commit" gate for this repository.
#
# There is no code here yet, so this checks the only things that can currently be
# wrong: that the sketches still parse, that the notes do not link into the void,
# and that the docs stayed in English (see docs/adr/0001-terminology.md).
#
# When a JSON Schema exists, validating docs/examples/ against it belongs here and
# becomes the real gate.
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
# ADR-0002 D16: every object must map onto JSON. YAML will happily produce a
# datetime from an unquoted timestamp, and a datetime has no JSON equivalent —
# so it parses here and breaks the moment anything serialises it.
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'JSONABLE' || fail=1
import glob, sys
try:
    import yaml
except ImportError:
    print("  skip  PyYAML not installed"); sys.exit(0)
OK = (dict, list, str, int, float, bool, type(None))
rc = 0
def walk(v, path, f):
    global rc
    if isinstance(v, bool) or v is None or isinstance(v, (str, int, float)):
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
    for doc in yaml.safe_load_all(open(f, encoding="utf-8")):
        walk(doc, "", f)
    if rc == 0:
        print(f"  ok    {f}")
sys.exit(rc)
JSONABLE
fi

section "Examples validate against the schema"
# The real gate. Every kind: RequirementSet document must satisfy
# schema/opennfr.io/v1/requirementset.schema.json — a sketch that does not parse
# as the format is a sketch of something else.
if ! command -v python3 >/dev/null 2>&1; then
  printf '  skip  python3 not found\n'
else
  python3 - <<'SCHEMA' || fail=1
import glob, json, sys
try:
    import yaml
    from jsonschema import Draft202012Validator
    import referencing  # noqa: F401
except ImportError as e:
    print(f"  skip  {e.name} not installed (pip install jsonschema pyyaml)")
    sys.exit(0)
from referencing import Registry, Resource
schemas = {}
for sf in sorted(glob.glob("schema/opennfr.io/v1/*.json")):
    s = json.load(open(sf, encoding="utf-8"))
    Draft202012Validator.check_schema(s)
    schemas[s["$id"]] = s
registry = Registry().with_resources(
    [(i, Resource.from_contents(s)) for i, s in schemas.items()]
)
by_kind = {s["title"]: s for s in schemas.values() if s.get("type") == "object"}
rc = 0
for f in sorted(glob.glob("examples/**/*.yaml", recursive=True)):
    for doc in yaml.safe_load_all(open(f, encoding="utf-8")):
        if not isinstance(doc, dict):
            continue
        kind = doc.get("kind")
        if kind not in by_kind:
            print(f"  --    {f}: kind {kind!r} has no schema yet")
            continue
        v = Draft202012Validator(by_kind[kind], registry=registry)
        errs = sorted(v.iter_errors(doc), key=lambda e: list(e.path))
        if errs:
            rc = 1
            for e in errs:
                where = "/".join(map(str, e.path)) or "(root)"
                print(f"  FAIL  {f}: {where}: {e.message}")
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
