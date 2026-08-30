# Ideas

Nothing here is documentation. Every entry is a construct the format does not have — something
to be built, reworked or dropped. What the format *is* lives at the repository root, and this file
is deliberately not linked from there.

Each entry says what it would buy and what has to become true before it could enter the schema. The
route out is in `CONTRIBUTING.md`: an issue that argues it, a glossary entry recording what was
rejected, the schema, and then the entry here is **deleted**. A note that has become a rule is a
second source for one decision.

The floor for admission, from the constitution: *a construct MUST NOT enter the format unless at
least one surveyed target can assert it exactly.* That is necessary and not sufficient — a
construct must also not enter solely to reach one target's feature.

```bash
git rm -r docs && bash scripts/verify.sh    # stays green, by rule and by gate
```

---

## Fields argued for and left out

**`indicator`** — *retired, not pending.* An object on the requirement holding both what to measure
and which requests, in two shapes borrowed from OpenSLO's `thresholdMetric` and `ratioMetric`. Its
substance survives, split between the requirement's `selector` and the predicate's `metric` /
`bad`. What killed it: holding the selection inside the shape forced a requirement about one
endpoint being fast *and* reliable to become two requirements with the same selector written twice.
A `ratio` also had to name a metric it did not measure — an error-rate requirement read
`metric: http.client.request.duration`, because a histogram's count is the request count and
OpenTelemetry defines no HTTP client request counter.

*Would need*: an OpenTelemetry request counter, so a fraction stops having to name a metric it does not measure — and a reason to reverse ADR-0003's split, which none has appeared.

**`window`** — measure only the steady phase, excluding ramp-up and ramp-down. Blocked on a
`loadtest.phase` attribute that nothing emits. A construct whose only meaning comes from an
attribute no target produces is a field that always matches everything, which is a silent green
with a schema around it. *Would need*: a target that labels its own phases.

**`baseline` + `tolerance`** — "no worse than last time", mutually exclusive with `threshold`, with
the direction following from `op` so that strings like Keptn's `"<=+10%"` are unnecessary. The
design is sound; the dependency is not. It needs stored history of previous runs, which no load
generator provides. *Would need*: a store, described somewhere, chosen by somebody.

**`severity` + `gate`** — `blocker | warning | info` on a criterion, and a policy turning many
results into one. Today any failed criterion fails the run, which is enough. `gate` was written when
this project expected to compute the outcome itself, which it no longer does. A worked example of
its cost: an early draft's `onNoData: fail` meant a run in which nothing failed produced no series
carrying `error.type`, hence no data, hence a failed run — the system was perfect and the gate said
no.

*Would need*: somebody to hit the wall: a real run where one failed criterion should not have failed the build, argued in an issue. Until then the knob is a policy language inside a format whose argument is that it has none.

**`enforcement` + `onViolation`** — where a criterion is checked, and whether to abort. Both
describe what a target can do, not what a requirement says. A requirement carrying them names a
target by implication, which the constitution forbids. Where a target can abort, that is a fact
about the target.

*Would need*: a target's description to exist, so the capability can be declared where it belongs. Neither field can return to the requirement itself, whatever else changes.

**`defaults` and `indicatorRef`** — sugar. `defaults` buys brevity and costs merge semantics: what
happens when a requirement overrides one key of an inherited map, and does a reader know without
checking. The duplication it was meant to remove is largely gone anyway, since the selector is now
written once per requirement.

*Would need*: a document where the duplication actually hurts after ADR-0003, plus merge semantics stated so precisely that two consumers cannot implement them differently. The second is the hard half.

**The load profile** — stages, arrival rate, duration. *Not a "yet".* The tools do not agree on what
an open or a closed workload model does under degradation, so borrowing the construct would import
that disagreement into a format whose only asset is that one document means one thing. The word
`workload` is reserved and unused so it is not consumed by the wrong meaning first.

*Would need*: the surveyed tools to agree on what an open or a closed model does under degradation. That is not something this format can bring about, which is why this is not a "yet".

**apdex** — one number for how many users were served well: each request is classified against a
threshold `T` as satisfied (`rt <= T`), tolerating (`T < rt <= 4T`) or frustrated, and the score is
`(satisfied + tolerating / 2) / total`. It is the one figure in this area a stakeholder reads
without training, and `APDEX` is a literal key in the NFR-YAML documents this format is meant to
replace, so it gets asked for. Two constructs are missing and neither is small. A predicate carries
one threshold, and a fraction — `bad` or `good` — splits a selection in two by attribute presence,
so nothing here produces three bands or takes a second threshold. And no aggregation the format has
— `p*`, `max`, `min`, `avg`, `stddev`, `count`, `rate` — takes a weighted sum of counts.

This is why apdex sits here and not beside throughput and an error rate. Those two are **derived**:
each reduces to one construct the format already has, `aggregation: rate` and a `bad` fraction.
Apdex is **composite** and reduces to none.

*Would need*: a banded classification carrying a second threshold, and an aggregation that weights the bands — each argued on its own merits rather than as a step toward apdex, because a scoring policy that arrives one field at a time is still a scoring policy inside a format whose argument is that it has none.

## A result document

**A result document.** `Verdict` — the result of checking one predicate: `pass | warn | fail | noData | skipped`. `Outcome`
— the aggregate: `pass | warn | fail | inconclusive`. `EvaluationReport` — the schema that would
carry them, using **existing** OpenTelemetry attributes for run identity (`test.suite.name`,
`cicd.pipeline.run.id`, `service.name`, `deployment.environment.name`) rather than fields of its
own, which is what would let a report correlate with the traces of the same run without glue.

Nothing produces one. The first design had this project evaluating — reading normalised series,
computing each statistic itself — and that is what made a result document necessary. Constitution
2.0.0 reversed it: the target computes its own statistic, asserts against it, and reports. The cost
is stated rather than hidden — two targets asserting the same criterion need not produce the same
number, and no rule can make them.

`inconclusive` is struck specifically: no surveyed target has a third outcome, so nothing could
produce one. The distinction it protected survives as a `guard`.

*Would need*: something that computes or collects a result; a vocabulary that is a target's or is
declared per target; and whatever it says about missing data being producible by a real target.

## Reaching a tool

**Assertion** — the projection of a criterion into one target's own form. The word stays out of the
document: an assertion is a generated artifact, not a source of truth, and the moment it enters the
format the format is nailed to one tool's semantics. The strongest constraint these notes have
produced, and the one that has survived every change of direction.

*Would need*: nothing. This one is settled, and it is recorded here so the next person does not reopen it.

**Adapter** — renames metrics to canonical names, converts units, renames the tool's labelling into
attributes, and renders criteria into native assertions. Always required, including for tools with
built-in OTLP output, because OTLP is a transport and not a vocabulary. Units are where an adapter
is most dangerous: tools report milliseconds where the conventions require seconds, and an error
there is three orders of magnitude wide.

*Would need*: something to render or ingest at all. No adapter can be written before there is a renderer for it to be part of.

**MetricMapping** — the declarative table binding one tool's names to canonical ones. Support as
data, not code: the alternative caps the tool list at maintainer bandwidth. The open problem is the
failure signal — k6 signals a failed request with a separate metric, JMeter with a boolean column,
Gatling with KO, and expressing that declaratively without reinventing a rules DSL inside a format
whose argument is that it has no DSL is unsolved.

*Would need*: the failure signal solved — a declarative way to say "an error happened" across tools that each signal it differently, without a rules DSL. That is the open problem, not a detail of the file format.

**The conformance ladder** — `report` / `assert` / `abort`, cumulative levels describing how deeply
a tool is integrated, where `report` was a complete mode rather than a degraded one. Retired by
constitution 2.0.0: the rungs were steps on a path ending in post-run evaluation, and with
evaluation out of scope the bottom rung guarantees nothing anything can consume. What replaces it
is not an ordinal — what a target can assert, what it cannot, how it names things and how its units
convert are declared per capability, each claim dated and sourced.

*Would need*: post-run evaluation to return to scope, which would make a bottom rung mean something again. Nothing else revives an ordinal.

**A reference implementation.** Anticipated in Go and never started. What survives is the technique
rather than the design: pointers for mutually exclusive variants so no custom unmarshaler is
needed, `KnownFields(true)` so an unknown field is an error, `float64` throughout with no decimal
strings, and a conversion table rather than a UCUM parser.

*Would need*: a specification that names the role it fills, per the process this repository already follows. The technique above is not a design and does not substitute for one.

## The `loadtest.*` registry

A proposed OpenTelemetry extension for what semconv does not cover, written in semconv style. **It
has been submitted nowhere and nothing emits these names.**

Metrics: `loadtest.vus`, `loadtest.iterations`, `loadtest.iteration.duration`, and
`loadtest.dropped_iterations` — iterations not started because the generator ran out of resources,
which is the textbook guard: if the generator could not keep up, no conclusion about the system may
be drawn. Plus five HTTP phase histograms — connect, TLS, send, wait (TTFB), receive — because the
conventions provide only the total and breaking it down is a standard diagnosis.

Attributes: `loadtest.phase`, `loadtest.scenario.name`, `loadtest.tool.name` / `.version`,
`loadtest.injector.id`.

Deliberately absent from it: `loadtest.throughput` (derived — `aggregation: rate`),
`loadtest.error_rate` (derived — a `bad` fraction), `loadtest.response_time` (a duplicate of
`http.client.request.duration`), `loadtest.apdex` (composite), `loadtest.run.id`
(`cicd.pipeline.run.id` already exists). And, since v0.6.0, a name for **a span an author
bracketed** — a business transaction across several requests, which no semantic convention names.
It is the one duration a load test measures that the format cannot spell, and it is absent for the
reason the rest of this registry is: a name nothing emits is a vocabulary of one.

**The rest of the registry** stays an idea. two names from this registry — `loadtest.request.name` and `loadtest.group.name` — are **not** ideas
any more. Every published example depends on them, and `README.md` defines them and records the debt.

*Would need*: submission upstream, and something that emits the names. A namespace nobody has
claimed and nothing publishes is a vocabulary of one, which is what the debt in `README.md` says.

## The monitoring direction

**One document, four backends.** The claim: one requirement document, unchanged, turned into both a query returning the canonical
measurement and a native monitoring definition, for Datadog, Prometheus, VictoriaMetrics and
InfluxDB. **Nothing verifies any part of it**, and it is stated so it can be argued with rather than
because it is believed.

Three unknowns keep it here. Four percentile machineries — Prometheus and VictoriaMetrics
interpolate from fixed buckets, Datadog uses a sketch, InfluxDB depends on how the data was written
— so one criterion can pass on one and fail on another with identical traffic. A change of vantage
point, client to server, which is the failure the format exists to prevent. And constructs that do
not cross: a guard about the load generator has no meaning against production traffic.

*Would need*: one unchanged document assembling a valid query for **all four**, each check dated and
sourced; the query vocabulary declared as structure rather than embedded query strings; every
construct that cannot cross listed by name; and at most one new document kind.
