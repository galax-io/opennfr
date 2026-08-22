# Contract: The four component roles

**Feature**: [spec.md](../spec.md) | **Status**: proposed until the architecture document lands

The interface this project exposes is not an API — it is the set of jobs an implementer may
build, and the boundaries they may not cross. FR-002 requires each named component to state
its input, its output, and at least one thing it is forbidden to depend on. The count of four
is a decision of this contract, corroborated by compatibility.md § Layering — no requirement
fixes it, and it is proposed until the architecture document lands.

These contracts are **authored here**, not inherited from
[compatibility.md](../../../reference/compatibility.md) § Layering, which gives responsibilities
without contracts and sits in that document's proposal half. Two of the four are sub-roles of
the glossary's `Adapter`; the architecture document must say so rather than introduce a rival
decomposition.

---

## R1 · Parse

**Job**: turn a document into an in-memory object model.

| | |
|---|---|
| **Input** | One document, in the JSON-compatible YAML subset of ADR-0002 § D16 |
| **Output** | An object model, or a parse error naming the offending field and its line |
| **Forbidden** | Knowing which target will consume the result. Parse is target-independent or the format is not |

**Guarantees the output carries** — proposed here, bound later by the `object-model`
follow-up spec. The unknown-field rule is committed text in ADR-0002 § D17:

- Unknown fields were rejected, not ignored. A typo like `agregation:` is an error, never a
  silently skipped criterion — ADR-0002 § D17.
- Mutually exclusive alternatives were resolved to exactly one: `distribution` xor `ratio`,
  `indicator` xor `indicatorRef`, `threshold` xor `baseline`+`tolerance`.
- Units are present. `unit` is mandatory, so the model has no unitless number.
- The declared profile version is known, independently of the file's name or location.

**Failure mode this exists to prevent**: lenient parsing turning a run green because a field
name was misspelled.

---

## R2 · Render *(sub-role of `Adapter`)*

**Job**: turn criteria into a target's native artifact.

| | |
|---|---|
| **Input** | Criteria from the object model, plus one tool mapping |
| **Output** | The target's native artifact, **plus a named list of every criterion it could not render** |
| **Forbidden** | Deciding whether the run passes. Render emits; it never judges |

**Hard rule** (FR-007): every criterion is either rendered or reported unrenderable
**by criterion identity**. Dropping one silently is forbidden — a dropped criterion is a check
that never ran and a result that looks clean.

**Known asymmetry the walkthroughs must show**: the survey gives k6 native thresholds and
abort, Gatling native assertions without abort, and JMeter neither. Render therefore returns a
non-empty unrenderable list for JMeter by construction, and that is a correct outcome, not a
failure of the role.

---

## R3 · Ingest *(sub-role of `Adapter`; called **file adapter** where it reads files)*

**Job**: turn a target's raw output into comparable measurements.

| | |
|---|---|
| **Input** | A target's raw output — an OTLP stream, a JTL file, a `simulation.log` — plus one tool mapping |
| **Output** | Normalised series under canonical names, in canonical units, with attributes renamed |
| **Forbidden** | Knowing what the criteria say. Ingest must not normalise differently because of what will be asked of the data |

**Unit conversion is part of the contract, not a detail.** The survey records tools reporting
milliseconds where semconv requires seconds. An error here is three orders of magnitude wide
and produces a confident, wrong, green result, which is why the conversion is stated in the
mapping rather than left to the implementation.

**Naming note**: `reader` is **not** this role's name. In this specification `reader` means a
human, and two success criteria rest on that sense.

---

## R4 · Evaluate

**Job**: reduce measurements and criteria to verdicts, and verdicts to one outcome.

| | |
|---|---|
| **Input** | Normalised series, criteria, guards, and the `gate` policy |
| **Output** | One verdict per criterion and per guard, then one outcome through `gate` |
| **Forbidden** | Knowing which target produced the measurements, or how they were obtained |

**This is Principle VI**, and it is the only reason one document can mean one thing across
seven targets. Its sharpest consequence: a statistic the target already computed — k6's own
p95 — **must not be consumed as a verdict**. The moment it is, the verdict depends on the
tool's percentile machinery, and the same document means different things in different places.

**Outcomes that are not pass**, and which the role must produce rather than collapse:

| State | Meaning | Never |
|---|---|---|
| `noData` | The selection matched nothing | a pass |
| `inconclusive` | A guard failed — the run did not happen as intended | a pass or a fail |

**Four defects in the current gate vocabulary** that the walkthroughs will expose. They are
pre-existing, not introduced by this contract, and each needs an issue:

1. `overall-availability` yields no series when nothing fails → `noData` → `onNoData: fail`.
   The run fails because the system was perfect.
2. A guard on a metric a target cannot measure lands on `onNoData: fail` rather than
   `onGuardViolation: inconclusive`, so a tool limitation reads as a system failure.
3. `skipped` appears in the status enum and in the report sketch, but **no `gate` key handles
   it**. Silence is undefined behaviour in a project whose Principle III forbids exactly that.
4. `indicatorRef: checkout-latency` points at a Requirement name, while ADR-0001 § D10 and the
   glossary describe `Indicator` as a reusable kind of its own.

---

## The path, end to end

```text
requirement → criterion → verdict → gate → outcome
     R1            R1        R4       R4      R4
                   R2 renders criteria into the target
                   R3 supplies R4 the measurements
```

The trace ends at **outcome**, not verdict. A `Verdict` is the result of checking one criterion;
what a CI job prints is the aggregated `Outcome`. Ending at verdict stops one component short
of `gate`.

---

## What no role may do

- **No role may read the requirement document to find its data source.** The source is a
  parameter of evaluation, never a property of the requirement — ADR-0002 § D18.
- **No construct may be checkable only while a run is in progress.** Anything expressible must
  also be evaluable afterwards, or the format silently excludes every tool that cannot assert
  inline. This is already a ratified constitutional constraint.
- **No role may substitute a measurement it can obtain for one it cannot.** A client-side
  latency is not a server-side latency; a gap is declared, never filled by the nearest
  available number.
