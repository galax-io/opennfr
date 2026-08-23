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
    """One definition, validatable on its own: its siblings minus the examples."""
    out = {k: v for k, v in node.items() if k != "examples"}
    out["$defs"] = schema["$defs"]
    return out

# The schema reference points a reader at the schema's examples, so a definition that carries none
# is a promise broken in the one place nobody looks. Counted per definition: a total
# hides the empty one behind the full ones.
WANT = ["selector", "predicate", "requirement"]
for name in WANT:
    if not schema["$defs"].get(name, {}).get("examples"):
        print(f"  FAIL  {path}: $defs/{name} carries no examples")
        rc = 1
for where, node in sorted(schema["$defs"].items()):
    for i, ex in enumerate(node.get("examples", [])):
        checked += 1
        for e in V(sub(node)).iter_errors(ex):
            print(f"  FAIL  {path}: {where} example {i}: {e.message}")
            rc = 1
if checked == 0:
    print(f"  FAIL  {path} carries no examples — the check scanned nothing")
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
# `indicator`/`distribution` ("a series") no longer exist in the schema — dead since the
# assertion-first design they belonged to was reverted. This probe now tests the same class of
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
FLOOR = 50
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
# can express — see specs/004-strip-to-schema/contracts/gatling-reach.md, sourced to
# Gatling v3.15.1 and checked 2026-08-20.
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
try:
    import yaml
except ImportError as e:
    print(f"  FAIL  {e.name} not installed (pip install pyyaml)"); sys.exit(1)

# Assertion scope is Global, ForAll, or Details(parts) — a path of recorded group and
# request names. Not a route, not a method, not a status code. Path parts are strings.
SELECTIONS = [set(), {"loadtest.request.name"}, {"loadtest.group.name", "loadtest.request.name"}]

# responseTime is the only addressable metric family.
METRIC = "http.client.request.duration"

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

TABLE = {
    "metric": {
        "PERCENTILE": ("responseTime.percentile", TIME, True),
        "max":        ("responseTime.max",        TIME, True),
        "min":        ("responseTime.min",        TIME, True),
        "avg":        ("responseTime.mean",       TIME, True),
        "stddev":     ("responseTime.stdDev",     TIME, True),
        "count":      ("allRequests.count",       COUNT, True),
        "rate":       ("requestsPerSec",          PERSEC, False),
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

def shape_of(p, why):
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

rc, checked = 0, 0
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
            for section in ("guards", "criteria"):
                for p in r.get(section) or []:
                    checked += 1
                    why = []

                    if set(sel) not in SELECTIONS:
                        why.append(f"selector {sorted(sel)} is not an assertion path")
                    elif any(not isinstance(v, str) for v in sel.values()):
                        why.append("an assertion path part must be a string")

                    if p.get("metric", METRIC) != METRIC:
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
                        factor = units.get(p.get("unit"))
                        if factor is None:
                            why.append(f"unit {p.get('unit')} is not a unit of {native}")
                        elif integral:
                            value = Fraction(str(p["threshold"])) * factor
                            if value.denominator != 1:
                                why.append(f"threshold {p['threshold']} {p['unit']} is {value} for {native}, "
                                           f"whose target is an integer")

                    if why:
                        cid = p.get("name") or agg
                        print(f"  FAIL  {f}: {r.get('name')}/{section}/{cid}: " + "; ".join(why))
                        rc = 1
# A scan that checked nothing reads exactly like a scan that passed.
if checked == 0:
    print("  FAIL  no predicate found to check — the scan is broken")
    sys.exit(1)
if rc == 0:
    print(f"  ok    {checked} predicates, all assertable by Gatling")
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
