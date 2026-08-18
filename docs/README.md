# Notes

> **These are notes, not rules.** Ideas about the format, kept for the arguments in them.
> The format itself is [FORMAT.md](../FORMAT.md); how it works is [ARCHITECTURE.md](../ARCHITECTURE.md).

Working notes towards a format for load testing requirements. See the
[project README](../README.md) for what this repository is and is not.

> These are notes, not normative text. Nothing here is settled, and field names drift
> between documents as the thinking changes. Where a document sounds decisive, read it as
> "this is the current leaning and here is why", not as a rule.

## Where to start

**[GLOSSARY.md](GLOSSARY.md)** — candidate terms with the alternatives that were
considered and dropped. The rest of the notes assume its vocabulary, so it is the cheapest
way in.

This directory holds **notes and ideas only**. The project itself lives at the repository
root: [FORMAT.md](../FORMAT.md), [ARCHITECTURE.md](../ARCHITECTURE.md), [LAYOUT.md](../LAYOUT.md).

**A note here is deleted once it stops being a note.** When an idea is accepted into the
format, parked, or rejected, its note goes in the same pull request — see
[LAYOUT.md](../LAYOUT.md). What survives is the ADR, the glossary's *Rejected* line, or the
schema; never a second copy of a decision.

## What is actually verified

Two documents contain checked facts rather than opinion, and they are the parts worth
trusting:

| | |
|---|---|
| [references.md](references.md) | the survey of OpenSLO, Keptn, k6, Taurus, picatinny, SLA4OAI and adjacent SLO tooling — what each does and where it hurts |
| [compatibility.md](compatibility.md) | what load testing tools actually emit as of August 2026, checked against their documentation. The useful finding is negative: OTLP output is common, semconv names are not |

## Thinking, in ADR form

The ADR format is used for its structure — context, options, cost — not because anything is
decided. Both are **status: proposed**.

### [ADR-0001](adr/0001-terminology.md) — naming

| № | Leaning |
|---|---|
| D1 | Call it OpenNFR; `apiVersion: opennfr.io/v1` |
| D2 | Three layers: Requirement → Criterion → Assertion / Verdict, with no `assertion` in the document itself |
| D3 | Take metric names from OTel semconv rather than inventing them |
| D4 | Structured criteria, no string DSL |
| D5 | Make `unit` mandatory |
| D6 | Preconditions (`guards`) yielding a third outcome, `inconclusive` |
| D7 | Leave the word `workload` unused for now |
| D8 | An indicator is either a `distribution` or a `ratio` |
| D9 | Define the result document too, not only the input |
| D10 | Keep the number of document kinds small |

### [ADR-0002](adr/0002-compatibility.md) — implementation and tools

| № | Leaning |
|---|---|
| D11 | An adapter is a semantic mapper, not a transport — and it seems to be needed always |
| D12 | Express tool mapping as data rather than code |
| D13 | Conformance levels instead of a support checkbox |
| D14 | Accept a fallback for addressing requests, since `http.route` is rarely emitted |
| D15 | A closed list of units rather than full UCUM |
| D16 | A subset of YAML that maps onto JSON |
| D17 | Strict parsing — an unknown field should be an error |
| D18 | Keep the data source out of the requirement document |
| D19 | Prefer constructs that decode without custom code |

## Sketches

| | |
|---|---|
| [semconv/loadtest.md](semconv/loadtest.md) | what could be taken from OTel verbatim and what a `loadtest.*` namespace might add |
| [units.md](units.md) | which units to allow and how to canonicalise them |
| [examples/checkout-perf.yaml](examples/checkout-perf.yaml) | what a requirement document might look like |
| [examples/checkout-perf.report.yaml](examples/checkout-perf.report.yaml) | what a result document might look like |
| [examples/mapping-k6.yaml](examples/mapping-k6.yaml) | tool mapping, best case — k6 has OTLP output and native thresholds |
| [examples/mapping-jmeter.yaml](examples/mapping-jmeter.yaml) | tool mapping, worst case — JTL files and no routes |

None of these sketches is validated: they use constructs the format does not have, which is why they live here. The validated corpus is `examples/` at the repository root, checked against the schema on every commit.

## Unresolved

Collected in the ADRs, and some of these may yet sink the approach:

- Declaring "an error occurred" across tools that all signal it differently
  ([ADR-0002](adr/0002-compatibility.md#open-questions)).
- Histogram resolution, since percentiles come from buckets.
- Baseline modes, time windows, streaming evaluation — sketched, not thought through
  ([ADR-0001](adr/0001-terminology.md#open-questions)).
- Whether load profiles belong in this format at all.

## Next

A JSON Schema for the requirement and result documents. Less because a schema is needed and
more because writing one is the fastest way to find out which parts of the vocabulary are
hand-waving.
