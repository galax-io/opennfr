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

There are two, and picking the wrong one is the mistake worth preventing.

| | `distribution` | `ratio` |
|---|---|---|
| Answers | *how long / how big?* | *how many of them?* |
| Names a metric | **yes** — its values are what you compare | **no** — nothing is measured, only counted |
| Typical use | latency, payload size | error share, success share |
| Reduced by | `p95`, `p99`, `max`, `avg`, `min`, `stddev`, `rate`, `count` | `rate`, `count` |

### `distribution` — a quantity with values

You are measuring something and asking about the shape of the numbers.

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

You are counting requests, not measuring them. **It names no metric**, because naming one is
how a document ends up saying `duration` in a requirement about errors.

```yaml
indicator:
  ratio:
    total: {}                    # the population: every request
    bad:                         # narrows it: those that went wrong
      error.type: "*"
criteria:
  - {aggregation: rate, op: lte, threshold: 5, unit: "%"}
```

*At most 5% of all requests failed.*

`bad` is applied **on top of** `total`, not instead of it, so it carries only what makes a
request bad. To ask about one endpoint, narrow the population and leave `bad` alone:

```yaml
ratio:
  total: {loadtest.request.name: POST /checkout}
  bad:   {error.type: "*"}
```

*At most 5% of checkout requests failed.*

### `bad` or `good`, exactly one

Two ways to say the same thing, and which you pick decides the direction of the comparison:

```yaml
ratio: {total: {}, bad:  {error.type: "*"}}    # criteria: rate lte 5   — at most 5% failed
ratio: {total: {}, good: {...}}                # criteria: rate gte 95  — at least 95% succeeded
```

Write whichever your requirement is actually about. `bad` with a `lte` is the common one, and
it is the one every load tool reports directly.

> **A known limitation.** The format has no way to write "the request succeeded". A selector
> can say an attribute is present (`error.type: "*"`) but not that it is absent, so `good`
> currently has nothing to select on and only `bad` is usable in practice. This is recorded
> rather than hidden.

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
