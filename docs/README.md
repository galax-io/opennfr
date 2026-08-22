# Ideas

**Nothing here is documentation.** Every page in this directory is an idea about the format —
something that has to be **built**, **reworked** or **dropped**. None of it is a rule, and a
reader who wants to know what the format actually is should not be here at all.

What the format is: `README.md` at the repository root, `schema/README.md` beside the schema,
and `reference/` for the vocabulary, the units, the names, the tool survey and the decision
records. Those are deliberately **not linked from this page**, and this directory is not linked
from them.

## The isolation rule

Nothing outside `docs/` may link into it. Outside references name a path in prose, inside a code
span, never as markdown link syntax — `scripts/verify.sh` fails the build on a link that crosses
that boundary in the wrong direction.

The rule is not tidiness. It buys one property, and it is a property you can run:

```bash
git rm -r docs && bash scripts/verify.sh
```

Every idea in here can be dropped in one operation without breaking a single real document. An
idea you cannot cheaply abandon is an idea you will keep for the wrong reasons.

Links pointing the other way — from here out to the format — are fine and expected. An argument
about a construct has to be able to name what it would change.

## What is parked here

| | |
|---|---|
| [not-in-the-format.md](not-in-the-format.md) | fields that were argued for and left out: the retired `indicator`, `window`, `baseline`, `severity`, `gate`, `enforcement`, `onViolation`, `defaults`, `indicatorRef`, and the load profile |
| [the-result-document.md](the-result-document.md) | what an evaluation would produce — `Verdict`, `Outcome`, `EvaluationReport` — and why nothing produces one |
| [tool-support.md](tool-support.md) | how the format would reach a tool: `Assertion`, `Target`, `Adapter`, `MetricMapping`, the retired conformance ladder, and the notes for a reference implementation |
| [semconv/loadtest.md](semconv/loadtest.md) | a proposed `loadtest.*` extension to OpenTelemetry, submitted nowhere, emitted by nothing |
| [examples/](examples/) | sketches of documents and tool mappings. They use constructs the format does not have, which is why they are here and why nothing validates them |
| [experimental/](experimental/) | the parked monitoring direction, with its own promotion and retirement conditions |

## How something leaves

```
note here  ->  argued in an issue  ->  ADR  ->  glossary entry  ->  schema  ->  the note is deleted
```

The last step is not optional. A note that has become a rule is a second source for one
decision, and two sources drift — which is the failure the format exists to prevent, applied to
the repository that defines it. The reasoning is not lost when the note goes: it lands in an
ADR, in a glossary entry's *Rejected* line, or in the schema itself. What is deleted is the
duplicate, never the argument.

The bar a construct has to clear before it can leave is in the constitution: *a construct MUST
NOT enter the format unless at least one surveyed target can assert it exactly*. That is a floor
and not a licence — one target being able to assert something is necessary and is not by itself
sufficient.
