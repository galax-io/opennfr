# Notes, evidence and ideas

> The format itself is [README.md](../README.md) and [the schema reference](../schema/README.md); how it works is [ARCHITECTURE.md](../ARCHITECTURE.md).

Nothing in this directory is a rule. Where a page here disagrees with
[`schema/opennfr.io/v1/requirementset.schema.json`](../schema/opennfr.io/v1/requirementset.schema.json),
the schema is right.

Three different kinds of thing live here, and they deserve different amounts of trust. The
column that matters is the last one.

## Reference — the vocabulary the format carries

| | | Trust |
|---|---|---|
| [GLOSSARY.md](GLOSSARY.md) | every term the schema carries, each with a rejected alternative | Enforced. `scripts/verify.sh` rejects a document that breaks one |
| [units.md](units.md) | the closed unit list and how the units convert | The list is the schema's `unit` enum. The conversions are a design, and nothing implements them |

## Evidence — checked facts, with dates

These are the most trustworthy pages in the repository, and they stay useful whatever happens
to the format.

| | | Trust |
|---|---|---|
| [references.md](references.md) | the survey: OpenSLO, Keptn quality gates, k6 thresholds, Taurus PassFail, SLA4OAI, gatling-picatinny and adjacent SLO tooling — what each got right and where each hurts | Checked against each project's own documentation |
| [compatibility.md](compatibility.md) | what load testing tools actually emit, as of August 2026 | Checked against each tool's documentation, and dated. The useful finding is negative: OTLP output is common, semantic convention names are not |

## Ideas — constructs the format does not have

| | |
|---|---|
| [ideas/](ideas/) | the argument for each, and what would have to become true first |
| [semconv/loadtest.md](semconv/loadtest.md) | what a `loadtest.*` extension to OpenTelemetry might contain. Submitted nowhere; nothing emits these names |
| [examples/](examples/) | sketches, deliberately outside the gate — they illustrate constructs the format does not have. The validated corpus is [`examples/`](../examples/) at the repository root |
| [experimental/](experimental/) | the parked monitoring direction, with its own promotion and retirement conditions |

**A note is deleted once it stops being a note.** When an idea is accepted into the format,
parked, or rejected, its note goes in the same pull request that accepts, parks or rejects it —
see [LAYOUT.md](../LAYOUT.md#how-an-idea-becomes-part-of-the-format). What survives is the ADR,
the glossary entry's *Rejected* line, or the schema; never a second copy of a decision.

## Why any of it is the way it is

The ADR format is used for its structure — context, options, cost. All three are
**status: proposed**.

### [ADR-0001](adr/0001-terminology.md) — naming

| № | Decision |
|---|---|
| D1 | Call it OpenNFR; `apiVersion: opennfr.io/v1` |
| D2 | Three layers: Requirement → Criterion → Assertion, with no `assertion` in the document itself |
| D3 | Take metric names from OpenTelemetry rather than inventing them |
| D4 | Structured criteria, no string DSL |
| D5 | Make `unit` mandatory |
| D6 | Preconditions — `guards` |
| D7 | Leave the word `workload` unused for now |
| D8 | An indicator is either a `distribution` or a `ratio` — *amended by ADR-0003* |
| D9 | Define the result document too, not only the input — *out of scope since constitution 2.0.0* |
| D10 | Keep the number of document kinds small |

### [ADR-0002](adr/0002-compatibility.md) — implementation and tools

| № | Decision |
|---|---|
| D11 | An adapter is a semantic mapper, not a transport — and it is needed always |
| D12 | Express tool support as data rather than code |
| D13 | Conformance levels instead of a support checkbox — *retired by constitution 2.0.0; an ADR is owed* |
| D14 | Accept a fallback for addressing requests, since `http.route` is rarely emitted |
| D15 | A closed list of units rather than full UCUM |
| D16 | A subset of YAML that maps onto JSON |
| D17 | Strict parsing — an unknown field is an error |
| D18 | Keep the data source out of the requirement document |
| D19 | Prefer constructs that decode without custom code |

### [ADR-0003](adr/0003-selection-belongs-to-the-requirement.md) — where the selection lives

A requirement carries its selection once, and every criterion and guard beneath it is about
those requests. Amends D8: the `indicator` object is gone, its substance split between the
requirement and the predicate.

## Unresolved

Open problems, some of which may sink the approach:

- **Declaring "an error occurred" across tools** that all signal it differently
  ([ADR-0002](adr/0002-compatibility.md#open-questions)).
- **A selector matches presence, never absence**, so `bad` can be written and `good` cannot.
- **Histogram resolution.** Percentiles come from buckets, so two targets asserting one
  criterion need not produce the same number.
- **Nothing renders.** Until a document becomes some target's own assertions, tool-agnosticism
  is untested rather than true.
- **Whether load profiles belong in this format at all** — currently
  [not a "yet"](ideas/not-in-the-format.md#the-load-profile).
