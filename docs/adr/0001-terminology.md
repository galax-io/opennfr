# ADR-0001. Format name and core terminology

- **Status:** proposed
- **Date:** 2026-08-09
- **Supersedes:** —

> The ADR format is used here for its structure — context, options, cost — not because
> anything is decided. Nothing below has been validated against a schema or an
> implementation. Read each entry as "this is the current leaning and here is the
> reasoning", and the *Rejected* notes as the more durable part: knowing why an option was
> dropped survives the option itself changing.

## Context

We need a format for describing non-functional requirements for load testing that:

1. serves both as an assertion inside a tool and as an after-the-fact check in a backend;
2. is not tied to any single load generator (Gatling, k6, JMeter, Locust, Artillery,
   yandex-tank);
3. parses strictly in any backend in any language;
4. is compatible with OpenTelemetry.

A survey of existing solutions is in [references.md](../references.md). In short: no
format targets this problem. OpenSLO solves the neighbouring one (production SLOs with
error budgets), Keptn provides CI gates with its own metric vocabulary, and
k6/Taurus/picatinny are tool-internal DSLs. The niche is empty.

## Working conclusions

### D1. Call the format OpenNFR

`apiVersion: opennfr.io/v1`, root object `kind: RequirementSet`.

Familiar to performance engineers, and it leaves room to extend the format beyond
performance (resilience, security) through profiles.

**Spelling is `opennfr`, unhyphenated, everywhere:** directory and repository, the
`opennfr.io` domain, the `opennfr.io/` annotation prefix, the Go module and package. Two
spellings of one brand (`open-nfr` in paths, `opennfr` in the format) breed typos and
broken links.

Rejected: `OpenPRS` — narrows the scope to performance permanently; `OpenLoadSLO` —
promises OpenSLO compatibility that would have to be honoured, error budgets included.

### D2. Three layers, three vocabularies

```
Requirement → Criterion → [render]   → Assertion                  (in the tool)
                        → [evaluate] → Verdict → Gate → Outcome   (in the backend)
```

Every concept lives in exactly one layer. The key consequence: **the word `assertion` does
not appear in the OpenNFR schema.** An assertion is a generated artifact of a specific
tool; admitted into the source of truth, it would nail the format to one tool's semantics.

This also dissolves the "assertion or check afterwards?" ambiguity: the same `Criterion`
is either rendered into an assertion (`enforcement: inline`) or computed after the fact
(`post`).

### D3. Metric names come strictly from OTel semconv, plus `loadtest.*`

No custom names and no aliases. Latency is `http.client.request.duration` — a load
generator *is* an HTTP client, so the client-side metric is semantically correct rather
than a compromise. Selection uses OTel attributes (`http.route`, `http.request.method`,
`error.type`).

Whatever OTel lacks and load testing needs gets its own [`loadtest.*`](../semconv/loadtest.md)
namespace in semconv style.

The price: adapters must map tool-specific names (`http_req_duration` in k6, etc.) onto
canonical ones. That is a deliberate payment for reports that correlate with the run's
traces without glue.

Rejected: a domain vocabulary of our own (`response_time`, `error_rate`) — creates a second
source of truth and guarantees divergence from semconv; aliases — the same divergence,
merely deferred.

### D4. Criteria are structure only, with no string DSL

```yaml
- { aggregation: p95, op: lte, threshold: 500, unit: ms }
```

Percentiles are a string enum matching `^p\d{1,2}(\.\d+)?$`, which JSON Schema validates
without a parser. String forms (`"p95 <= 500ms"`, `"<=+10%"`, `avg-rt of Page>150ms`) are
rejected: a bespoke grammar becomes part of the spec, must be reimplemented in every
backend, and instantly becomes a source of compatibility bugs. This is exactly where Keptn
and Taurus get stuck.

### D5. `unit` is mandatory, UCUM

`ms`, `s`, `%`, `1`, `By`, `{request}/s`. This settles "is 0.1 a fraction or a
percentage?", which OpenSLO answers with two separate fields (`target`/`targetPercent`)
and picatinny does not answer at all (bare numbers, unit implied).

> Refined by [ADR-0002 § D15](0002-compatibility.md): the set of units is a *closed
> subset* of UCUM, not UCUM in full. See [units.md](../units.md).

### D6. `guards` and the `inconclusive` outcome

A latency requirement is only meaningful once the target load is reached. A run that
under-delivers load shows green thresholds and produces a false verdict — this is the most
common lie in load testing reports, and none of the surveyed formats catches it.

The decision: a `guards` section, syntactically identical to `criteria`, whose violation
yields `inconclusive` ("the test did not happen") rather than `fail` ("the system does not
hold"). Those are different engineering decisions, so they are different outcomes.

`inconclusive` and `noData` are first-class outcomes, not special cases of `pass`.

### D7. The word `workload` is reserved and currently unused

A throughput requirement is expressed as an ordinary `Requirement` (`aggregation: rate`,
`op: gte`) and needs no special mechanism.

Whether an executable load profile (stages, arrival rate, duration) belongs in the format
is still open. To avoid consuming the name with the wrong meaning, applicability
conditions are called `guards` and `workload` is left free.

### D8. An indicator has two shapes: `distribution` and `ratio`

Modelled on OpenSLO's `thresholdMetric`/`ratioMetric`, minus the worse name:
`thresholdMetric` collides with the threshold value. An error rate is expressed as a
`ratio` with `bad: { selector: { error.type: "*" } }` — without inventing an "errors"
metric, which OTel does not have.

### D9. `EvaluationReport` is the second normative schema

"Parses into any backend" is not satisfied by an input schema alone: a backend also needs
a standard output. Run identity uses existing OTel attributes (`test.suite.name`,
`cicd.pipeline.run.id`, `service.version`, `deployment.environment.name`); we define no
fields of our own for it.

Criteria are referenced by `criterionId` (the `name`, else the `aggregation`), never by
index: indices break whenever the file is edited.

### D10. As few kinds as possible

`RequirementSet`, `Indicator` (reusable), `EvaluationReport`. Everything else is inline.
OpenSLO's `Service` is unnecessary: grouping is expressed with labels carrying OTel names.

> [ADR-0002 § D12](0002-compatibility.md) adds a fourth and final kind, `MetricMapping`.

## Consequences

**Positive**

- Reports correlate with the run's traces and metrics through standard attributes, no glue.
- The format validates entirely with JSON Schema; no backend needs a parser of its own.
- `inconclusive` makes a silently false green impossible on an under-delivered run.
- The layer split allows adding tools without touching the spec.

**Negative / cost**

- Every adapter must maintain a mapping table onto OTel names. That is per-tool work, and
  non-trivial for JMeter.
- The format is more verbose than string DSLs. The `defaults` section compensates.
- Strict UCUM (`{request}/s` rather than `rps`) is unfamiliar to performance engineers.
- `loadtest.*` is our namespace, not a standard. Until OTel adopts it, it is an extension
  rather than a convention.

## Open questions

1. **`baseline.source`** — which modes are needed: `previousPassed`, `previousRun`,
   `movingAverage(N)`, `pinnedRun(id)`. The answer determines whether a separate
   `kind: Baseline` is required or inline suffices.
2. **`window`** — are `phase` + `rolling` enough, or are absolute bounds and offsets from
   the run start also needed?
3. **Executable `workload`** — is a load profile in scope at all (see D7)?
4. ~~Documentation language~~ — resolved: English, as of the first publication.

## References

- [Glossary](../GLOSSARY.md)
- [The `loadtest.*` registry](../semconv/loadtest.md)
- [Reference survey](../references.md)
- [Examples](../examples/)
