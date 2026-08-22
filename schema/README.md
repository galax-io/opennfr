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

## The shape

A requirement says **which requests** once, and then everything that must be true of them.

```yaml
- name: checkout
  displayName: Checkout is fast and reliable
  selector:                                    # which requests — written once
    http.route: /api/v1/checkout
  guards: [...]                                # optional: was the run valid at all
  criteria:                                    # what must hold
    - {metric: http.client.request.duration, aggregation: p99, op: lte, threshold: 500, unit: ms}
    - {bad: {error.type: "*"},               aggregation: rate, op: lte, threshold: 5,   unit: "%"}
```

One selector, two statements about the same endpoint: it is fast, and it does not fail. That is
one requirement because it is one human sentence.

## What a criterion can be about

Every criterion is `aggregation` + `op` + `threshold` + `unit`. What it reduces depends on which
optional key it carries — and it carries at most one.

| Carries | It is about | Aggregations that mean anything |
|---|---|---|
| `metric` | a quantity the selected requests carry | `p50`…`p99.9`, `avg`, `min`, `max`, `stddev`, `sum`, `count`, `rate` |
| `bad` or `good` | a fraction of the selected requests | `rate` (the share), `count` (how many) |
| neither | the selected requests themselves | `count` (how many), `rate` (per second) |

**`metric`** names what to measure — an OpenTelemetry name, borrowed. The criterion reduces its
values.

**`bad`** narrows the requirement's selection to the ones that went wrong; the denominator is
the requirement's selection, so it is never written twice. An error rate is
`bad: {error.type: "*"}` — no invented errors metric, which OpenTelemetry does not have either.
`good` is the same for the other side, and at most one of them appears.

**Neither** counts the requests: `count` is how many, `rate` is how many per second.

The schema enforces the combinations. A percentile without a metric is rejected — there are no
values to take a percentile of. A percentile with `bad` is rejected — a percentile of a fraction
is not a number anyone wants. `metric` with `bad` is rejected: one measures, the other counts.

## Both together, on one run

Say the run made **1000 requests** to `/api/v1/checkout`, **30** carrying `error.type`, with a
99th-percentile duration of 480 ms and a slowest of 1200 ms:

```yaml
- name: checkout
  selector: {http.route: /api/v1/checkout}
  criteria:
    - {metric: http.client.request.duration, aggregation: p99,   op: lte, threshold: 500,  unit: ms}
    - {metric: http.client.request.duration, aggregation: max,   op: lte, threshold: 1000, unit: ms}
    - {bad: {error.type: "*"},               aggregation: rate,  op: lte, threshold: 5,    unit: "%"}
    - {bad: {error.type: "*"},               aggregation: count, op: lte, threshold: 20,   unit: "{request}"}
```

| Criterion | What the aggregation reduces | Actual | Must be | |
|---|---|---|---|---|
| `p99` of the metric | the **durations** of the 1000 requests | 480 ms | ≤ 500 ms | pass |
| `max` of the metric | the same durations | 1200 ms | ≤ 1000 ms | **fail** |
| `rate` with `bad` | 30 **÷** 1000 | 3% | ≤ 5% | pass |
| `count` with `bad` | how many matched `bad` | 30 | ≤ 20 | **fail** |

The same four keys in every row. In the top two they reduce the values a metric carries; in the
bottom two they reduce counts of requests, and no metric is involved.

> **A known limitation.** A selector says an attribute is *present* (`error.type: "*"`), not
> that it is absent, so `bad` has something to select and `good` does not. Write the failed
> fraction and compare with `lte`. Recorded rather than hidden.

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
