# Parked: constructs no target can assert

**Status: parked. Last true: 2026-08-21.**

**What would promote each of these:** a surveyed target that can assert it **exactly**. That is
the constitution's admission rule, and it is a floor rather than a licence — one target being
able to assert a construct is necessary and is not by itself sufficient.

**What would retire them:** a finding that no target will ever assert them, which nobody has
established and which would be hard to establish honestly.

---

## Why these are here rather than in the glossary

Both were listed as things the format did not have "yet". Under the admission rule the word
*yet* is the wrong one: they are not waiting on this project's effort, they are waiting on a
capability that does not exist in any surveyed tool. Keeping them in the vocabulary as
forthcoming would let a reader plan around them.

They are **not rejected**. Each was wanted, each is argued below, and each returns the day
something can check it.

---

## baseline and tolerance

Comparison against a previous run instead of an absolute threshold. Mutually exclusive with
`threshold`.

```yaml
- aggregation: p95
  op: lte
  baseline: { source: previousPassed }
  tolerance: { value: 10, unit: "%" }
```

Reads as *"p95 is no more than 10 % worse than the baseline"*.

**The arguments worth keeping:**

- **The direction of the tolerance follows from `op`** — `lte` means upwards, `gte` downwards —
  so a string form like Keptn's `"<=+10%"` is unnecessary. That rejection lives permanently in
  ADR-0001 § D4, which forbids parsing meaning out of strings; this entry is not its home.
- **`tolerance.unit` may be `%` (relative) or the metric's own unit** (absolute, e.g. `50 ms`).
  One field, two readings, disambiguated by the unit — the same device that makes `threshold`
  unambiguous.

**Why no target can assert it:** it needs stored history of previous runs. No load generator
keeps one. This is not a gap in any tool's assertion DSL; it is a gap in what a load generator
is.

## window

Restricting a measurement to a run phase, or to a rolling interval.

```yaml
window:
  phase: steady     # rampUp | steady | rampDown | full
  rolling: 1m       # optional — a rolling window instead of one aggregate per phase
```

`phase` solved an everyday nuisance: not counting ramp-up and ramp-down in a percentile.

**Rejected names:** `timeWindow` (OpenSLO) — redundant, the word *window* already means a span
of time; `interval`, `period` — both vague about whether they mean a span or a repetition.

**Why `phase` cannot be asserted:** it rests on a `loadtest.phase` attribute that nothing
emits. The attribute is proposed in `docs/semconv/loadtest.md`, which is itself an unsubmitted
upstream proposal.

**`rolling` is a separate question and was never screened.** It does not depend on the missing
attribute, and whether any target can assert over a rolling window has not been checked. It is
parked here with `phase` for convenience rather than because the same argument covers it — and
whoever revives this should screen `rolling` on its own before assuming it shares `phase`'s
fate. ADR-0001's open question about it remains open.

---

## A note on what "parked" costs here

Both constructs were in the glossary, which the constitution calls the product. Moving them out
is not free: a reader who wanted *"no worse than last time"* now finds nothing in the
vocabulary and may conclude the project never considered it. That is the trade — an honest
absence over a promise nothing can keep — and this file is where the consideration went.
