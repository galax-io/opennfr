# The format

A container. It fixes the **shape** a requirement is written in, and nothing else.

The definition is the schema:
[`schema/opennfr.io/v1/requirementset.schema.json`](schema/opennfr.io/v1/requirementset.schema.json).
This file explains it; the schema decides.

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

Validate it:

```bash
bash scripts/verify.sh
```

## What the format does not define

**Metric names.** `metric` is a string. The schema will never enumerate metric names, because
enumerating them would make every new metric a change to the format. Names are borrowed from
OpenTelemetry semantic conventions where one exists; where none exists, the `loadtest.*`
proposal in [`docs/semconv/loadtest.md`](docs/semconv/loadtest.md) is the current thinking, and
it is a note rather than a rule.

**Attribute names.** `selector` is attribute → value. Same reasoning. `{}` means every series;
`"*"` means the attribute is present with any value.

**Derived quantities.** Throughput is `aggregation: rate`. An error rate is a `ratio` whose
`bad` selector carries `error.type: "*"`. Neither is a metric, and neither gets a name.

So: to measure something new, you write a different `metric` string. You do not touch this
file or the schema.

## What the format does define

| | |
|---|---|
| The envelope | `apiVersion`, `kind`, `metadata.name` |
| Two indicator shapes | `distribution` for a distribution of values, `ratio` for a fraction. Exactly one, expressed by nesting rather than a discriminator, so a decoder needs no second pass |
| One predicate shape | `aggregation` + `op` + a bar. Shared by criteria and guards |
| Two kinds of bar | An absolute `threshold`, which requires a `unit`; or `baseline` + `tolerance`, where `tolerance.unit` carries it. Never both |
| Closed value sets | `op`, `severity`, `enforcement`, `onViolation`, `window.phase`, `gate` outcomes. `aggregation` is an enum plus a percentile pattern — the one place with a pattern rather than a list |
| Strictness | `additionalProperties: false` everywhere. A typo like `agregation:` is a parse error, not a silently skipped criterion |

Everything beyond the envelope, one indicator and one criterion is optional. The optional parts
that carry a real dependency are listed in [ARCHITECTURE.md](ARCHITECTURE.md) with what each
one costs — two of them are satisfiable by no tool today.

## Not in the container at all

The load profile — stages, arrival rate, duration. The three priority tools do not agree on
what an open or closed model does under degradation, so borrowing the construct would import
that disagreement. The word `workload` is reserved and unused for exactly this reason.

## How an idea becomes part of the format

```
note in docs/  →  argued in an issue  →  ADR  →  glossary entry  →  schema  →  the note is deleted
```

**The last step is not optional.** When a note is accepted into the format, parked into the
experimental area, or rejected outright, **the note in `docs/` is deleted in the same pull
request** that accepts, parks or rejects it.

`docs/` holds live ideas only. A note that has already become a rule is a second source for one
decision, and two sources drift — which is the failure this whole format exists to prevent,
applied to its own repository.

Rules that hold at every step:

- A term reaches [`docs/GLOSSARY.md`](docs/GLOSSARY.md) with a **rejected alternative** before
  it appears in an example or the schema. The rejection outlives the term it protects.
- A metric or attribute name is **borrowed**, never invented, wherever semconv has one.
- Nothing reports success by omission. Missing data is `noData`, a violated guard is
  `inconclusive`, and neither is a pass.

## Where the rest lives

| | |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | how a document becomes a verdict, and what reaches which tool |
| [LAYOUT.md](LAYOUT.md) | where every kind of file lives |
| [`docs/`](docs/) | notes and arguments — **ideas, not rules** |
