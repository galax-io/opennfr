# Contract — #82: identity has no slot in a Gatling assertion

**Commit**: `docs(format): identity has no slot in a Gatling assertion (#82)`
**Files**: `README.md`, `scripts/verify.sh`

The reach tables claim to partition every axis and to admit a predicate only on an exact row match. A predicate has nine keys; `name` and `displayName` have no row anywhere. This commit gives them one, on an axis that decides nothing about assertability, and adds the one probe that can show it decides nothing.

**The row stops at the assertion.** A target description is what a renderer reads to turn a requirement into assertions; what Gatling does with an assertion afterwards is not something this format describes, and the row must not drift into describing it.

---

## 1. `README.md` § *Gatling* — a new `#### Identity`

Placed **after § *Units*** and **before § *Two things Gatling cannot do at all***, with the other axes (FR-022).

```markdown
#### Identity

A predicate's identity — its `name`, or the `aggregation` standing in where no `name` is set — is
what tells it from the other predicates in its list. This axis is the one that decides nothing:
every predicate below is assertable, and the verdict says what becomes of the key when the predicate
is rendered, not whether the statement runs.

| OpenNFR | Gatling | |
|---|---|---|
| `name`, and the `aggregation` that stands in for it | — | **not carried** — `Assertion` is `(path, target, condition)`, and no field of it holds a label. The predicate renders; the key does not travel with it, and two requirements that select the same requests and state the same criterion render to equal `Assertion` values |
| `displayName` | — | **not carried**, and nothing is lost by it: the key is inert. Nothing selected, measured or compared depends on it, so a target that drops it drops nothing the format claims |

**not carried** is a third verdict and says what neither of the others can: the predicate renders,
and the key does not travel into what it renders to. It is not **cannot** — a predicate carrying a
`name` is assertable, and a renderer refusing one would be narrowing the format to what a target
happens to carry.

**Sourced** to `io.gatling.commons.stats.assertion.Assertion`,
read with `javap` from `gatling-shared-model` 0.0.11 — the release Gatling
**3.13.5** pins. **Checked 2026-08-31.** That is a different version from the **3.15.1** the four
sources above were read at, and it is named rather than rounded to match them: 3.15.1 was not
available where this was checked. `Assertion` is byte-identical in the release Gatling 3.11.5 pins,
so the shape held across two minors — which is what is known, and is not a claim about a third.
```

### Why each part

| Part | Requirement | Why |
|---|---|---|
| the axis covers the `aggregation` fallback, not just `name` | FR-023 | an unnamed predicate still has an identity, and it is the arm every published document uses |
| the reason stops at `Assertion` | FR-025 | `AssertionResult` and `AssertionMessage` were read too ([research.md](../research.md) R1) and are **left out**: they are about what a target does with an assertion, and a target description says what a renderer produces, not what happens to it afterwards. The claim needs only the three fields and the absence of a fourth |
| the version is 3.13.5 and the difference is stated | FR-026 | Principle IV wants the version read and the date checked. Borrowing the header's 3.15.1 would date a claim at a version nobody opened, which is the defect the row is being written to fix |
| `displayName` gets its own row and its own reason | FR-027 | it is the second key the partition claim was false for. #82 argues it needs no row *because* it is inert; the row is how "inert" gets said and the partition gets fixed at once |
| **not carried** is explained under the table | FR-024 | a third verdict in a target's description is a cost, and a reader meeting it needs to know it is not a softer **cannot** |

`AssertionModel.scala`, where `Assertion` is defined, is **already** among the four sources § *Gatling*'s header names. The section gains a differently dated reading of a file it already cites, not a new source.

---

## 2. `README.md` § *How these tables are applied*

Added after the existing paragraph beginning **"The tables partition each axis."** (line 726).

```markdown
All nine of a predicate's keys now have a row. Seven decide whether it is assertable — `metric`,
`aggregation`, `op`, `threshold`, `unit`, `bad`, `good` — and the two on the Identity axis do not,
which is why their verdict is **not carried** rather than **can** or **cannot**. The gate therefore
implements no rejection from that axis, and the one thing there is to check about it is that it
rejects nothing: `PREDICATE_RENDERS` carries a predicate with a `name`, and it renders.
```

FR-028. The claim stops being false without being narrowed, and the sentence says where the gate stands, so a reader does not have to infer that an axis with no rejection is an axis with no implementation.

---

## 3. `scripts/verify.sh` — one rendering probe, one floor

Nothing in the repository puts a `name` on a predicate: not the 10 corpus predicates, not the schema's root example, not one of the 24 `PREDICATE_PROBES` and `PREDICATE_RENDERS` entries ([research.md](../research.md) R7). A line added to `predicate_why` refusing a `name` would be caught by nothing.

**`PREDICATE_RENDERS` gains one entry**, beside the existing base:

```python
    {**RENDERABLE, "name": "p95-latency"},
```

**The floor beside it goes 14 → 15**:

```python
FLOORS = [("rejection", SELECTION_PROBES, 10), ("rendering", SELECTION_RENDERS, 5),
          ("predicate rejection", PREDICATE_PROBES, 10), ("predicate rendering", PREDICATE_RENDERS, 15)]
```

**And a sentence joins the comment above `PREDICATE_RENDERS`**, in the register the existing ones use:

```python
# The `name` entry is the Identity axis's only probe, and it is a rendering one because that axis
# rejects nothing: `predicate_why` never reads the key, and nothing else in the repository carries
# one — not a corpus document, not a probe. A rejection added on `name` would otherwise be caught
# by nothing at all.
```

`verify.sh:826` already states the cost as a rule — *"Adding a probe means raising the number beside it, which is the intended cost"* — and it is paid here rather than waived (FR-030).

**No rejection is added** (FR-031). `predicate_why` is untouched: it reads `metric`, `aggregation`, `op`, `threshold`, `unit`, `bad` and `good`, and that is the behaviour the row publishes.

---

## What this commit does **not** touch

| | Why |
|---|---|
| `GLOSSARY.md` | the row records what a target does with an existing term and introduces none (FR-032) |
| `examples/` | unchanged, as throughout the milestone |
| the § *Gatling* header's version and dates | it stays at 3.15.1 for its four sources. The Identity row carries its own, and says why they differ |
| § *Two things Gatling cannot do at all* | it keeps its name. Identity is not a third thing Gatling cannot do — the assertion runs — which is why it is an axis and not a bullet there |
| `predicate_why` | see FR-031 |

## Acceptance

- `bash scripts/verify.sh` green, and § *Examples are assertable by Gatling* reports **15** predicate rendering probes.
- Adding `if "name" in p: why.append(...)` to `predicate_why` makes the gate exit non-zero. Today it does not.
- Listing the nine predicate keys against the reach section leaves none unaddressed.
- The Identity row states a Gatling version and a date, and a reader can tell they are not the header's.
