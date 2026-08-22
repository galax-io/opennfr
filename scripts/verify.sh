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
section "YAML sketches parse"
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the YAML parse gate cannot run"
else
  python3 - <<'PY'
import glob, sys
try:
    import yaml
except ImportError:
    print("  FAIL  PyYAML not installed (pip install pyyaml)")
    sys.exit(1)
rc = 0
files = sorted(glob.glob("examples/*.yaml") + glob.glob("docs/**/*.yaml", recursive=True))
if not files:
    print("  FAIL  no YAML document found to parse")
    sys.exit(1)
for f in files:
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
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the JSON-mapping gate cannot run"
else
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
files = sorted(glob.glob("examples/*.yaml") + glob.glob("docs/examples/**/*.yaml", recursive=True))
if not files:
    print("  FAIL  no YAML document found to map onto JSON")
    sys.exit(1)
for f in files:
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
section "The schema holds up its own examples, and still rejects"
# Two things nothing else covers.
#
# The `examples` the schema carries are what an editor offers, so an example the schema
# rejects teaches a shape that does not exist. Tighten a pattern and they go stale in
# silence — every other check here reads examples/, not the schema's own contents.
#
# And every published example is one the schema is meant to ACCEPT, so nothing notices if
# a closure comes loose. `displayName` was added to three objects that close over their
# properties; the probes below are the cases that must still fail.
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the schema self-check cannot run"
else
  python3 - <<'SELFCHECK' || fail=1
import json, sys
try:
    from jsonschema import Draft202012Validator as V
except ImportError as e:
    print(f"  FAIL  {e.name} not installed (pip install jsonschema)"); sys.exit(1)

path = "schema/opennfr.io/v1/requirementset.schema.json"
try:
    schema = json.load(open(path, encoding="utf-8"))
    V.check_schema(schema)
except Exception as e:
    print(f"  FAIL  {path}: not a usable schema ({e})"); sys.exit(1)

rc, checked = 0, 0

def sub(node):
    """One definition, validatable on its own: its siblings minus the examples."""
    out = {k: v for k, v in node.items() if k != "examples"}
    out["$defs"] = schema["$defs"]
    return out

for where, node in [("(root)", schema)] + sorted(schema["$defs"].items()):
    for i, ex in enumerate(node.get("examples", [])):
        checked += 1
        for e in V(sub(node)).iter_errors(ex):
            print(f"  FAIL  {path}: {where} example {i}: {e.message}")
            rc = 1
if checked == 0:
    print(f"  FAIL  {path} carries no examples — the check scanned nothing")
    sys.exit(1)

# The closures. Each MUST be rejected; one that validates means a guard came loose.
def doc():
    return {"apiVersion": "opennfr.io/v1", "kind": "RequirementSet", "metadata": {"name": "probe"},
            "spec": {"requirements": [{"name": "r",
                     "indicator": {"distribution": {"metric": "m", "selector": {}}},
                     "criteria": [{"aggregation": "max", "op": "lte", "threshold": 1, "unit": "ms"}]}]}}

probes = {}
d = doc(); d["metadata"]["nope"] = "x";                       probes["unknown field on metadata"] = d
d = doc(); d["spec"]["requirements"][0]["nope"] = "x";        probes["unknown field on a requirement"] = d
d = doc(); d["spec"]["requirements"][0]["criteria"][0]["nope"] = "x"; probes["unknown field on a criterion"] = d
d = doc(); d["spec"]["displayName"] = "x";                    probes["displayName on spec"] = d
d = doc(); d["spec"]["requirements"][0]["indicator"]["distribution"]["displayName"] = "x"
probes["displayName on a series"] = d
d = doc(); d["metadata"]["displayName"] = "x" * 201;          probes["displayName over 200 characters"] = d
d = doc(); d["metadata"]["displayName"] = "";                 probes["empty displayName"] = d

for name, bad_doc in probes.items():
    if not list(V(schema).iter_errors(bad_doc)):
        print(f"  FAIL  the schema accepts what it must reject: {name}")
        rc = 1

if rc == 0:
    print(f"  ok    {checked} embedded examples valid, {len(probes)} closures still reject")
sys.exit(rc)
SELFCHECK
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
