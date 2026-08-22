# The schema, and how to choose within it

One file: [`opennfr.io/v1/requirementset.schema.json`](opennfr.io/v1/requirementset.schema.json).
It fixes the shape a requirement is written in. It decides; this page explains.

A document is a list of **requirements**. Each one says *what is measured* (an indicator) and
*what must be true of it* (criteria, and optionally guards).

```yaml
apiVersion: opennfr.io/v1
kind: RequirementSet
metadata:
  name: checkout-perf
spec:
  requirements:
    - name: ...
      indicator: ...        # what is measured
      guards: [...]         # optional — was the run valid at all
      criteria: [...]       # what must hold
```

---

## The one real choice: which indicator shape

Two shapes, exactly one per requirement. They come from OpenSLO's `thresholdMetric` and
`ratioMetric`; the names differ because `thresholdMetric` would collide with the threshold
value, and that rename is recorded in [ADR-0001 § D8](../docs/adr/0001-terminology.md).

| | `distribution` | `ratio` |
|---|---|---|
| Answers | *how long / how big?* | *how many of them?* |
| Names a metric | **yes** — its values are what you compare | **no** — nothing is measured, only counted |
| Typical use | latency, payload size | error rate |
| Reduced by | `p95`, `p99`, `max`, `min`, `avg`, `stddev`, `sum`, `count`, `rate` | `rate` (the fraction), `count` |

### `distribution` — a quantity with values

```yaml
indicator:
  distribution:
    metric: http.client.request.duration   # an OpenTelemetry name, not ours
    selector:
      loadtest.request.name: GET /
criteria:
  - {aggregation: p99, op: lte, threshold: 500, unit: ms}
```

*The 99th percentile of how long `GET /` took is at most 500 ms.*

### `ratio` — a fraction of requests

Both sides are **selectors, not metrics**. Nothing here is measured; requests are counted.
`total` is the denominator, `bad` or `good` the numerator.

```yaml
indicator:
  ratio:
    total: {}                    # every request
    bad:
      error.type: "*"            # those carrying an error
criteria:
  - {aggregation: rate,  op: lte, threshold: 5,   unit: "%"}          # the share
  - {aggregation: count, op: lte, threshold: 100, unit: "{request}"}  # the number
```

*At most 5% of requests failed, and at most 100 of them.*

For errors you want one of exactly those two — a percentage or a count. Both read off the same
indicator; the aggregation picks which.

`bad` narrows `total`, so asking about one endpoint is a change to `total` alone:

```yaml
ratio:
  total: {loadtest.request.name: POST /checkout}
  bad:   {error.type: "*"}
```

### `rate` means two things, and that is borrowed

Over a `distribution` it is **per second**; over a `ratio` it is **the fraction**. The shape
tells them apart. k6 carries the same overload and resolves it the same way — `rate` on a
Counter is per second, on a Rate metric it is a proportion — so this is inherited rather than
invented, and a second word to avoid it would cost more than it saves.

> **A known limitation.** A selector can say an attribute is present (`error.type: "*"`) but not
> that it is absent, so `bad` has something to select and `good` does not. Write the failed
> fraction and compare with `lte`. Recorded rather than hidden.

---

## Both together, on one run

The confusing part is that a criterion looks identical in both cases — `aggregation`, `op`,
`threshold`, `unit` — while what the aggregation *reduces* is completely different. Here is one
endpoint with both kinds of requirement.

```yaml
spec:
  requirements:

    - name: checkout-duration
      indicator:
        distribution:                                        # what to measure: duration
          metric: http.client.request.duration
          selector: {loadtest.request.name: POST /checkout}  # of which requests
      criteria:
        - {aggregation: p99, op: lte, threshold: 500,  unit: ms}
        - {aggregation: max, op: lte, threshold: 1000, unit: ms}

    - name: checkout-errors
      indicator:
        ratio:                                               # measure nothing, count requests
          total: {loadtest.request.name: POST /checkout}     # the denominator
          bad:   {error.type: "*"}                           # the numerator
      criteria:
        - {aggregation: rate,  op: lte, threshold: 5,  unit: "%"}
        - {aggregation: count, op: lte, threshold: 20, unit: "{request}"}
```

Say the run made **1000 requests** to `POST /checkout`, **30** of them carrying `error.type`,
with a 99th-percentile duration of 480 ms and a slowest of 1200 ms:

| Requirement | What the aggregation reduces | Actual | Must be | |
|---|---|---|---|---|
| `checkout-duration` | `p99` of the **durations** | 480 ms | ≤ 500 ms | pass |
| `checkout-duration` | `max` of the **durations** | 1200 ms | ≤ 1000 ms | **fail** |
| `checkout-errors` | `rate` = **bad ÷ total** | 3% | ≤ 5% | pass |
| `checkout-errors` | `count` = **how many bad** | 30 | ≤ 20 | **fail** |

The same four keys in every row. In the top two they reduce the *values* the metric carries; in
the bottom two they reduce *counts of requests*, and no metric is involved at all.

### Why that is two requirements and not one

A requirement is about **one measured thing**. Latency and failure are two, so they are two
requirements — the same split OpenSLO makes, where one SLI feeds one objective.

The cost is visible above: `{loadtest.request.name: POST /checkout}` is written twice. That is
real, and it is the price of a requirement meaning exactly one thing. A shared-defaults
construct would remove the repetition and is deliberately not in the format — see FORMAT.md's
list of what is left out and why.

### The aggregations that mean anything, per shape

| | `distribution` | `ratio` |
|---|---|---|
| `p50`…`p99.9`, `avg`, `min`, `max`, `stddev`, `sum` | values of the metric | **rejected** — a percentile of a fraction is not a number anyone wants |
| `count` | how many observations | how many `bad` (or `good`) |
| `rate` | per second | the fraction itself |

---

## `selector` — which requests

A map of attribute to value. Every key must match.

```yaml
selector: {}                                   # every request
selector: {loadtest.request.name: GET /}       # one named request
selector:                                      # one request inside a group
  loadtest.group.name: MyGroup
  loadtest.request.name: MyRequest
selector: {error.type: "*"}                    # the attribute is present, any value
```

Attribute names are borrowed from OpenTelemetry where an equivalent exists. `http.route` is the
portable way to address an endpoint; almost no load generator emits it, so `loadtest.request.name`
is the honest fallback — at the cost that such a document does not travel between tools unchanged.

---

## `criteria` and `guards` — the same shape, different meaning

Both are *predicates*: `aggregation` + `op` + `threshold` + `unit`.

```yaml
criteria:
  - {aggregation: p95, op: lte, threshold: 500, unit: ms}
guards:
  - {name: reached-target-rate, aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"}
```

A violated **criterion** says *the system did not hold*. A violated **guard** says *the run did
not happen as intended* — the generator never reached the load the requirement assumes, so a
green criterion beside it is not evidence of anything. That distinction is the reason guards
exist: a test at 5 rps shows an excellent p95 and tells you nothing.

### When a predicate needs a `name`

Only when two predicates of one requirement would otherwise be indistinguishable. Identity is
the `name` if set, otherwise the `aggregation`:

```yaml
guards:   [{aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"}]
criteria: [{aggregation: rate, op: lte, threshold: 400, unit: "{request}/s"}]
# both identities are "rate" — one of them must be named
```

With different aggregations (`p99` and `max`), no name is needed and adding one is noise.

---

## `displayName` — optional, for people

Free text in any script, up to 200 characters, on the document, on a requirement and on a
predicate. It changes nothing: two documents differing only in display names mean the same thing.

Keep it to the quantity, never the answer:

```yaml
- {displayName: 99th percentile, aggregation: p99, op: lte, threshold: 500, unit: ms}   # yes
- {displayName: 99th percentile under 500 ms, ...}                                      # no
```

The second is a copy of `threshold`, and the copy stops being true the first time the threshold
moves.

---

## What the schema will not do

- **It does not enumerate metric names.** Measuring something new must never require changing
  the format, so `metric` is any string and the vocabulary comes from OpenTelemetry.
- **It does not name derived quantities.** There is no `error_rate` metric and no `throughput`
  metric — both are `aggregation` over something that already exists. A second vocabulary is a
  second source of truth.
- **It rejects unknown fields, everywhere.** A misspelled `agregation` would otherwise disable a
  criterion silently and turn a run green.
- **It requires a unit on every threshold.** `500` alone is three orders of magnitude away from
  being unambiguous.
