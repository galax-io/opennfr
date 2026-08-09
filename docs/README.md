# OpenNFR documentation

For what OpenNFR is and why, start from the [project README](../README.md). This page is
the index of the design documents.

**Status: design stage.** Terminology and compatibility requirements are settled. There is
no schema, validator or adapter yet — the examples illustrate naming and are not validated.

## Read first

**[GLOSSARY.md](GLOSSARY.md)** — the normative vocabulary. One concept, one word, each with
the rejected synonyms spelled out. Everything else assumes it.

## Decisions

### Terminology — [ADR-0001](adr/0001-terminology.md)

| № | Decision |
|---|---|
| D1 | The format is named **OpenNFR**, `apiVersion: opennfr.io/v1` |
| D2 | Three layers: Requirement → Criterion → Assertion / Verdict. The schema has no `assertion` |
| D3 | Metric names come strictly from OTel semconv plus the `loadtest.*` namespace |
| D4 | Criteria are structure only, with no string DSL |
| D5 | `unit` is mandatory |
| D6 | `guards` and the `inconclusive` outcome |
| D7 | The word `workload` is reserved and currently unused |
| D8 | An indicator is either a `distribution` or a `ratio` |
| D9 | `EvaluationReport` is the second normative schema |
| D10 | As few kinds as possible |

### Compatibility — [ADR-0002](adr/0002-compatibility.md)

| № | Decision |
|---|---|
| D11 | An adapter is a semantic mapper, not a transport — and it is **always** required |
| D12 | `kind: MetricMapping` — mapping is data, not Go code |
| D13 | Conformance levels: `report` / `assert` / `abort` |
| D14 | `loadtest.request.name` is the canonical addressing fallback |
| D15 | Units are a closed enum, not full UCUM |
| D16 | A normative subset of YAML: no anchors, everything maps onto JSON |
| D17 | Strict parsing: an unknown field is an error |
| D18 | The data source is not part of `RequirementSet` |
| D19 | Go-friendliness as a construct-selection criterion |

## References

| | |
|---|---|
| [semconv/loadtest.md](semconv/loadtest.md) | what is taken from OTel verbatim, what `loadtest.*` defines, what is deliberately absent |
| [units.md](units.md) | the closed unit list and canonicalisation rules |
| [compatibility.md](compatibility.md) | conformance levels, the tool matrix, requirements for the Go implementation |
| [references.md](references.md) | the survey of OpenSLO, Keptn, k6, Taurus, picatinny, SLA4OAI |

## Examples

Illustrative of naming; not validated, as there is no schema yet.

| | |
|---|---|
| [checkout-perf.yaml](examples/checkout-perf.yaml) | `RequirementSet` — throughput, latency with guards, error rate, baseline comparison |
| [checkout-perf.report.yaml](examples/checkout-perf.report.yaml) | `EvaluationReport` — the standard output of a check |
| [mapping-k6.yaml](examples/mapping-k6.yaml) | `MetricMapping` — the best case: OTLP output and native thresholds |
| [mapping-jmeter.yaml](examples/mapping-jmeter.yaml) | `MetricMapping` — the worst case: JTL files and no routes |

## Open questions

- [ADR-0001](adr/0001-terminology.md#open-questions): baseline modes, whether `window` is
  sufficient, and the fate of an executable `workload`.
- [ADR-0002](adr/0002-compatibility.md#open-questions): the expressiveness of
  `errorSignal`, histogram resolution, streaming for `enforcement: inline`, and whether
  `dataSourceRef` is needed.

## Next step

A JSON Schema for `RequirementSet` and `EvaluationReport`. It will quickly expose whatever
the vocabulary leaves unsaid and force several of the open questions shut.
