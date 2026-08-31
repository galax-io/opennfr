# Phase 1 — Data Model: Identity Has One Scope

**Feature**: `011-identity-has-one-scope` | **Date**: 2026-08-31 | **Spec**: [spec.md](spec.md)

No field is added, removed or retyped. What this milestone changes is what an existing derived value is **scoped to**, what **checks** it, and what a target does with it. The entities below are the ones that scope, check and description each name.

---

## Identity (`criterionId`)

**What it is**: what tells one predicate from the others in its list.

| | |
|---|---|
| **Derivation** | the predicate's `name` if set, its `aggregation` otherwise |
| **Type** | string. The `name` arm matches `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$` and is at most 253 characters; the `aggregation` arm is one of the closed set or a percentile matching `^p\d{1,2}(\.\d+)?$` |
| **Unique within** | **one list** — after #58. `criteria` and `guards` are two lists |
| **Stated in** | `README.md` § *A predicate*, and nowhere else |
| **Checked by** | `scripts/verify.sh`, through `scripts/identity.py` |
| **Defined in** | `GLOSSARY.md` § *criterionId* |
| **Expressible in JSON Schema** | no. The fallback is a conditional over two keys and a set membership across siblings |

**The two arms are one namespace.** `name: rate` beside an unnamed `rate` collides, because both predicates produce the identity `rate`. This falls out of the derivation rather than being an extra rule, and probe 5 exists so nothing quietly turns it into two namespaces.

**It is unique within a list, not within a document.** `(requirement.name, list, criterionId)` is what is unique across a whole document, and that is what "unique within one list" amounts to. It is why the flagship example is legal — its two `rate` predicates differ in the middle component.

**Not a field.** `criterionId` never appears in a document. It is a derived value with a name, which is why it has a `GLOSSARY.md` entry and no schema property.

---

## A list

**What it is**: `criteria` or `guards` on one requirement — the unit an identity is unique within.

| | |
|---|---|
| **Members** | predicates, structurally identical between the two lists |
| **Cardinality** | `criteria` is required and `minItems: 1`; `guards` is optional and, when present, `minItems: 1` |
| **Meaning of the split** | a violated criterion says *the system did not hold*; a violated guard says *the run did not happen as intended* |
| **In the corpus** | 5 lists across 4 requirements, holding 10 predicates |

**Why the list and not the requirement.** `rate` over the requests, `rate` over a metric's observations and `rate` over a fraction are three quantities under one word, and `README.md` § *A predicate* already says the predicate's shape decides which. Two of them meeting inside one requirement is a lexical coincidence, not an ambiguous document — and the two lists are already statements about different things, a guard about whether the run happened and a criterion about whether the system held.

---

## A predicate's nine keys, against the reach axes

The reach section claims to partition every axis. After #82 it does.

| Key | Axis | Decides assertability |
|---|---|---|
| `metric` | Metrics | yes |
| `aggregation` | Aggregations | yes |
| `op` | Operators | yes |
| `unit` | Units | yes |
| `threshold` | Units — the integer-target rule | yes |
| `bad` | Aggregations — the fraction rows | yes |
| `good` | Aggregations — the fraction rows | yes |
| `name` | **Identity** *(new)* | **no** |
| `displayName` | **Identity** *(new)* | **no** |

Seven decide; two do not. The two that do not are the two that had no row.

---

## A reach row

**What it is**: one line of a target's description, matched exactly, carrying a verdict and a reason.

| Verdict | Means | Gate behaviour |
|---|---|---|
| **can** | the target asserts this exactly | `predicate_why` returns no reason |
| **cannot** | the target has no correspondence | `predicate_why` returns the row's reason |
| **not carried** *(new)* | the predicate renders; the key does not travel into the assertion | `predicate_why` returns no reason, and never reads the key |

**not carried** is not a weaker **cannot**. A predicate carrying a `name` is assertable, and a gate that started refusing one would be narrowing the format to what a target happens to carry — which is what `scripts/verify.sh` is explicitly forbidden from doing.

**It says nothing about what the target does afterwards.** A target description is what a renderer reads to produce assertions. Where an assertion goes, how a target reports it and what a consumer makes of it are outside this page, and the row stops at the boundary.

---

## The identity check

**What it is**: the rule `README.md` states, implemented once and reached from two places.

| | |
|---|---|
| **Home** | `scripts/identity.py` |
| **Surface** | `predicate_id(predicate)`, `collisions(requirement, scanned)`, `duplicates(requirement)`, `selftest()` |
| **Consumers** | `scripts/verify.sh` § *Examples validate against the schema* (over `examples/*.yaml`) and § *The schema holds up its own examples, and still rejects* (over the schema's root `examples`) |
| **Why a module** | the two consumers are separate `python3` heredocs — separate processes. `scripts/mdlinks.py` is the same problem, solved the same way, for the reason its own comment gives |
| **Trusted after** | `selftest()` returns empty. Called before the first consumer uses it, as `mdlinks.selftest()` is |

---

## An identity probe

**What it is**: a requirement paired with the collisions `duplicates()` must report for it.

| | |
|---|---|
| **Shape** | `(requirement, expected, why)` where `expected` is a list of `(list, criterionId)` |
| **Directions** | both. Four probes must report a collision; two must report none |
| **Count** | 6, floored at 6 |
| **Floor message** | *a rule nothing probes is a rule nothing checks* — the sentence `scripts/verify.sh` already uses |

The classes each probe is the sole catcher of are in [research.md](research.md) R4.

---

## A counted scan

**What it is**: what fails when a *call site* is deleted rather than a rule.

| Site | Unit counted | Today | Floor |
|---|---|---|---|
| `examples/*.yaml` | lists offered to the check | 5 | 5 |
| the schema's root `examples` | lists offered to the check | 1 | 1 |

Probes cannot catch this: they call the module directly, and a deleted call leaves them green. Principle III requires it in terms — *any check that scanned nothing MUST say so* — and `scripts/verify.sh` already does the same thing twice, at `EXAMPLES = 20` and at the isolation section's `scanned`.
