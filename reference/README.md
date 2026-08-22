# Reference

What is true of the format today.

Everything on these pages is either enforced by
[`schema/opennfr.io/v1/requirementset.schema.json`](../schema/opennfr.io/v1/requirementset.schema.json)
and `scripts/verify.sh`, borrowed verbatim from a source outside this repository, or a fact
checked against somebody else's documentation and dated. Where a page says something is a design
rather than a rule, it says so in its own text.

**Ideas do not live here.** Constructs the format does not have — and the arguments for them —
are under `docs/`, and nothing in this directory links there. That one-way rule is what makes
`docs/` deletable in a single operation without breaking anything real.

| | | Trust |
|---|---|---|
| [glossary.md](glossary.md) | every term the schema carries, each with the alternative that was rejected and why | Enforced. `scripts/verify.sh` rejects a document that breaks one |
| [units.md](units.md) | the closed unit list, and how the units convert | The list **is** the schema's `unit` enum. The conversions are a design, and nothing implements them |
| [names.md](names.md) | which OpenTelemetry metric and attribute names to write, and the one name this repository did not borrow | Borrowed verbatim from semantic conventions. Not checked by the schema, which does not enumerate names |
| [compatibility.md](compatibility.md) | what load testing tools actually emit | Checked against each tool's own documentation, August 2026 |
| [prior-art.md](prior-art.md) | the survey: OpenSLO, Keptn quality gates, k6 thresholds, Taurus PassFail, SLA4OAI, gatling-picatinny and adjacent SLO tooling | Checked against each project's own documentation |
| [adr/](adr/) | the decision records — why the format is the way it is | `status: proposed` throughout, and honest about it |

## The decision records

| | |
|---|---|
| [ADR-0001](adr/0001-terminology.md) | naming: what to call the thing, three layers, borrowed metric names, structure over string DSLs, a mandatory unit, guards, and the reserved `workload` |
| [ADR-0002](adr/0002-compatibility.md) | implementation and tools: adapters, support as data, a fallback for addressing requests, a closed unit list, strict parsing, and keeping the data source out of the document |
| [ADR-0003](adr/0003-selection-belongs-to-the-requirement.md) | a requirement carries its selection once. Amends ADR-0001 § D8 — the `indicator` object is gone, its substance split between the requirement and the predicate |

An ADR is amended, never contradicted. A pull request that disagrees with one changes that ADR
in the same change — see [LAYOUT.md](../LAYOUT.md).

## Where the rest is

| | |
|---|---|
| [README.md](../README.md) | the entry point: what the format is, and every field explained |
| [schema/README.md](../schema/README.md) | the schema reference: every constraint, every enumerated value |
| [ARCHITECTURE.md](../ARCHITECTURE.md) | how a requirement would become an outcome |
| [LAYOUT.md](../LAYOUT.md) | where every kind of file lives and what changing it obliges |
