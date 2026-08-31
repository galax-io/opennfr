#!/usr/bin/env bash
#
# verify.sh — the "green per commit" gate for this repository.
#
# There is no code here yet, so this checks the only things that can currently be
# wrong: that every published document validates against the schema, that nothing
# links into the void, that no documentation links into docs/, and that the docs
# stayed in English.
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
section "YAML parses"
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
files = sorted(glob.glob("examples/*.yaml"))
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
section "Documents map one-to-one onto JSON"
# Every object must map onto JSON, and anchors, aliases and merge
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
            print(f"  FAIL  {f}: alias *{ev.anchor} — the format forbids aliases"); rc = 1
        elif getattr(ev, "anchor", None):
            print(f"  FAIL  {f}: anchor &{ev.anchor} — the format forbids anchors"); rc = 1
        elif isinstance(ev, yaml.ScalarEvent) and ev.value == "<<":
            print(f"  FAIL  {f}: merge key << — the format forbids merge keys"); rc = 1
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
files = sorted(glob.glob("examples/*.yaml"))
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
# The real gate. Every document in examples/ must satisfy the schema.
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
sys.path.insert(0, "scripts")
import identity

# The identity rule is held to its own probes before either section trusts it. Both branches
# that checked it could be replaced with `if False:` and this gate still printed PASS, and the
# `name` arm of the fallback had never been observed at all — issue #72.
wrong = identity.selftest()
for m in wrong:
    print(f"  FAIL  the identity rule is wrong: {m}")
if wrong:
    sys.exit(1)

schema = json.load(open("schema/opennfr.io/v1/requirementset.schema.json", encoding="utf-8"))
Draft202012Validator.check_schema(schema)
v = Draft202012Validator(schema)
rc = 0
identity_lists = []
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
        # The identity rule, and why the schema cannot carry it, live in scripts/identity.py.
        for r in (doc.get("spec") or {}).get("requirements", []) or []:
            for section, cid in identity.collisions(r, identity_lists):
                print(f"  FAIL  {f}: {r.get('name')}/{section}: duplicate predicateId {cid!r}")
                errs = errs or [1]
                rc = 1
        if errs:
            rc = 1
        else:
            print(f"  ok    {f}  [{kind}]")

# A check that scanned nothing reads exactly like one that passed, and a probe cannot catch a
# deleted CALL — the probes above call the module directly and would stay green. This count can,
# because `collisions` is a generator that appends only while it is being consumed: drop the loop
# and the count drops with it. Counting through a second function did NOT do that.
IDENTITY_LISTS = 5
if len(identity_lists) < IDENTITY_LISTS:
    print(f"  FAIL  the identity check read {len(identity_lists)} lists, expected at least "
          f"{IDENTITY_LISTS} — a check that scanned nothing reads exactly like one that passed")
    rc = 1
else:
    print(f"  ok    identity: {len(identity.PROBES)} probes still hold, "
          f"{len(identity_lists)} lists read")
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
# And every published example is one the schema is meant to ACCEPT, so nothing notices if a
# constraint comes loose: loosening one never invalidates a document that was already valid. The
# probes below are documents that must still FAIL, one per constraint the schema makes.
#
# They started as seven, covering the `displayName` closures alone, and a sweep found that 39 of
# the 41 single-constraint loosenings in this file left the section green — the whole closed
# vocabulary among them, including the `mss` typo `$defs/unit`'s own description promises is a
# parse error. Every constraint now has a probe. The sweep is the check on the checks: mutate one
# constraint at a time and confirm this section reddens.
#
# The one exception is `$defs/predicate.type`, whose removal changes no verdict — the `not` rules
# below reject a non-object anyway — so no document can probe it.
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
    """One shape, validatable on its own: its siblings minus the examples.

    `$id` is carried over. Without it a `$ref` written absolutely against the schema's own
    `$id` stops resolving inside this file: offline that is a URLError, and if opennfr.io
    ever serves that URL the gate would check the working tree against the PUBLISHED schema
    instead of the change under review — a gate that quietly stops reading the diff.
    """
    out = {k: v for k, v in node.items() if k != "examples"}
    out["$defs"] = schema["$defs"]
    if "$id" in schema:
        out["$id"] = schema["$id"]
    return out

def at(pointer):
    """The subschema a local JSON pointer addresses, or None if it addresses nothing.

    None rather than a raised KeyError: a `$ref` to a definition that is not there is a
    thing to REPORT. `V.check_schema` does not resolve refs, so a dangling one reaches this
    far, and letting it raise buried every diagnostic under a stack trace.
    """
    node = schema
    for part in pointer.strip("/").split("/"):
        key = part.replace("~1", "/").replace("~0", "~")
        if not isinstance(node, dict) or key not in node:
            return None
        node = node[key]
    return node

def refs(node, found):
    """Every local pointer a `$ref` anywhere in the schema addresses."""
    if isinstance(node, dict):
        target = node.get("$ref")
        if isinstance(target, str) and "#" in target and target.split("#", 1)[1].startswith("/"):
            found.add(target.split("#", 1)[1])
        for v in node.values():
            refs(v, found)
    elif isinstance(node, list):
        for v in node:
            refs(v, found)
    return found

# Every shape the schema defines must show what it looks like: the schema reference points a
# reader at these, so one that carries no example is a promise broken where nobody looks.
#
# The set is derived, never listed — a list is a second statement of "everything the schema
# defines" and drifts the moment one is added. But it is derived from where the shapes are
# USED, not from the name of the container they sit in. Keyed on `$defs`, the requirement
# travelled with the definition: renaming one, deleting it, or moving all nine to
# `#/definitions/` left the loop iterating nothing and reporting ok — nine definitions, no
# examples, green. Following `$ref` targets instead means a shape cannot escape by moving,
# and it also reaches the objects defined inline, which `$defs` never did.
def inline_shapes(node, pointer, out):
    """Every subschema that declares an object shape, wherever it sits.

    Not just the top level: an object written inline three levels down is as much a shape an
    author has to fill in as one behind a `$ref`, and it used to escape the requirement
    entirely. `examples` subtrees are instance data, never schemas, so they are not entered.
    """
    # Only where a shape is NAMED and filled in: under `properties`, a definition, or `items`.
    # `allOf`/`if`/`then` and friends hold rules about a shape, not a shape — asking a
    # conditional fragment for an example is asking prose of an assertion.
    WHERE = ("properties", "$defs", "definitions", "items")
    if isinstance(node, dict):
        if pointer and "properties" in node:
            out.append((pointer, node))
        for k in WHERE:
            v = node.get(k)
            if isinstance(v, dict):
                children = v.items() if k != "items" else [(None, v)]
                for name, child in children:
                    inline_shapes(child, f"{pointer}/{k}" + (f"/{name}" if name else ""), out)
    return out

slots, seen = [("(root)", schema)], {""}
for pointer, node in ([(p, at(p)) for p in sorted(refs(schema, set()))]
                      + inline_shapes(schema, "", [])):
    if pointer not in seen:
        seen.add(pointer)
        slots.append((pointer, node))

# A floor, for the reason the probe dict below carries one: a set that can empty satisfies
# itself, and pruning most of it is the realistic accident, not deleting all of it.
SHAPES = 11
if len(slots) < SHAPES:
    print(f"  FAIL  {path}: {len(slots)} shapes to document, expected at least {SHAPES} — "
          f"a shape that is gone cannot be missing its examples")
    sys.exit(1)

for where, node in slots:
    if node is None:
        print(f"  FAIL  {path}: a `$ref` addresses {where}, which the schema does not define")
        rc = 1
    elif not (isinstance(node, dict) and node.get("examples")):
        print(f"  FAIL  {path}: {where} carries no examples")
        rc = 1
if rc:
    # Stop before validating: an absent shape means an unresolvable `$ref` below, and a
    # traceback would bury the diagnostics just printed under a stack.
    sys.exit(1)

PROBES = ["x", 1, True, None, [], {}, {"a": 1}]
for where, node in slots:
    validator = V(sub(node))
    # A shape that accepts everything asserts nothing, so its examples prove nothing either —
    # the presence check would pass on garbage and raise `checked` while doing it.
    if all(not list(validator.iter_errors(p)) for p in PROBES):
        print(f"  FAIL  {path}: {where} asserts nothing — its examples cannot be wrong")
        rc = 1
        continue
    for i, ex in enumerate(node["examples"]):
        checked += 1
        try:
            errors = sorted(validator.iter_errors(ex), key=lambda e: list(e.path))
        except Exception as e:                        # an unresolvable $ref, say
            print(f"  FAIL  {path}: {where} example {i} cannot be validated: {e}")
            rc = 1
            continue
        for e in errors:
            at_path = "/".join(map(str, e.path)) or "(whole)"
            print(f"  FAIL  {path}: {where} example {i} at {at_path}: {e.message}")
            rc = 1

# The root's examples are whole documents, so they answer to what the corpus answers to.
# The schema cannot express predicateId uniqueness — that is why examples/ is checked for it
# by hand above — and the one document an editor offers first was the one nothing checked.
# The rule itself lives in scripts/identity.py, shared with that section so the two cannot
# drift into disagreeing about it.
sys.path.insert(0, "scripts")
import identity

root_identity_lists = []
for i, ex in enumerate(schema.get("examples", [])):
    for r in (ex.get("spec") or {}).get("requirements", []) or []:
        for part, cid in identity.collisions(r, root_identity_lists):
            print(f"  FAIL  {path}: root example {i}: {r.get('name')}/{part}: "
                  f"duplicate predicateId {cid!r}")
            rc = 1

# As above: a deleted call reads as a clean scan, so the count is floored too.
ROOT_IDENTITY_LISTS = 1
if len(root_identity_lists) < ROOT_IDENTITY_LISTS:
    print(f"  FAIL  {path}: the identity check read {len(root_identity_lists)} lists of the "
          f"schema's own examples, expected at least {ROOT_IDENTITY_LISTS}")
    rc = 1

EXAMPLES = 20
if checked < EXAMPLES:
    print(f"  FAIL  {path}: {checked} examples, expected at least {EXAMPLES} — "
          f"the check is reading less than it was written to read")
    sys.exit(1)

# The closures. Each MUST be rejected; one that validates means a guard came loose.
#
# doc() must itself be valid — unmutated — before any probe below is trusted. A probe built on
# an already-invalid base is rejected for the wrong reason, and every mutation below would then
# "pass" no matter what it actually tests (issue #37). Checked, not assumed: see the assertion
# immediately after this function.
def doc():
    # Carries a guard as well as a criterion: the two are the same shape and are edited as a pair,
    # so a base document exercising only one leaves the other free to come loose unobserved.
    return {"apiVersion": "opennfr.io/v1", "kind": "RequirementSet",
            "metadata": {"name": "probe", "displayName": "a probe", "annotations": {"k": "v"}},
            "spec": {"requirements": [{"name": "r", "selector": {},
                     "guards": [{"aggregation": "rate", "op": "gte", "threshold": 1, "unit": "{request}/s"}],
                     "criteria": [{"metric": "m", "aggregation": "max", "op": "lte", "threshold": 1, "unit": "ms"}]}]}}

base_errs = list(V(schema).iter_errors(doc()))
if base_errs:
    for e in base_errs:
        where = "/".join(map(str, e.path)) or "(root)"
        print(f"  FAIL  {path}: probe base document is invalid on its own at {where}: {e.message}")
    print("  FAIL  every probe below is meaningless until the base document validates unmutated")
    sys.exit(1)

probes = {}
d = doc(); d["metadata"]["nope"] = "x";                       probes["unknown field on metadata"] = d
d = doc(); d["spec"]["requirements"][0]["nope"] = "x";        probes["unknown field on a requirement"] = d
d = doc(); d["spec"]["requirements"][0]["criteria"][0]["nope"] = "x"; probes["unknown field on a criterion"] = d
d = doc(); d["spec"]["displayName"] = "x";                    probes["displayName on spec"] = d
# `indicator`/`distribution` ("a series") no longer exist in the schema. They survived the
# assertion-first revert and were removed by 7f33bdf (#33/#34). This probe now tests the same class of
# closure (an object with additionalProperties: false, rejecting a displayName it never declared)
# on the one place still uncovered: the document root itself.
d = doc(); d["displayName"] = "x";                            probes["displayName at the document root"] = d
d = doc(); d["metadata"]["displayName"] = "x" * 201;          probes["displayName over 200 characters"] = d
d = doc(); d["metadata"]["displayName"] = "";                 probes["empty displayName"] = d
d = doc(); d["spec"]["requirements"][0]["guards"][0]["nope"] = "x"; probes["unknown field on a guard"] = d

# Everything above closes an object. What follows holds the rest of the schema to what its own
# descriptions promise, because none of it was covered: 65 of 78 single-constraint loosenings left
# this section green, including the whole closed vocabulary. `$defs/unit` says its enum exists
# "precisely so a typo like `mss` is a parse error rather than a disagreement between consumers" —
# nothing checked that, and a promise nothing checks is the thing this section exists to catch.

# The required fields, one per object. FR-002 names a missing required field as a closure the gate
# must fail on, and until now none was probed.
for where, field, mutate in [
    ("the document", "apiVersion", lambda d: d.pop("apiVersion")),
    ("the document", "kind",       lambda d: d.pop("kind")),
    ("the document", "metadata",   lambda d: d.pop("metadata")),
    ("the document", "spec",       lambda d: d.pop("spec")),
    ("metadata",     "name",       lambda d: d["metadata"].pop("name")),
    ("spec",         "requirements", lambda d: d["spec"].pop("requirements")),
    ("a requirement", "name",     lambda d: d["spec"]["requirements"][0].pop("name")),
    ("a requirement", "selector", lambda d: d["spec"]["requirements"][0].pop("selector")),
    ("a requirement", "criteria", lambda d: d["spec"]["requirements"][0].pop("criteria")),
    ("a criterion",  "aggregation", lambda d: d["spec"]["requirements"][0]["criteria"][0].pop("aggregation")),
    ("a criterion",  "op",        lambda d: d["spec"]["requirements"][0]["criteria"][0].pop("op")),
    ("a criterion",  "threshold", lambda d: d["spec"]["requirements"][0]["criteria"][0].pop("threshold")),
    ("a criterion",  "unit",      lambda d: d["spec"]["requirements"][0]["criteria"][0].pop("unit")),
]:
    d = doc(); mutate(d);                                     probes[f"{where} without {field}"] = d

# The closed vocabularies. Each is a value one letter away from a legal one, which is the mistake
# the enumerations exist to turn into a parse error rather than a disagreement between consumers.
d = doc(); d["spec"]["requirements"][0]["criteria"][0]["unit"] = "mss";         probes["a unit outside the enumeration"] = d
d = doc(); d["spec"]["requirements"][0]["criteria"][0]["op"] = "approx";        probes["an op outside the enumeration"] = d
d = doc(); d["spec"]["requirements"][0]["criteria"][0]["aggregation"] = "median-ish"; probes["an aggregation outside the set"] = d
d = doc(); d["spec"]["requirements"][0]["criteria"][0]["aggregation"] = "p999"; probes["a percentile of three digits"] = d
d = doc(); d["spec"]["requirements"][0]["criteria"][0]["threshold"] = "500ms";  probes["a threshold that is not a number"] = d
d = doc(); d["metadata"]["name"] = "Not A Name!";                              probes["a name outside the pattern"] = d
d = doc(); d["metadata"]["name"] = "x" * 254;                                  probes["a name over 253 characters"] = d
d = doc(); d["spec"]["requirements"][0]["criteria"] = [];                      probes["a requirement with no criteria"] = d
d = doc(); d["metadata"]["annotations"] = {"k": ["not", "a", "string"]};       probes["an annotation that is not a string"] = d
d = doc(); d["apiVersion"] = "opennfr.io/v2";                                  probes["an apiVersion this schema does not define"] = d

# The hierarchy. `loadtest.group.name` is the one attribute whose value shape the schema names,
# and it is named so the SCHEMA can reject a scalar and an empty list rather than leaving both
# to the gate. The fourth probe is the other half of that edit: `properties` was added beside
# `additionalProperties` and not instead of it, so an array under any other attribute is still
# refused. Widen that type list and only this probe notices.
for label, sel in [
    ("a scalar loadtest.group.name",      {"loadtest.group.name": "Checkout"}),
    ("an empty loadtest.group.name",      {"loadtest.group.name": []}),
    ("a group name that is not a string", {"loadtest.group.name": ["Checkout", 7]}),
    ("an array under another attribute",  {"http.route": ["a", "b"]}),
]:
    d = doc(); d["spec"]["requirements"][0]["selector"] = sel;                 probes[label] = d

# The shapes. A `type` is the quietest constraint to lose — drop one and a string passes where an
# object was required, with every other rule on that object silently inapplicable.
for label, mutate in [
    ("a document that is not an object",     lambda d: "a string"),
    ("metadata that is not an object",       lambda d: d.__setitem__("metadata", "x") or d),
    ("a spec that is not an object",         lambda d: d.__setitem__("spec", "x") or d),
    ("requirements that are not an array",   lambda d: d["spec"].__setitem__("requirements", "x") or d),
    ("no requirements at all",               lambda d: d["spec"].__setitem__("requirements", []) or d),
    ("a requirement that is not an object",  lambda d: d["spec"]["requirements"].__setitem__(0, "x") or d),
    ("criteria that are not an array",       lambda d: d["spec"]["requirements"][0].__setitem__("criteria", "x") or d),
    ("a criterion that is not an object",    lambda d: d["spec"]["requirements"][0]["criteria"].__setitem__(0, "x") or d),
    ("guards that are not an array",         lambda d: d["spec"]["requirements"][0].__setitem__("guards", "x") or d),
    ("an empty guards array",                lambda d: d["spec"]["requirements"][0].__setitem__("guards", []) or d),
    ("a name that is not a string",          lambda d: d["metadata"].__setitem__("name", 7) or d),
    ("a displayName that is not a string",   lambda d: d["metadata"].__setitem__("displayName", 7) or d),
    ("annotations that are not an object",   lambda d: d["metadata"].__setitem__("annotations", "x") or d),
    ("a selector that is not an object",     lambda d: d["spec"]["requirements"][0].__setitem__("selector", "x") or d),
    ("a selector value that is an object",   lambda d: d["spec"]["requirements"][0]["selector"].__setitem__("k", {}) or d),
    ("an aggregation that is not a string",  lambda d: d["spec"]["requirements"][0]["criteria"][0].__setitem__("aggregation", 7) or d),
    ("a metric that is not a string",        lambda d: d["spec"]["requirements"][0]["criteria"][0].__setitem__("metric", 7) or d),
    ("an empty metric",                      lambda d: d["spec"]["requirements"][0]["criteria"][0].__setitem__("metric", "") or d),
    ("a kind this schema does not define",   lambda d: d.__setitem__("kind", "Requirement") or d),
]:
    probes[label] = mutate(doc())

# The four cross-field rules on a predicate — the format's own semantics, and the only place they
# are stated machine-checkably. #38 removed a dead conditional from this file; nothing was watching
# whether the live ones stayed live.
# `rate` and a `%` unit, so the fraction rules are satisfied and only "not both" can reject it.
# Written with `max` instead, this probe passed for the wrong reason — the percentile rule caught
# it — and the rule it is named after could be deleted in silence.
d = doc(); c = d["spec"]["requirements"][0]["criteria"][0]
c["bad"] = {"error.type": "*"}; c["aggregation"] = "rate"; c["unit"] = "%"
probes["a predicate that is both a metric and a fraction"] = d
d = doc(); c = d["spec"]["requirements"][0]["criteria"][0]; c.pop("metric")
c["bad"] = {"error.type": "*"}; c["good"] = {"error.type": "*"}; c["aggregation"] = "rate"; c["unit"] = "%"
probes["a fraction carrying both of its sides"] = d
d = doc(); c = d["spec"]["requirements"][0]["criteria"][0]; c.pop("metric")
c["bad"] = {"error.type": "*"}; c["aggregation"] = "p99"; c["unit"] = "%"
probes["a percentile over a fraction"] = d
d = doc(); d["spec"]["requirements"][0]["criteria"][0].pop("metric")
probes["a spread with no metric to spread"] = d

# A probe that was deleted cannot fail. The base document above proves the probes stand on
# something valid; this proves the probes are still there to stand on it. A floor at zero would
# only catch emptying the dict outright, so it is set just under the current count: pruning most
# of the block is the realistic accident, and it would otherwise show up as nothing but a smaller
# number in a line nobody compares against anything.
FLOOR = 54
if len(probes) < FLOOR:
    print(f"  FAIL  {path}: {len(probes)} closure probes, expected at least {FLOOR} — "
          f"probes have been removed, and a probe that is gone cannot fail")
    sys.exit(1)

for name, bad_doc in probes.items():
    if not list(V(schema).iter_errors(bad_doc)):
        print(f"  FAIL  the schema accepts what it must reject: {name}")
        rc = 1

# One rule cannot be reached by a rejection probe. `A fraction has no percentile` is redundant for
# VALIDITY — a fraction has no metric, and every aggregation but `rate` and `count` requires one,
# so the document is rejected either way — but it is what produces the message README.md quotes.
# Delete it and the document is still refused, now blaming a missing `metric` the author never
# meant to write. That is a documented diagnostic degrading in silence, so it is checked by the
# message rather than by the verdict.
d = doc(); c = d["spec"]["requirements"][0]["criteria"][0]; c.pop("metric")
c["bad"] = {"error.type": "*"}; c["aggregation"] = "p95"; c["unit"] = "%"
WANT_MESSAGE = "'p95' is not one of ['rate', 'count']"
if not any(e.message == WANT_MESSAGE for e in V(schema).iter_errors(d)):
    print(f"  FAIL  a percentile over a fraction no longer says why: expected {WANT_MESSAGE!r}, "
          f"which README.md quotes as the message for this mistake")
    rc = 1

if rc == 0:
    print(f"  ok    {checked} embedded examples valid, {len(probes)} closures still reject")
sys.exit(rc)
SELFCHECK
fi

# ---------------------------------------------------------------------------
section "Examples are assertable by Gatling"
# An example nothing can run teaches a shape nobody can use. Gatling is the only target
# with a waiting counterparty, so the published corpus is held to what its assertion DSL
# can express — see README.md > "What any tool can actually run", which is the source
# these rows implement and the only place the tables are stated. Sourced to Gatling
# v3.15.1 and checked 2026-08-20.
#
# Capabilities PARTITION each axis: a predicate is assertable only if it matches a row
# below exactly. Anything unlisted is rejected, never allowed by default — a denylist
# would bless the next construct added to the schema without anyone noticing.
#
# This reads examples/ and NEVER the schema. The format is deliberately wider than the
# corpus: http.route, sum and neq are valid and no example uses them. Extending this
# section to read the schema would be the format narrowing to one tool, which the
# constitution's Principle VI forbids.
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the Gatling reach gate cannot run"
else
  python3 - <<'GATLING' || fail=1
import glob, sys
from fractions import Fraction
sys.path.insert(0, "scripts")
import identity
try:
    import yaml
except ImportError as e:
    print(f"  FAIL  {e.name} not installed (pip install pyyaml)"); sys.exit(1)

# The two keys that spell a request's recorded position. Written once: they appear in the key
# sets, in the value rules and in the flattener below, and four literals of one attribute name
# are four chances to fix three of them.
HIERARCHY = "loadtest.group.name"
REQUEST = "loadtest.request.name"

# Assertion scope is Global, ForAll, or Details(parts) — a path of recorded group and
# request names. Not a route, not a method, not a status code. Path parts are strings, and
# the hierarchy carries them as a list while the request name carries one.
#
# What each denotes: {} is every request pooled; a request name alone is that request with NO
# enclosing group, because an absent hierarchy beside a named request means the empty one; the
# pair is that request at whatever depth the list spells. {HIERARCHY} alone is absent on
# purpose, and settled rather than pending: it has a meaning, the requests whose hierarchy is
# exactly those groups, and no Gatling scope denotes the requests a path encloses.
SELECTIONS = [set(), {REQUEST}, {HIERARCHY, REQUEST}, {HIERARCHY}]

# Of those, the one that resolves to a GROUP rather than a request. `details(...)` on a
# group's path resolves to the group, whose statistics are its own, so this selection
# reaches exactly one quantity and every other selection reaches everything but it.
GROUP_ONLY = {HIERARCHY}

# Of those, the ones a quantifier has a scope for. `"*"` renders as forAll(), which takes no
# path, so a quantified selection carrying one has no correspondence. It is admitted only as
# the request-name value: anywhere else in a path it is not a recorded name. Held beside
# SELECTIONS so that adding a selection there forces a decision here instead of silently
# rejecting it.
QUANTIFIABLE = [{REQUEST}]

# Two addressable metrics, one per statistic on AssertionStatsRepository. `http.client.
# request.duration` was the only one until v0.8.0 and is retired, not aliased (#89): it is
# absent from METRICS, so a document carrying it is refused by the row that names it.
METRIC = "loadtest.request.duration"
GROUP_METRIC = "loadtest.group.duration"
METRICS = (METRIC, GROUP_METRIC)

# `bad` maps to failedRequests, which counts KO and nothing else, so the only numerator
# with an exact correspondence is "an error happened". A narrower filter — a status code,
# an error class — has no equivalent, and an empty one would count every request.
BAD = {"error.type": "*"}

# Conditions: lt, lte, gt, gte, between, around, deviatesAround, is, in. `eq` is `is`;
# there is no negation, so `neq` has no equivalent.
OPS = {"lt": "lt", "lte": "lte", "gt": "gt", "gte": "gte", "eq": "is"}

# The partition. (shape, aggregation) -> what Gatling asserts, in which units, and
# whether the target is an Int — a fractional value against an Int target is
# unrenderable rather than roundable, and rounding would move the bar silently.
TIME = {"ms": Fraction(1), "s": Fraction(1000)}          # -> native milliseconds
SHARE = {"%": Fraction(1), "1": Fraction(100)}           # -> native percent
COUNT = {"{request}": Fraction(1)}
PERSEC = {"{request}/s": Fraction(1)}
def percentile(a): return a.startswith("p") and a[1:].replace(".", "", 1).isdigit()

# The statistic each addressable metric resolves to. One `Stats` type serves both, so the units
# and the integer target are shared and only the name differs — but the name belongs to the METRIC,
# and the metric rows below carry a `{}` for it. Deriving it by rewriting the other name was a
# silent no-op the moment a native stopped containing "responseTime", and nothing probed it.
NATIVE = {METRIC: "responseTime", GROUP_METRIC: "groupCumulatedResponseTime"}

TABLE = {
    "metric": {
        "PERCENTILE": ("{}.percentile", TIME, True),
        "max":        ("{}.max",        TIME, True),
        "min":        ("{}.min",        TIME, True),
        "avg":        ("{}.mean",       TIME, True),
        "stddev":     ("{}.stdDev",     TIME, True),
    },
    "fraction": {
        "rate":  ("failedRequests.percent", SHARE, False),
        "count": ("failedRequests.count",   COUNT, True),
    },
    "requests": {
        "count": ("allRequests.count", COUNT, True),
        "rate":  ("requestsPerSec",    PERSEC, False),
    },
}

# Written once so the rule and the probes below cannot drift into different words.
NOT_A_PATH = "selector {} is not an assertion path"
NOT_A_STRING = "an assertion path part must be a string"
NOT_A_LIST = (f"{HIERARCHY} is a hierarchy: the enclosing groups outermost first, "
              "a list of names and never one name")
NO_GROUPS = (f"{HIERARCHY}: [] is not a hierarchy — a request with no enclosing group "
             f"is spelled by omitting the key")
QUANTIFIED = ('`"*"` is presence: in place of a request name it quantifies to forAll(), which '
              'carries no path, and in any other position no scope carries a wildcard path part')

def path_parts(sel):
    # The path a selector spells: its enclosing groups outermost first, then the request name.
    # The two keys carry different arities, so every rule below is written about a part rather
    # than about the key it came from. Only ever called once the hierarchy is known to be a
    # list — on a scalar, list() would spell it out one character at a time.
    return list(sel.get(HIERARCHY, [])) + ([sel[REQUEST]] if REQUEST in sel else [])

def selection_why(sel):
    # Why this selector is not an assertion path, or [] if it is. A function rather than
    # inline code so the probes below exercise the same rule the corpus is judged by;
    # two copies would be free to disagree, which is the defect this section is fixing.
    why = []
    if set(sel) not in SELECTIONS:
        why.append(NOT_A_PATH.format(sorted(sel)))
    elif HIERARCHY in sel and not isinstance(sel[HIERARCHY], list):
        # Before the parts are flattened, and never after. A scalar group name is a perfectly
        # good string, so flattened first it becomes one path part per CHARACTER — "Checkout"
        # is eight parts, all strings — and every rule below passes over it.
        why.append(NOT_A_LIST)
    elif HIERARCHY in sel and not sel[HIERARCHY]:
        why.append(NO_GROUPS)
    else:
        # Only here is the hierarchy known to be a non-empty list, which is what makes the
        # flattening safe — so the path is built once, after the branches above and never
        # before them, and both rules below read the same list.
        parts = path_parts(sel)
        if any(not isinstance(p, str) for p in parts):
            why.append(NOT_A_STRING)
        elif any(p == "*" for p in parts) and set(sel) not in QUANTIFIABLE:
            # `"*"` quantifies: the requirement is stated once of each request position the
            # selector admits. Gatling spells that forAll(), which takes no path, so "every
            # request inside one group" — and every other position `"*"` could occupy — has no
            # correspondence. The row follows from the anchoring rule rather than excepting it:
            # `"*"` is not a name, so no hierarchy is claimed and none may be carried. The test
            # reads the flattened path and not sel.values(): a hierarchy is a list and never
            # equals `"*"`, so under sel.values() this branch would be dead for every group
            # position.
            why.append(QUANTIFIED)
    return why

def predicate_why(p):
    # Why this predicate has no Gatling equivalent, or [] if it has one. A function for the same
    # reason selection_why is one: the probes below exercise the rule the corpus is judged by, and
    # two copies would be free to disagree. It was inline until v0.6.0, which is part of why the
    # predicate axes went unprobed — there was nothing a probe could call.
    why = []
    if p.get("metric", METRIC) not in METRICS:
        why.append(f"metric {p['metric']} is not addressable")

    shape = shape_of(p, why)
    agg = p.get("aggregation")
    row = None
    if shape:
        key = "PERCENTILE" if percentile(str(agg)) else agg
        row = TABLE[shape].get(key)
        if row is None:
            why.append(f"aggregation {agg} over a {shape} has no equivalent")

    if p.get("op") not in OPS:
        why.append(f"op {p.get('op')} has no equivalent")

    if row:
        native, units, integral = row
        # A no-op on the fraction and requests rows, which carry no placeholder.
        native = native.format(NATIVE.get(p.get("metric", METRIC), METRIC))
        factor = units.get(p.get("unit"))
        if factor is None:
            why.append(f"unit {p.get('unit')} is not a unit of {native}")
        elif integral and "threshold" not in p:
            # The one key the old inline block read without .get(). A predicate missing it is
            # schema-invalid, but this section reads examples/ and never the schema, so it has to
            # say so rather than abort the scan and leave the rest of the corpus unread.
            why.append(f"threshold is absent, and {native} takes one")
        elif integral:
            value = Fraction(str(p["threshold"])) * factor
            if value.denominator != 1:
                why.append(f"threshold {p['threshold']} {p['unit']} is {value} for {native}, "
                           f"whose target is an integer")
    return why

def shape_of(p, why):
    if ("bad" in p or "good" in p) and "metric" in p:
        # `bad`/`good` count requests, so the shape below reads no metric at all. Discarding a
        # key without a message is the #57 failure class, and it let a group metric ride a
        # fraction into a group scope asserting failedRequests.
        why.append(f"metric {p['metric']} is discarded by a fraction: `bad`/`good` counts "
                   f"requests, not a metric's observations")
        return None
    if "good" in p:
        # successfulRequests exists, but a selector matches presence and never absence,
        # so no OpenNFR fraction corresponds to it. See README > Names.
        why.append("`good` has no expressible numerator: a selector cannot say an attribute is absent")
        return None
    if "bad" in p:
        if p["bad"] != BAD:
            why.append(f"bad {p['bad']} is not `{{error.type: \"*\"}}`; failedRequests counts KO and nothing else")
            return None
        return "fraction"
    return "metric" if "metric" in p else "requests"

# Rules that REJECT have nothing in examples/ to prove they fire: the corpus holds only
# documents that validate and are assertable. Each probe is a selector this contract says
# cannot be rendered, paired with the reason its row gives. A probe that stops being
# rejected FAILs the section instead of passing quietly.
def pairing_why(sel, p):
    # The one place two axes decide together, and README > How these tables are applied says so.
    # A hierarchy with no request name resolves to a group, and a group's only assertable
    # statistic is its cumulated response time — so that selection admits GROUP_METRIC and
    # nothing else, and every other selection admits everything but it. Two `can` rows that do
    # not compose is exactly the thing a renderer cannot discover from the tables alone.
    group_sel = set(sel) == GROUP_ONLY
    group_metric = p.get("metric") == GROUP_METRIC
    if group_sel and not group_metric:
        return [f"a hierarchy with no request name resolves to a group, whose only assertable "
                f"statistic is {GROUP_METRIC}"]
    if group_metric and not group_sel:
        return [f"{GROUP_METRIC} is a group's own statistic, and this selection does not "
                f"resolve to a group"]
    return []

def render_why(sel, p):
    # Every rule the corpus is judged by, in one place. PAIRING_PROBES and PAIRING_RENDERS go
    # through this and not through pairing_why alone, so dropping a rule from the composite
    # reddens them — which is the only thing that can catch a rule deleted from the CALL rather
    # than from its own body.
    return selection_why(sel) + predicate_why(p) + pairing_why(sel, p)

# Each entry is a (selector, predicate) pair the joint rule must REJECT, and the reason its row
# gives. Neither axis alone can catch these: every one of them is built from a selection the
# Selection axis accepts and a predicate the Metrics axis accepts.
PAIRING_PROBES = [
    ({HIERARCHY: ["Checkout"]}, {"metric": METRIC, "aggregation": "p95", "op": "lte",
                                 "threshold": 500, "unit": "ms"},
     f"a hierarchy with no request name resolves to a group, whose only assertable statistic "
     f"is {GROUP_METRIC}"),
    ({HIERARCHY: ["Checkout"]}, {"aggregation": "count", "op": "lte", "threshold": 20,
                                 "unit": "{request}"},
     f"a hierarchy with no request name resolves to a group, whose only assertable statistic "
     f"is {GROUP_METRIC}"),
    ({REQUEST: "POST /checkout"}, {"metric": GROUP_METRIC, "aggregation": "p95", "op": "lte",
                                   "threshold": 500, "unit": "ms"},
     f"{GROUP_METRIC} is a group's own statistic, and this selection does not resolve to a group"),
    ({}, {"metric": GROUP_METRIC, "aggregation": "max", "op": "lte", "threshold": 500,
          "unit": "ms"},
     f"{GROUP_METRIC} is a group's own statistic, and this selection does not resolve to a group"),
]

# And the other direction. A rejection probe cannot show that the pair still RENDERS, and the
# corpus cannot either: nothing published selects a group.
PAIRING_RENDERS = [
    ({HIERARCHY: ["Checkout"]}, {"metric": GROUP_METRIC, "aggregation": "p95", "op": "lte",
                                 "threshold": 500, "unit": "ms"}),
    ({HIERARCHY: ["Checkout", "Payment"]}, {"metric": GROUP_METRIC, "aggregation": "max",
                                            "op": "lte", "threshold": 1, "unit": "s"}),
    ({}, {"metric": METRIC, "aggregation": "p99", "op": "lte", "threshold": 500, "unit": "ms"}),
    ({REQUEST: "POST /checkout"}, {"metric": METRIC, "aggregation": "avg", "op": "lte",
                                   "threshold": 500, "unit": "ms"}),
]

SELECTION_PROBES = [
    ({"http.route": "/api/v1/checkout"}, NOT_A_PATH.format(["http.route"])),
    ({HIERARCHY: "Checkout", REQUEST: "POST /checkout"}, NOT_A_LIST),
    ({HIERARCHY: "*", REQUEST: "POST /checkout"}, NOT_A_LIST),
    ({HIERARCHY: [], REQUEST: "POST /checkout"}, NO_GROUPS),
    ({REQUEST: 200},  NOT_A_STRING),
    ({REQUEST: True}, NOT_A_STRING),
    ({HIERARCHY: ["Checkout", 7], REQUEST: "POST /checkout"}, NOT_A_STRING),
    ({HIERARCHY: ["Checkout"], REQUEST: "*"}, QUANTIFIED),
    ({HIERARCHY: ["*"], REQUEST: "POST /checkout"}, QUANTIFIED),
]

# And the other direction. A rejection probe cannot show that a row still RENDERS, and the
# corpus cannot either: nothing published nests two groups, so a depth bound added to the rule
# above would leave every check here green. These must produce no reason at all.
SELECTION_RENDERS = [
    {},
    # Was a REJECTION probe until v0.8.0, when #89 minted the name the old refusal was waiting
    # on. It is not deleted, it changed direction — which is why the rejection floor below drops
    # by one and this one rises by one, rather than either being quietly relaxed.
    {HIERARCHY: ["Checkout"]},
    {REQUEST: "POST /checkout"},
    {REQUEST: "*"},
    {HIERARCHY: ["Checkout"], REQUEST: "POST /checkout"},
    {HIERARCHY: ["Checkout", "Payment"], REQUEST: "GET /test/id"},
]

# And the other four axes, which had NO probe at all until v0.6.0. Selection was probed; metric,
# aggregation, operator and unit were not, so every rejection rule on them was unexercised and any
# could have been deleted green. The corpus cannot stand in for them — it holds only documents that
# are assertable. That is how TABLE["metric"] carried `count` and `rate`, rendering a shape these
# tables reject and discarding the `metric` key without a message, for five releases (#57).
#
# Each entry is one axis's rule, exercised through predicate_why — the same function the corpus is
# judged by, never a copy of it. Written as a mutation of one renderable predicate so a probe
# differs from a passing one in exactly the thing it tests.
RENDERABLE = {"metric": METRIC, "aggregation": "p95", "op": "lte", "threshold": 500, "unit": "ms"}
PREDICATE_PROBES = [
    ({**RENDERABLE, "aggregation": "count", "unit": "{request}"},
     "aggregation count over a metric has no equivalent"),
    ({**RENDERABLE, "aggregation": "rate", "unit": "{request}/s"},
     "aggregation rate over a metric has no equivalent"),
    ({**RENDERABLE, "aggregation": "sum"},
     "aggregation sum over a metric has no equivalent"),
    ({**RENDERABLE, "metric": "http.client.response.body.size"},
     "metric http.client.response.body.size is not addressable"),
    # The retired name (#89). Its `cannot` row is the only published row whose rule is an
    # ABSENCE — it is refused by not being in METRICS — so nothing else would notice it being
    # let back in, and a mutation adding it survived every other probe here.
    ({**RENDERABLE, "metric": "http.client.request.duration"},
     "metric http.client.request.duration is not addressable"),
    # The only probe that reads a group statistic's NAME. Without it the metric-to-native
    # mapping could be wrong or absent and every other probe stayed green, because the group
    # metric appeared solely in rendering probes, which assert no message at all.
    ({**RENDERABLE, "metric": GROUP_METRIC, "unit": "%"},
     "unit % is not a unit of groupCumulatedResponseTime.percentile"),
    # And a fraction may not smuggle a metric past the shape, which discards it.
    ({"metric": GROUP_METRIC, "bad": BAD, "aggregation": "rate", "op": "lte",
      "threshold": 5, "unit": "%"},
     f"metric {GROUP_METRIC} is discarded by a fraction: `bad`/`good` counts requests, "
     f"not a metric's observations"),
    ({**RENDERABLE, "op": "neq"},
     "op neq has no equivalent"),
    ({**RENDERABLE, "unit": "%"},
     "unit % is not a unit of responseTime.percentile"),
    ({**RENDERABLE, "threshold": 0.1},
     "threshold 0.1 ms is 1/10 for responseTime.percentile, whose target is an integer"),
    ({k: v for k, v in RENDERABLE.items() if k != "threshold"},
     "threshold is absent, and responseTime.percentile takes one"),
    ({"good": {"error.type": "*"}, "aggregation": "rate", "op": "lte", "threshold": 5, "unit": "%"},
     "`good` has no expressible numerator: a selector cannot say an attribute is absent"),
    ({"bad": {"http.response.status_code": 500}, "aggregation": "rate", "op": "lte",
      "threshold": 5, "unit": "%"},
     'bad {\'http.response.status_code\': 500} is not `{error.type: "*"}`; '
     "failedRequests counts KO and nothing else"),
]

# And the other direction, which the first draft of this section did without on the grounds that
# the corpus already exercises every accepted shape. It does not: the corpus is ten predicates and
# reaches five of TABLE's nine rows, four of six unit keys and two of five operators, so `min`,
# `avg`, `stddev`, `allRequests.count`, a fraction in `1`, and three of the four comparisons could
# each be deleted with this section still green. Same argument as SELECTION_RENDERS, one axis over.
#
# The first entry is the base every probe above mutates. Without it the whole table can pass on a
# broken baseline: drop `lte` from OPS and all the rejection probes still fire their own reason
# alongside the new one, because the check is membership and not equality.
#
# The `name` entry is the Identity axis's only probe, and it is a rendering one because that axis
# rejects nothing: predicate_why never reads the key, and nothing else in the repository carries
# one — not a corpus document, not a probe. A rejection added on `name` would be caught by nothing
# at all (#82).
PREDICATE_RENDERS = [
    RENDERABLE,
    {**RENDERABLE, "name": "p95-latency"},
    {"metric": GROUP_METRIC, "aggregation": "p95", "op": "lte", "threshold": 500, "unit": "ms"},
    {**RENDERABLE, "aggregation": "max"},
    {**RENDERABLE, "aggregation": "min"},
    {**RENDERABLE, "aggregation": "avg"},
    {**RENDERABLE, "aggregation": "stddev"},
    {**RENDERABLE, "aggregation": "p99.9", "unit": "s", "threshold": 1},
    {**RENDERABLE, "op": "lt"},
    {**RENDERABLE, "op": "gt"},
    {**RENDERABLE, "op": "gte"},
    {**RENDERABLE, "op": "eq"},
    {"aggregation": "count", "op": "lte", "threshold": 20, "unit": "{request}"},
    {"aggregation": "rate", "op": "gte", "threshold": 200, "unit": "{request}/s"},
    {"bad": {"error.type": "*"}, "aggregation": "rate", "op": "lte", "threshold": 0.05, "unit": "1"},
    {"bad": {"error.type": "*"}, "aggregation": "count", "op": "lte", "threshold": 20, "unit": "{request}"},
]

# The gate's metric names must be the names README publishes. `METRIC` is anchored by the
# corpus, which carries its literal; `GROUP_METRIC` is carried by no document, so renaming it
# left the gate green while it rejected the published name as "not addressable".
rc, checked = 0, 0
_reach = open("README.md", encoding="utf-8").read().split("## What any tool can actually run", 1)
if len(_reach) != 2:
    print("  FAIL  README.md has no section 'What any tool can actually run' to implement")
    sys.exit(1)
for _name in (METRIC, GROUP_METRIC):
    if f"`{_name}`" not in _reach[1]:
        print(f"  FAIL  {_name} is not a metric README publishes — the gate and the page "
              f"disagree about the name")
        rc = 1

# A pruned probe table reports no failures and reads exactly like a sound one. ALL FOUR floors are
# EXACT, and that is deliberate — the closure floor above sits just under its count because its
# probes overlap, and these do not. Each probe here is the sole catcher of its own class.
#
# Two of them are worth naming, because each is one deletion away from a rule nothing checks.
# The depth-2 rendering probe is the sole catcher of a depth bound anywhere in the rule, and
# the corpus cannot stand in for it: nothing published nests two groups. The `["*"]` rejection
# probe is the sole catcher of the quantifier test reading sel.values() instead of the
# flattened path, where a hierarchy is a list, never equals `"*"`, and leaves the branch dead.
# At a floor of one less, either could be dropped green and the rule it guards broken green
# afterwards: two steps, both passing. Adding a probe means raising the number beside it,
# which is the intended cost.
#
# The two predicate floors are exact for a related but different reason, worth stating because it is
# not the sentence above: each REJECTION probe is the sole catcher of one rule regressing, and three
# of them share the aggregation-row lookup while catching three distinct regressions. Each RENDERING
# probe is the sole catcher of one published `can` row being deleted, which no rejection probe and
# no corpus document can show.
FLOORS = [("rejection", SELECTION_PROBES, 9), ("rendering", SELECTION_RENDERS, 6),
          ("predicate rejection", PREDICATE_PROBES, 13), ("predicate rendering", PREDICATE_RENDERS, 16),
          ("pairing rejection", PAIRING_PROBES, 4), ("pairing rendering", PAIRING_RENDERS, 4)]
for _label, _probes, _floor in FLOORS:
    if len(_probes) < _floor:
        print(f"  FAIL  {len(_probes)} {_label} probes, expected at least {_floor} — "
              f"a rule nothing probes is a rule nothing checks")
        sys.exit(1)
for probe, expected in SELECTION_PROBES:
    got = selection_why(probe)
    if expected not in got:
        print(f"  FAIL  probe {probe}: expected rejection {expected!r}, got {got or 'accepted'}")
        rc = 1
for probe in SELECTION_RENDERS:
    got = selection_why(probe)
    if got:
        print(f"  FAIL  probe {probe}: renders, but the rule rejects it: {'; '.join(got)}")
        rc = 1
for probe, expected in PREDICATE_PROBES:
    got = predicate_why(probe)
    if expected not in got:
        print(f"  FAIL  probe {probe}: expected rejection {expected!r}, got {got or 'accepted'}")
        rc = 1
for sel, pred, expected in PAIRING_PROBES:
    got = render_why(sel, pred)
    if expected not in got:
        print(f"  FAIL  pairing probe {sel} x {pred.get('metric')}: expected {expected!r}, "
              f"got {got or 'accepted'}")
        rc = 1
for sel, pred in PAIRING_RENDERS:
    got = render_why(sel, pred)
    if got:
        print(f"  FAIL  pairing render {sel} x {pred.get('metric')}: rejected — {got}")
        rc = 1
for probe in PREDICATE_RENDERS:
    got = predicate_why(probe)
    if got:
        print(f"  FAIL  probe {probe}: renders, but the rule rejects it: {'; '.join(got)}")
        rc = 1

files = sorted(glob.glob("examples/*.yaml"))
if not files:
    print("  FAIL  examples/ holds no document to check")
    sys.exit(1)
for f in files:
    with open(f, encoding="utf-8") as fh:
        docs = list(yaml.safe_load_all(fh))
    for doc in docs:
        if not isinstance(doc, dict):
            continue
        for r in doc.get("spec", {}).get("requirements", []) or []:
            sel = r.get("selector") or {}
            # One selector judges both: it is written once for the requirement and binds
            # every criterion and guard beneath it, so a quantified selection quantifies a
            # guard too.
            for section in ("guards", "criteria"):
                for p in r.get(section) or []:
                    checked += 1
                    why = render_why(sel, p)

                    if why:
                        cid = identity.predicate_id(p)
                        print(f"  FAIL  {f}: {r.get('name')}/{section}/{cid}: " + "; ".join(why))
                        rc = 1
# A scan that checked nothing reads exactly like a scan that passed.
if checked == 0:
    print("  FAIL  no predicate found to check — the scan is broken")
    sys.exit(1)
if rc == 0:
    print(f"  ok    {checked} predicates assertable by Gatling, "
          f"{len(SELECTION_PROBES)} selection probes still rejected, "
          f"{len(SELECTION_RENDERS)} still rendered, "
          f"{len(PREDICATE_PROBES)} predicate probes still rejected, "
          f"{len(PREDICATE_RENDERS)} still rendered, "
          f"{len(PAIRING_PROBES)} pairing probes still rejected, "
          f"{len(PAIRING_RENDERS)} still rendered")
sys.exit(rc)
GATLING
fi

# ---------------------------------------------------------------------------
section "Internal markdown links resolve"
# A raw grep for `](...)` cannot tell a markdown link from a regular expression that happens to
# close a bracket group with a parenthesis inside a code span — issue #43. What a link is now
# lives in scripts/mdlinks.py, shared with the isolation section below so the two cannot drift
# into disagreeing about the same text.
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the link-resolution gate cannot run"
else
  python3 - <<'LINKS' || fail=1
import os, sys
sys.path.insert(0, "scripts")
import mdlinks

# The extractor is held to its own fixtures before anything trusts it. #43 was a scanner that
# had been wrong about what a link is for as long as it had existed, and nothing noticed.
wrong = mdlinks.selftest()
for m in wrong:
    print(f"  FAIL  the link extractor is wrong: {m}")
if wrong:
    sys.exit(1)

def md_files():
    # Same population the previous grep pipeline scanned: every *.md file, except those under a
    # top-level dot-directory (.git/, .github/, .specify/, .claude/) or a dot-prefixed root file.
    for root, dirs, files in os.walk("."):
        if root == ".":
            dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in sorted(files):
            if f.endswith(".md") and not (root == "." and f.startswith(".")):
                yield os.path.join(root, f)

root = os.getcwd()
missing = 0
found = 0
for src in sorted(md_files()):
    try:
        text = open(src, encoding="utf-8").read()
    except (OSError, UnicodeDecodeError) as e:
        # One unreadable file used to abort the section on a traceback: no ok, no FAIL, and
        # every file after it unscanned. It fails as a file now, and the scan continues.
        print(f"  FAIL  {src}: cannot be read as UTF-8 ({e})")
        missing = 1
        continue
    base = os.path.dirname(src)
    for target in mdlinks.targets(text):
        found += 1
        resolved = mdlinks.resolve(root, base, target)
        if resolved is None:
            continue                                   # anchor or placeholder, addresses no file
        if not os.path.exists(resolved):
            print(f"  FAIL  {src} -> {target}")
            missing = 1

# Zero links means the extraction above stopped working, not that the docs are clean.
if found == 0:
    print("  FAIL  no markdown links found — the link extraction is broken")
    sys.exit(1)
elif missing == 0:
    print(f"  ok    no dangling internal links ({found} checked)")
sys.exit(1 if missing else 0)
LINKS
fi

# ---------------------------------------------------------------------------
section "docs/ is isolated"
# Constitution Principle VIII, all three clauses, checked rather than asserted:
#   - docs/ holds ideas and nothing else — markdown only, so nothing there can be a
#     document the format's own gates would otherwise have to validate;
#   - nothing outside docs/ links into it, so `git rm -r docs` breaks nothing;
#   - every idea states what would have to become true before it could enter the format.
#
# specs/ is exempt and it is the ONLY exemption: it is the spec-kit working record, read
# as history and left as written. Dot-directories are NOT exempt — .github/ and
# .specify/ hold markdown that a reader follows, and a link from there into docs/ would
# dangle the moment the ideas area is dropped.
if ! command -v python3 >/dev/null 2>&1; then
  bad "python3 not found — the isolation gate cannot run"
else
  python3 - <<'ISOLATION' || fail=1
import os, re, subprocess, sys

def tracked():
    out = subprocess.run(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
                         capture_output=True, check=True).stdout
    return sorted(f for f in out.decode("utf-8").split("\0") if f)

try:
    files = tracked()
except (OSError, subprocess.CalledProcessError) as e:
    print(f"  FAIL  cannot enumerate files ({e}) — the isolation gate cannot run")
    sys.exit(1)

rc = 0

# --- docs/ holds markdown and nothing else -----------------------------------------
strays = [f for f in files if f.startswith("docs/") and not f.endswith(".md")]
for f in strays:
    print(f"  FAIL  {f}: docs/ holds ideas and nothing else — markdown only")
    rc = 1

# --- every idea says what would have to become true ---------------------------------
ideas = "docs/ideas.md"
if os.path.exists(ideas):
    text = open(ideas, encoding="utf-8").read()
    entries = re.findall(r"^\*\*(.+?)\*\*", text, re.M)
    needs = text.count("*Would need*")
    if not entries:
        print(f"  FAIL  {ideas}: no idea found — the entry scan is broken")
        rc = 1
    elif needs != len(entries):
        print(f"  FAIL  {ideas}: {len(entries)} ideas, {needs} say what would have to "
              f"become true — Principle VIII requires one each")
        rc = 1

# --- nothing outside docs/ links into it --------------------------------------------
# The same definition of a link the resolution section uses. Held apart, the two disagreed:
# a code span naming a path under docs/ was text to one gate and a violation to the other,
# which made the isolation rule impossible to document in the documents it governs.
sys.path.insert(0, "scripts")
import mdlinks

root = os.getcwd()
scanned = 0
sources = [f for f in files
           if f.endswith(".md") and not f.startswith(("docs/", "specs/"))]
if not sources:
    print("  FAIL  no markdown found outside docs/ — the isolation scan is broken")
    sys.exit(1)
for f in sources:
    base = os.path.dirname(f)
    try:
        text = open(f, encoding="utf-8").read()
    except (OSError, UnicodeDecodeError) as e:
        print(f"  FAIL  {f}: cannot be read as UTF-8 ({e})")
        rc = 1
        continue
    for target in mdlinks.targets(text):
        # Pure path arithmetic: no chdir, so nothing can silently fail to resolve.
        resolved = mdlinks.resolve(root, base, target)
        if resolved is None:
            continue
        scanned += 1
        if resolved == os.path.join(root, "docs") or resolved.startswith(os.path.join(root, "docs") + os.sep):
            print(f"  FAIL  {f} links into docs/ -> {target}")
            rc = 1
if scanned == 0:
    print("  FAIL  no links found outside docs/ — the isolation scan is broken")
    sys.exit(1)
if rc == 0:
    print(f"  ok    docs/ is markdown-only, every idea states its condition, "
          f"and none of {scanned} links outside it points in")
sys.exit(rc)
ISOLATION
fi

# ---------------------------------------------------------------------------
section "Docs are English"
# Everything published is in English. Cyrillic left in a file
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
printf '\n'
if [ "$fail" -ne 0 ]; then
  printf 'FAIL\n'
  exit 1
fi
printf 'PASS\n'
