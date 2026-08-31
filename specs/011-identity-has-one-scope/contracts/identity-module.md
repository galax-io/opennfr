# Contract — #72: the branch fires, and stays fired

**Commit**: `fix(gate): the identity rule is probed in both directions (#72)`
**Files**: `scripts/identity.py` *(new)*, `scripts/verify.sh`, `AGENTS.md`

Today both uniqueness branches can be replaced with `if False:` and the gate still prints **PASS**. This commit makes each of four things fail: deleting the rule, deleting either call site, deleting a probe, and hardening the rule into "every pair collides".

---

## 1. `scripts/identity.py` — new

The module holds the rule once. It does **not** restate the scope in prose: that lives in `README.md` § *A predicate*, and a comment repeating it is the copy #58 is about.

```python
"""What a predicate's identity is, and where two of them collide.

Shared by the two sections of scripts/verify.sh that check it — one over examples/, one over the
schema's own root examples — so the two cannot drift into disagreeing about the same rule. The
rule is stated in README.md > A predicate and is not restated here.

Until v0.8.0 nothing exercised any of this. No document in the repository carries a colliding
identity and none carries a `name` at all, so both branches could be replaced with `if False:`
with the gate still printing PASS, and the `name` arm of the fallback had never been observed.
"""

SECTIONS = ("criteria", "guards")


def predicate_id(predicate):
    """The identity of one predicate: its `name` if set, its `aggregation` otherwise."""
    return predicate.get("name") or predicate.get("aggregation")


def collisions(requirement, scanned):
    """Yield every collision, appending to `scanned` once per list compared.

    A generator, so the count each call site floors is a by-product of CONSUMING the check.
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
    """Every collision as a list. What the probes judge."""
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
     "a guard and a criterion sharing an identity — the exemption examples/the-run-held-up.yaml relies on"),
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
```

### What each probe is the sole catcher of

| # | Catches |
|---|---|
| 1 | the aggregation arm, in `criteria` — the rule itself |
| 2 | the rule reaching `guards` at all. The corpus has one guard and can never collide |
| 3 | the **`name` arm**, which nothing in the repository has ever exercised |
| 4 | the rule hardened into "every pair collides" |
| 5 | the two arms silently becoming two namespaces |
| 6 | the per-list reset — the exemption #58 settles |

Probe 6 overlaps what the corpus already shows: flatten the two lists and `examples/the-run-held-up.yaml` fails. FR-017 requires that be said rather than assumed. It is included anyway, because the corpus exists to hold what a target can run and is free to change for reasons unrelated to this rule, and a probe is here to hold the rule.

---

## 2. `scripts/verify.sh` — § *Examples validate against the schema*

The `SCHEMA` heredoc (lines 118–172).

**Add at the top of the heredoc**, beside the existing imports, in the shape `LINKS` already uses at `:901-911`:

```python
sys.path.insert(0, "scripts")
import identity

# The rule is held to its own probes before anything trusts it. Both branches that checked it
# could be replaced with `if False:` and this gate still printed PASS — issue #72.
wrong = identity.selftest()
for m in wrong:
    print(f"  FAIL  the identity rule is wrong: {m}")
if wrong:
    sys.exit(1)

identity_lists = 0
```

**Replace lines 157–166** — the inline rule, and *not* the comment above it — with a call:

```python
        for r in doc.get("spec", {}).get("requirements", []) or []:
            for section, cid in identity.collisions(r, identity_lists):
                print(f"  FAIL  {f}: {r.get('name')}/{section}: duplicate criterionId {cid!r}")
                errs = errs or [1]
                rc = 1
```

**And replace the comment at `:155-156`** (FR-008). It reads *"criterionId is the name if set, otherwise the aggregation. The schema cannot express that fallback, so uniqueness is checked here"* — after the extraction that is a second copy of the module's own docstring **and** a false sentence, because the check is no longer here. It becomes a pointer:

```python
        # The identity rule, and why the schema cannot carry it, live in scripts/identity.py.
```

Note the boundary: the comment is lines **155–156** and the rule is **157–166**. Replacing from 156 deletes half a sentence and leaves the other half standing.

**Add before `sys.exit(rc)`** — the floor, and the line that says what ran (FR-020):

```python
IDENTITY_LISTS = 5
if identity_lists < IDENTITY_LISTS:
    print(f"  FAIL  the identity check read {identity_lists} lists, expected at least "
          f"{IDENTITY_LISTS} — a check that scanned nothing reads exactly like one that passed")
    rc = 1
elif not rc:
    print(f"  ok    identity: {len(identity.PROBES)} probes still hold, "
          f"{identity_lists} lists read")
```

`rc = 1` rather than `sys.exit(1)`, because the section reports every failure it finds before exiting; that is what the rest of this heredoc does.

The `ok` line exists because this section had no aggregate line at all — it printed one line per file and nothing about the rule it was also applying. § *Examples are assertable by Gatling* reports its four probe counts on one line for exactly this reason, and a rule whose probes ran is worth the same sentence. Its counts are what a reviewer compares against a later release: **6 probes, 5 lists** at v0.8.0.

**`selftest()` runs here and not in both consumers**, which is what `mdlinks` does: it is called in `LINKS` and not in `ISOLATION`. This section runs first, and a failure here reddens the run before the second consumer is reached.

---

## 3. `scripts/verify.sh` — § *The schema holds up its own examples, and still rejects*

The `SELFCHECK` heredoc (lines 198–522).

**Replace lines 340–350** with:

```python
sys.path.insert(0, "scripts")
import identity

root_identity_lists = 0
for i, ex in enumerate(schema.get("examples", [])):
    for r in (ex.get("spec", {}) or {}).get("requirements", []) or []:
        for part, cid in identity.collisions(r, root_identity_lists):
            print(f"  FAIL  {path}: root example {i}: {r.get('name')}/{part}: "
                  f"duplicate criterionId {cid!r}")
            rc = 1

ROOT_IDENTITY_LISTS = 1
if root_identity_lists < ROOT_IDENTITY_LISTS:
    print(f"  FAIL  {path}: the identity check read {root_identity_lists} lists of the schema's "
          f"own examples, expected at least {ROOT_IDENTITY_LISTS}")
    rc = 1
```

The comment above the old loop — that the root examples answer to what the corpus answers to, and that the one document an editor offers first was the one nothing checked — is kept.

---

## 4. `AGENTS.md` § *Structure*

One clause.

| | |
|---|---|
| **Before** | ``scripts/` -> the gate (`verify.sh`) and what it shares (`mdlinks.py`)` |
| **After** | ``scripts/` -> the gate (`verify.sh`) and what it shares (`mdlinks.py`, `identity.py`)` |

A map correction, not a rule. It rides with this commit because this commit adds the file the sentence describes.

---

## The seven mutations this commit makes fail

Four *classes* — deleting the rule, hardening it, deleting a call site, deleting a probe — and seven mutations that exercise them. The list is the same seven [quickstart.md](../quickstart.md) § 3 runs; there is one canonical set and this is it.

| Mutation | What fails |
|---|---|
| `duplicates()` returns `[]` always | probes 1, 2, 3, 5 — `selftest()` |
| `duplicates()` reports every pair | probes 4, 6 — `selftest()` |
| the `name` arm removed from `predicate_id` | probe 3, and probe 5 |
| the per-section reset removed | probe 6, and `examples/the-run-held-up.yaml` |
| the `SCHEMA` collisions loop dropped, every other line kept | `IDENTITY_LISTS`: `read 0 lists, expected at least 5` |
| the `SELFCHECK` collisions loop dropped, every other line kept | `ROOT_IDENTITY_LISTS`: `read 0 lists … expected at least 1` |
| a probe deleted | `FLOOR` |

Today, every one of these is green.

## Acceptance

- `bash scripts/verify.sh` green, and § *Examples validate against the schema* prints `ok    identity: 6 probes still hold, 5 lists read`.
- Each mutation above, applied alone, makes the gate exit non-zero.
- `git diff --stat` over `examples/`, `README.md`, `GLOSSARY.md` and `schema/` is empty for this commit.
