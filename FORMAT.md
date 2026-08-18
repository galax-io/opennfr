# The format

A container. It fixes the **shape** a requirement is written in, and nothing else.

The definition is the schema. This file explains it; the schema decides.

| Kind | Schema | What it holds |
|---|---|---|
| `RequirementSet` | [`requirementset.schema.json`](schema/opennfr.io/v1/requirementset.schema.json) | What must hold. The input |
| `EvaluationReport` | [`evaluationreport.schema.json`](schema/opennfr.io/v1/evaluationreport.schema.json) | What happened. The output |
| — | [`common.schema.json`](schema/opennfr.io/v1/common.schema.json) | Definitions both share. One home each, so they cannot drift |
| `MetricMapping` | not yet | Binds the format to one tool |

The output is not an afterthought. Without a standard report, "any backend can consume this" is
half a promise: a backend needs a standard output as much as a standard input.

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

A guard, a ratio and a report are in [`examples/`](examples/). Those files are not sketches —
`scripts/verify.sh` validates them against the schema on every commit, so if the format changes
under them, the build goes red.

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
| One predicate shape | `aggregation` + `op` + `threshold` + `unit`. Criteria and guards are the same shape; only the meaning of a violation differs |
| Guards | A violated guard means the run did not happen as intended, so the outcome is `inconclusive` — not `fail`, and never a pass |
| Three outcomes | `pass`, `fail`, `inconclusive`. Three verdict statuses: `pass`, `fail`, `noData` |
| Strictness | `additionalProperties: false` everywhere. A typo like `agregation:` is a parse error, not a silently skipped criterion |
| Results that cannot lie | A verdict with status `pass` or `fail` must carry what it observed. A verdict with `noData` must carry a **reason**. Silence is not a permitted answer |

That is the whole container. Three files, under 12 KB of schema.

## Deliberately not in it — yet

These are real needs. They are **ideas in `docs/`**, not part of the format, because each one
either adds a dependency the format cannot honour or adds a knob before anyone has asked for it.

| Idea | Why it is not here |
|---|---|
| `window` — measure only the steady phase | Rests on a `loadtest.phase` attribute that nothing emits |
| `baseline` + `tolerance` — "no worse than last time" | Needs stored history of previous runs, which no load generator provides |
| `severity` and `gate` — which violations fail the run | A knob. Today any failed criterion fails the run, and that is enough until someone needs otherwise |
| `enforcement`, `onViolation` — fail during the run | Tool capability, not format. k6 can, JMeter cannot, and the format must not exclude JMeter |
| `defaults` — write shared settings once | Sugar. It buys brevity and costs merge semantics |
| `indicatorRef` — reuse one indicator | Sugar |

Each is argued in [`docs/GLOSSARY.md`](docs/GLOSSARY.md). When one is accepted, it lands in the
schema **and its note in `docs/` is deleted** — see below.

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
