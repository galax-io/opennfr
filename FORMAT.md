# The format

A container. It fixes the **shape** a requirement is written in, and nothing else.

The definition is [`schema/opennfr.io/v1/requirementset.schema.json`](schema/opennfr.io/v1/requirementset.schema.json).
One file. This page explains it; the schema decides.

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

[`examples/minimal.yaml`](examples/minimal.yaml) is that document. It is not a sketch:
`scripts/verify.sh` validates it against the schema on every commit, so the format cannot drift
away from it.

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
| Guards | A precondition: the run happened in the intended regime at all. It renders like a criterion, and what tells it apart is its entry in the rendering, not an outcome |
| No outcome vocabulary | The target evaluates and reports. This format defines no verdict, no outcome and no result document |
| Strictness | Unknown fields are rejected everywhere. A typo like `agregation:` is a parse error, not a silently skipped criterion |
| Closed units | `unit` is an enumeration from [`docs/units.md`](docs/units.md), so `mss` is caught here rather than three orders of magnitude later |
| Aggregations that fit the shape | A `ratio` is a fraction, so only `rate` and `count` mean anything over it. A percentile of a fraction is rejected |

That is the whole container. One file, under 6 KB.

## Deliberately not in it — yet

These are real needs. They are **ideas in `docs/`**, not part of the format, because each one
either adds a dependency the format cannot honour or adds a knob before anyone has asked for it.

| Idea | Why it is not here |
|---|---|
| `window` — measure only the steady phase | Rests on a `loadtest.phase` attribute that nothing emits. **Not "yet"** — parked, because no target can assert it |
| `baseline` + `tolerance` — "no worse than last time" | Needs stored history of previous runs, which no load generator keeps. Parked for the same reason |
| `severity` and `gate` — which violations fail the run | They grade violations for a policy that no longer exists. Parked with post-run evaluation |
| `enforcement`, `onViolation` — fail during the run | `enforcement`'s default was "check after the run", which is unreachable now. Parked; `onViolation`'s admission floor is met, so it waits on the field rather than on a tool |
| `defaults` — write shared settings once | Sugar. It buys brevity and costs merge semantics |
| `indicatorRef` — reuse one indicator | Sugar |
| A result document — what an evaluation produced | Nothing produces one yet. Designing the output before anything computes it is guessing, and a guess in a schema is harder to withdraw than a guess in a note |
| `MetricMapping` — binding the format to a tool | **Superseded**, not pending: what a target can and cannot assert is declared in a target description |

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
- Nothing reports success by omission. Every predicate is either rendered into the target's own
  assertions or named, with a reason, as one that target cannot express — before the run starts,
  and with no third bucket.

## Where the rest lives

| | |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | how a document becomes a target's own assertions, and what the target is told it could not be given |
| [LAYOUT.md](LAYOUT.md) | where every kind of file lives |
| [`docs/`](docs/) | notes and arguments — **ideas, not rules** |
