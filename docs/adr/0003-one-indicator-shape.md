# ADR-0003. One indicator shape; `rate` and `share` are different words

- **Status:** accepted
- **Date:** 2026-08-21
- **Amends:** [ADR-0001 § D5](0001-terminology.md) — the two-shape indicator

> Field names in a published example are a compatibility-sensitive surface, which the
> constitution says may not change without an ADR. This is that record.

## Context

The format had two indicator shapes:

```yaml
indicator:                          indicator:
  distribution:                       ratio:
    metric: <name>                      total: {metric: <name>, selector: {}}
    selector: {...}                     bad:   {metric: <name>, selector: {error.type: "*"}}
```

`distribution` for a quantity with values, `ratio` for a fraction of requests. Three things
were wrong with it, and a reader found the first by looking at an example and asking why
duration was in a requirement about errors.

**A `ratio` named a metric it never read.** Its two sides carried
`http.client.request.duration` because a histogram's count is the request count — formally
true, and it made an error-rate requirement say `duration` twice. The metric was there to
satisfy the shape, not to be measured.

**`ratio` duplicated `rate`.** The fraction-ness was stated once by the indicator shape and
again by the aggregation. Two places, one fact.

**`rate` meant two things.** Over a `distribution` it was requests per second; over a `ratio`
it was a proportion. Nothing but the enclosing shape told them apart, so the same word in the
same field meant `{request}/s` in one document and `%` in the next.

## Decision

**One indicator shape.** `selector` says which requests; `metric` says what to measure of them
and is **optional**. Omitted, the requirement is about the requests themselves.

```yaml
indicator: {metric: http.client.request.duration, selector: {loadtest.request.name: GET /}}
indicator: {selector: {}}
```

**The aggregation decides what you get**, which is where it belongs:

| With a metric | Without |
|---|---|
| `p50`…`p99.9`, `min`, `max`, `avg`, `stddev`, `sum` — reductions of values | `count`, `rate`, `share` — reductions of requests |

**`rate` is per second. `share` is a fraction.** Separate words for separate quantities.

**`of` narrows on the predicate.** A fraction needs a numerator, and it belongs where the
reduction is rather than in a second indicator shape:

```yaml
indicator: {selector: {loadtest.request.name: POST /checkout}}
criteria:
  - {aggregation: share, of: {error.type: "*"}, op: lte, threshold: 5, unit: "%"}
```

`share` requires `of`; `count` accepts it; everything else rejects it — a percentile of a
subset is a percentile of a different indicator, and one predicate hiding two selections is
how that goes unnoticed.

## Why this shape and not the old one

**It matches how the tools are actually built**, which the old shape did not. Gatling exposes
`responseTime.percentile(95)` against `allRequests.count`, `requestsPerSec` and
`failedRequests.percent`; k6 exposes `http_req_duration` with `p(95)` against `http_req_failed`
as a rate. In both, a metric appears exactly where values are read and nowhere else. The old
two-shape model had to invent a metric for the counting case; this one does not.

**It removes a construct rather than adding one.** Net: one shape instead of two, three keys
gone (`total`, `bad`, `good`), one added (`of`), one aggregation added (`share`).

## Consequences

**Breaking.** Every existing document changes: `indicator.distribution.*` moves up a level, and
any `ratio` becomes a `share` predicate. Both published examples were rewritten in the same
change, and the gate caught a stale example inside the schema itself — which is what that check
exists for.

**`good` is gone, and the capability it stood for was never real.** A selector says an
attribute is *present*; it cannot say *absent*. Nothing selects "the request succeeded", so the
successful share had nothing to compute from. It is written as a failed share compared with
`lte`, and the limitation is recorded in `schema/README.md` rather than papered over by a key
that could not work.

**`sum` is now clearly value-only**, where before a `sum` over a ratio was syntactically
sayable and meaningless.

## Rejected alternatives

**Keep both shapes and drop the metric from `ratio` only.** The first fix attempted, and it
solves the duration-in-an-error-requirement problem. It leaves the other two: `ratio` still
duplicates `rate`, and `rate` still means two things. Fixing one of three is how a format
accumulates the other two.

**Introduce a request-count metric** — `loadtest.requests` — so the counting case has something
to name. Forbidden by Principle II as an alias: OpenTelemetry defines no HTTP client request
counter precisely because a histogram's count *is* one, and a second spelling of an existing
quantity is the drift the principle exists to stop.

**Let `rate` keep both meanings and disambiguate by unit.** `{request}/s` against `%`. It works
mechanically and it makes the unit load-bearing for meaning rather than for magnitude — so a
unit typo would not be a wrong number but a different question.

## References

- [`schema/README.md`](../../schema/README.md) — the shape, and how to choose within it
- [`FORMAT.md`](../../FORMAT.md)
- [ADR-0002 § D15](0002-compatibility.md) — units are a closed enum, unaffected
