# ADR-0003. Selection belongs to the requirement, not to the indicator

- **Status:** accepted
- **Date:** 2026-08-21
- **Amends:** [ADR-0001 § D8](0001-terminology.md) — the two indicator shapes

> Field names in a published example are a compatibility-sensitive surface, which the
> constitution says may not change without an ADR. This is that record.

## Context

[ADR-0001 § D8](0001-terminology.md) gave an indicator two shapes, modelled on OpenSLO:

```yaml
indicator:                            indicator:
  distribution:                         ratio:
    metric: <name>                        total: { selector: {...} }
    selector: {...}                       bad:   { selector: {error.type: "*"} }
```

The shapes are right and stay. What was wrong is where the **selection** sat: inside the shape.
An indicator is one per requirement, so a requirement could be about one measured thing — and
"checkout is fast **and** does not fail" is two measured things about one endpoint.

```yaml
- name: checkout-duration
  indicator:
    distribution:
      metric: http.client.request.duration
      selector: {http.route: /api/v1/checkout}      # written here
  criteria: [{aggregation: p99, op: lte, threshold: 500, unit: ms}]

- name: checkout-errors
  indicator:
    ratio:
      total: {http.route: /api/v1/checkout}         # and again here
      bad:   {error.type: "*"}
  criteria: [{aggregation: rate, op: lte, threshold: 5, unit: "%"}]
```

Two requirements, one endpoint, the selector twice. A reader asked why, and there was no good
answer: it is not two statements about the system, it is one statement the shape could not hold.

## Decision

**The requirement carries the selection.** Every criterion and guard under it is about those
requests.

**A criterion carries what it is about**, at most one of:

| Carries | About | Aggregations |
|---|---|---|
| `metric` | a quantity those requests carry | percentiles, `avg`, `min`, `max`, `stddev`, `sum`, `count`, `rate` |
| `bad` or `good` | a fraction of those requests | `rate` (the share), `count` (how many) |
| neither | the requests themselves | `count`, `rate` |

```yaml
- name: checkout
  displayName: Checkout is fast and reliable
  selector: {http.route: /api/v1/checkout}
  criteria:
    - {metric: http.client.request.duration, aggregation: p99, op: lte, threshold: 500, unit: ms}
    - {bad: {error.type: "*"},               aggregation: rate, op: lte, threshold: 5,   unit: "%"}
```

The `total` of a fraction is the requirement's selection, so it is never written twice.

The schema enforces the combinations: a percentile without a metric is rejected (no values to
take one of), a percentile with `bad` is rejected (a percentile of a fraction is not a number
anyone wants), and `metric` with `bad` is rejected (one measures, the other counts).

## Why this and not the alternatives

**It matches how the tools scope assertions.** Gatling opens a scope once —
`details("Group" / "Request")` — and hangs `responseTime.percentile(99)` and
`failedRequests.percent` off the same scope. k6 tags a metric and asserts several thresholds on
it. In both, selection is one level up from the statistic, which is where this puts it. The old
shape had to repeat the scope per statistic and then map two requirements onto one.

**It removes a construct.** `indicator` and `series` are gone as objects; `selector` moves up
one level; the criterion gains two optional keys. Net: fewer nested shapes, one fewer place for
a selection to live.

**D8's substance survives.** A metric is measured, a fraction is counted, and an error rate is
still `bad: {error.type: "*"}` with no invented errors metric — which is what D8 was protecting.
Only the nesting changed.

## Consequences

**Breaking.** Every document changes: `indicator.distribution.selector` becomes the
requirement's `selector`, `indicator.distribution.metric` moves onto each criterion, and a
`ratio` becomes a criterion carrying `bad`. Both published examples were rewritten in the same
change.

**`metric` is repeated across criteria of one requirement** when several measure the same
quantity — five percentiles of a duration name it five times. That is the cost, and it is the
lesser one: a repeated metric name is a repeated fact about the same requirement, where a
repeated selector was a repeated fact split across two.

**The word `indicator` loses its object** and keeps its meaning in the glossary, as the
counterpart of an SLI.

## Rejected alternatives

**Leave it and accept the duplication.** What the format did until now. It is defensible while
a requirement has one criterion and stops being defensible at two, which is the common case.

**A shared-defaults construct** — write the selector once at the document level and inherit it.
It removes the same duplication and adds merge semantics: what happens when a requirement
overrides one key of an inherited selector, and does a reader know without checking. FORMAT.md
already lists `defaults` among the things left out, and this decision does not need it.

**Let a requirement hold several indicators.** Keeps the shapes intact and makes the requirement
a list of lists — the selection still repeats per indicator, so it fixes nothing and adds
nesting.

## References

- [ADR-0001 § D8](0001-terminology.md) — the two shapes, and the OpenSLO names they came from
- [`schema/README.md`](../../schema/README.md) — the shape, worked on one run
- [`FORMAT.md`](../../FORMAT.md)
