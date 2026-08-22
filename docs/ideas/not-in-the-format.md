# Fields that were argued for and left out

> The format itself is [README.md](../../README.md) and [the schema reference](../../schema/README.md); how it works is [ARCHITECTURE.md](../../ARCHITECTURE.md).

**Notes, not rules.** Every field below was designed, argued about, and is absent from
[the schema](../../schema/opennfr.io/v1/requirementset.schema.json). Writing one into a
document is a validation error today.

They are kept because the argument is worth more than the field, and because the next person
to want one should find out what it costs before proposing it rather than after.

---

## indicator

**Status: retired.** The construct is gone; what it held is still in the format, in two
places.

`indicator` was an object on the requirement, holding what to measure and which requests to
measure it over. It had two shapes, borrowed from OpenSLO's `thresholdMetric` and `ratioMetric`
— [ADR-0001 § D8](../adr/0001-terminology.md):

```yaml
indicator:
  distribution:                              # a metric, measured
    metric: http.client.request.duration
    selector: {http.route: /api/v1/checkout}
```
```yaml
indicator:
  ratio:                                     # a fraction, counted
    total: {metric: ..., selector: {...}}
    bad:   {metric: ..., selector: {error.type: "*"}}
```

[ADR-0003](../adr/0003-selection-belongs-to-the-requirement.md) took it apart. The substance is
unchanged — a metric is measured, a fraction is counted, an error rate is still
`bad: {error.type: "*"}` with no invented errors metric — but the selection moved up to the
requirement and what is measured moved down to the predicate.

**What it cost while it stood.** Holding the selection inside the indicator forced a
requirement about one endpoint being *fast* and *reliable* to become two requirements with the
same selector written twice: two objects for one human sentence, and two places to edit when a
route changes. A `ratio` also had to name a metric it did not measure — an error-rate
requirement read `metric: http.client.request.duration` because a histogram's count is the
request count and OpenTelemetry defines no HTTP client request counter. The document was correct
and read as though it were about latency.

Rejected alongside it: keeping the selection per criterion.

---

## window

**Status: blocked on something nothing emits.**

Where in time the measurement is taken — the everyday nuisance of not counting ramp-up and
ramp-down:

```yaml
window:
  phase: steady     # rampUp | steady | rampDown | full
  rolling: 1m       # optional — a rolling window instead of one aggregate per phase
```

`phase` rests on a `loadtest.phase` attribute. **Nothing emits it.** It is proposed in
[semconv/loadtest.md](../semconv/loadtest.md), which states in its own text that it has been
submitted nowhere. A construct whose only meaning comes from an attribute no target produces is
a field that always matches everything, which is a silent green with a schema around it.

What would unblock it: a surveyed target that labels its own phases, or an adapter that can
reconstruct them from a load profile the format does not carry.

Rejected: `timeWindow` (OpenSLO) — redundant. `interval`, `period` — vague about which end is
meant.

---

## baseline and tolerance

**Status: blocked on data nothing stores.**

Comparison against a previous run instead of against an absolute number, mutually exclusive
with `threshold`:

```yaml
- aggregation: p95
  op: lte
  baseline: {source: previousPassed}
  tolerance: {value: 10, unit: "%"}
```

Reads as *"p95 is no more than 10 % worse than the baseline"*. The direction follows from `op`
— `lte` upwards, `gte` downwards — so strings like Keptn's `"<=+10%"` are unnecessary, and
`tolerance.unit` may be `%` for relative or the metric's own unit for absolute.

The design is fine. The dependency is not: it needs stored history of previous runs, and no
load generator provides one. Admitting it would mean the format depends on a store that is not
described anywhere, chosen by nobody, and different for every user.

---

## severity and gate

**Status: a knob nobody has asked for yet.**

`severity` — `blocker | warning | info` on a criterion — and `gate`, the policy that turns many
results into one:

```yaml
gate:
  onBlocker: fail
  onWarning: warn
  onInfo: ignore
  onNoData: fail
  onGuardViolation: inconclusive
```

Three severity levels rather than four, because in practice nobody distinguishes a `critical`
sitting between `blocker` and `warning`.

Today any failed criterion fails the run, and that is enough. The pair adds a policy language
to a format whose whole argument is that it has no language — and `gate` in particular was
written when this project expected to compute the outcome itself, which it no longer does.
See [the-result-document.md](the-result-document.md).

A worked example of the cost: an early draft's `onNoData: fail` meant a run in which nothing
failed produced no series carrying `error.type`, hence no data, hence a failed run. The system
was perfect and the gate said no.

---

## enforcement and onViolation

**Status: a target capability described as a format field.**

`enforcement` said where a criterion is checked — `post` after the run, `inline` during it, or
`both` — and `onViolation: abort` said to stop the run, mapping to k6's `abortOnFail` and
Taurus's `stop as failed`.

Both describe what a target can do, not what a requirement says. A requirement that carries
them is a requirement that names a target by implication, which
[Principle VI](../../.specify/memory/constitution.md) forbids: *"A requirement document MUST
NOT name a target: not in a field, a value, a metric name, or an example."*

Where a target can abort, that is a fact about the target and belongs in the target's own
description, dated and sourced — not in the document that is supposed to outlive it.

`enforcement` also assumed a `post` path that constitution 2.0.0 put out of scope.

---

## defaults and indicatorRef

**Status: sugar.**

`defaults` writes shared settings once at the document level and lets requirements inherit
them. `indicatorRef` names a reusable indicator instead of repeating one.

Both buy brevity. `defaults` costs merge semantics — what happens when a requirement overrides
one key of an inherited map, and does a reader know without checking — and the answer is a set
of rules every consumer has to implement identically, which is the failure the format exists to
prevent. `indicatorRef` costs a second way to say one thing, and pointed at a `Requirement` name
in the drafts that used it while the glossary described `Indicator` as a kind of its own.

The duplication `defaults` was meant to remove is largely gone anyway: since
[ADR-0003](../adr/0003-selection-belongs-to-the-requirement.md) the selector is written once per
requirement rather than once per criterion.

---

## The load profile

**Status: not a "yet".**

Stages, arrival rate, duration — the description of the load to be generated, as opposed to the
requirement it has to satisfy.

The tools do not agree on what an open or a closed workload model does under degradation, so
borrowing the construct would import that disagreement into a format whose only asset is that
one document means one thing. It is also the part the tools already do well.

The word `workload` is [reserved and unused](../GLOSSARY.md#workload) for exactly this, so that
it is not consumed by the wrong meaning first.
