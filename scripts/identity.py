"""What a predicate's identity is, and where two of them collide.

Shared by the two sections of scripts/verify.sh that check it — one over examples/, one over
the schema's own root examples — so the two cannot drift into disagreeing about the same rule.
The rule is stated in README.md > A predicate and is not restated here.

Until v0.8.0 nothing exercised any of this. No document in the repository carries a colliding
identity and none carries a `name` at all, so both branches could be replaced with `if False:`
with the gate still printing PASS, and the `name` arm of the fallback had never been observed
(issue #72).
"""

SECTIONS = ("criteria", "guards")


def predicate_id(predicate):
    """The identity of one predicate: its `name` if set, its `aggregation` otherwise."""
    return predicate.get("name") or predicate.get("aggregation")


def collisions(requirement, scanned):
    """Yield every collision in one requirement, as (section, predicateId), in the order found.

    A generator on purpose, and `scanned` gains one entry per list compared. The count the call
    sites floor is therefore a by-product of CONSUMING this: a call site that keeps the count
    while dropping the loop keeps nothing, because an unconsumed generator appends nothing.
    An earlier shape counted lists through a second function, and both call sites could then
    drop the check with their floors still satisfied.
    """
    for section in SECTIONS:
        predicates = requirement.get(section)
        if predicates is None:
            continue
        scanned.append(section)
        seen = set()
        for p in predicates:
            cid = predicate_id(p)
            if cid in seen:
                yield section, cid
            seen.add(cid)


def duplicates(requirement):
    """Every collision in one requirement, as a list. What the probes below judge."""
    return list(collisions(requirement, []))


# Each probe is a requirement paired with what duplicates() must return for it. Four must report a
# collision and two must report none: a rejection probe cannot show that the rule still ACCEPTS,
# and without that direction a rule hardened into "every pair collides" passes every probe here.
# Same argument as SELECTION_RENDERS and PREDICATE_RENDERS, one rule over.
PROBES = [
    ({"criteria": [{"aggregation": "rate"}, {"aggregation": "rate"}]},
     [("criteria", "rate")],
     "two unnamed criteria sharing an aggregation"),

    ({"criteria": [{"aggregation": "p95"}],
      "guards": [{"aggregation": "rate"}, {"aggregation": "rate"}]},
     [("guards", "rate")],
     "two unnamed guards sharing an aggregation — the corpus holds one guard and can never collide"),

    ({"criteria": [{"name": "peak", "aggregation": "p95"},
                   {"name": "peak", "aggregation": "max"}]},
     [("criteria", "peak")],
     "the `name` arm: colliding names over differing aggregations"),

    ({"criteria": [{"name": "a", "aggregation": "rate"},
                   {"name": "b", "aggregation": "rate"}]},
     [],
     "distinct names over one aggregation — the direction no rejection probe can show"),

    ({"criteria": [{"aggregation": "rate"}, {"name": "rate", "aggregation": "count"}]},
     [("criteria", "rate")],
     "a `name` equal to another predicate's aggregation — one namespace, not two"),

    ({"guards": [{"aggregation": "rate"}], "criteria": [{"aggregation": "rate"}]},
     [],
     "a guard and a criterion sharing an identity — the exemption the-run-held-up.yaml relies on"),
]

# A pruned probe list reports nothing and reads exactly like a sound one. The floor is EXACT: each
# probe above is the sole catcher of its own class, and adding one means raising this number.
FLOOR = 6


def selftest():
    """Every probe this module gets wrong, as a list of strings. Empty when sound."""
    wrong = []
    if len(PROBES) < FLOOR:
        wrong.append(f"the probe list has shrunk to {len(PROBES)}, expected at least {FLOOR} — "
                     f"a rule nothing probes is a rule nothing checks")
    for requirement, want, why in PROBES:
        got = duplicates(requirement)
        if got != want:
            wrong.append(f"{why}: expected {want}, got {got}")
    return wrong
