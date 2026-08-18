# The format

The smallest document that says something checkable, and how to grow it.

Everything in [`docs/`](docs/) is an idea about this. This file is the format itself.

## The minimal document

```yaml
apiVersion: opennfr.io/v1
kind: RequirementSet
metadata:
  name: checkout-perf
spec:
  requirements:
    - name: checkout-latency
      indicator:
        distribution:
          metric: http.client.request.duration
          selector:
            http.route: /api/v1/checkout
      criteria:
        - aggregation: p95
          op: lte
          threshold: 500
          unit: ms
```

That is the entire required surface. Read it as: *for requests to this route, the 95th
percentile of client-side duration is at most 500 ms.*

## Required fields — the complete list

| Field | Is | Why it cannot be dropped |
|---|---|---|
| `apiVersion` | `opennfr.io/v1` | A document read by the wrong version must fail loudly, not be guessed at |
| `kind` | `RequirementSet` | One file may hold several objects |
| `metadata.name` | A name | Results have to point back at something |
| `requirements[].name` | A name | The unit a verdict is reported against |
| `indicator.distribution.metric` | A metric name | What is being measured |
| `indicator.distribution.selector` | Attribute → value. `{}` means everything | Which series. Empty is explicit, never implied |
| `criteria[].aggregation` | `p95`, `avg`, `rate`, `count`, … | How the series becomes one number |
| `criteria[].op` | `lte`, `gte`, `lt`, `gt`, `eq`, `neq` | The comparison |
| `criteria[].threshold` | A number | The bar |
| `criteria[].unit` | `ms`, `s`, `%`, `1`, `By`, … | **Mandatory.** Without it, `0.1` is either a tenth of a percent or a tenth of a fraction, and nobody can tell |

Ten fields. Nothing else is required.

## Filling it with metrics

You do not change the format to add a metric. `metric:` takes a **name**, and names come from
outside:

1. **OpenTelemetry semantic conventions first.** `http.client.request.duration`,
   `http.client.request.body.size`, `http.server.request.duration`. A load generator is an HTTP
   client, so the client-side metric is the correct one for a load test.
2. **`loadtest.*` only where semconv has no equivalent** — `loadtest.vus`,
   `loadtest.iterations`, `loadtest.dropped_iterations`, the per-phase HTTP durations. The
   registry is [`docs/semconv/loadtest.md`](docs/semconv/loadtest.md), and it is a **proposal**:
   nothing has submitted it anywhere and no tool emits these names today.

Adding a metric is therefore one of two things: use a semconv name that already exists, or add
a row to the `loadtest.*` registry and use that. Neither touches this file.

**What is not a metric.** Throughput, error rate and apdex are *derived*, not measured.
Throughput is `aggregation: rate` over a duration histogram's count. An error rate is a `ratio`
indicator whose `bad` selector carries `error.type: "*"`. Coining
`loadtest.throughput` would create a second name for something that already exists.

## Optional, and what each one costs

Everything below is off unless written. Each line is a dependency you take on.

| Construct | Buys you | Depends on |
|---|---|---|
| `indicator.ratio` | A fraction — errors over total — instead of a distribution | Nothing |
| `indicatorRef` | Reusing one indicator across requirements | Nothing |
| `guards` | *Inconclusive* instead of a false pass when the run did not happen as intended | Nothing, but the metric you guard on must be measurable by your tool |
| `severity` + `gate` | Which violations fail the run and which only warn | Nothing |
| `window.phase` | Excluding ramp-up and ramp-down | The `loadtest.phase` attribute — **which nothing emits today** |
| `baseline` + `tolerance` | "No worse than last time" instead of an absolute bar | Stored history of previous runs — **which no load generator provides** |
| `enforcement: inline` | Failing during the run instead of after | The tool having native assertions. k6 yes, Gatling partly, JMeter no |
| `onViolation: abort` | Stopping the run on violation | The tool being able to abort. k6 yes, Gatling no, JMeter no |

The last four are the honest ones to know about: a document that uses them is not portable to
every tool, and two of them are not satisfiable by anything today.

**Not in the format at all:** the load profile — stages, arrival rate, duration. The three
priority tools do not agree on what an open or closed model does under degradation, so
borrowing the construct would import that disagreement. The word `workload` is reserved and
unused for exactly this reason.

## Changing the format

```
idea in docs/  →  argued in an issue  →  ADR  →  glossary entry  →  this file  →  schema
```

Rules that hold at every step:

- A term reaches [`docs/GLOSSARY.md`](docs/GLOSSARY.md) with a **rejected alternative** before
  it appears in an example or a schema. The rejection is the durable part; the term may change,
  the reason it is not the other thing does not.
- A metric or attribute name is **borrowed**, never invented, wherever semconv has one.
- An unknown field is a parse error. A typo like `agregation:` must not silently disable a
  criterion and turn a run green.
- Nothing reports success by omission. Missing data is `noData`, a violated guard is
  `inconclusive`, and neither is a pass.

## Where the rest lives

| | |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | how a document becomes a verdict, and what reaches which tool |
| [LAYOUT.md](LAYOUT.md) | where every kind of file lives |
| [`docs/`](docs/) | ideas, arguments and prior art — **notes, not rules** |
| [`docs/examples/`](docs/examples/) | fuller sketches; none is validated, because there is no schema yet |
