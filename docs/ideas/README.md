# Ideas

> The format itself is [README.md](../../README.md) and [the schema reference](../../schema/README.md); how it works is [ARCHITECTURE.md](../../ARCHITECTURE.md).

**Constructs the format does not have.** Each page here holds an argument: what the construct
would buy, what it would cost, and what has to become true before it could enter the schema.

None of it is a rule. Where a page here disagrees with
[`schema/opennfr.io/v1/requirementset.schema.json`](../../schema/opennfr.io/v1/requirementset.schema.json),
the schema is right.

This directory exists because the alternative was worse. The vocabulary the format carries and
the vocabulary it does not were filed together in one glossary, in one voice, and a reader had
no way to tell which was which — which is precisely the failure the format exists to prevent,
applied to the repository that defines it.

| | |
|---|---|
| [not-in-the-format.md](not-in-the-format.md) | fields that were argued for and left out: `indicator`, `window`, `baseline`, `severity`, `gate`, `enforcement`, `onViolation`, `defaults`, `indicatorRef` |
| [the-result-document.md](the-result-document.md) | what an evaluation would produce — `Verdict`, `Outcome`, `EvaluationReport` — and why nothing produces one |
| [tool-support.md](tool-support.md) | how the format would reach a tool: `Assertion`, `Target`, `Adapter`, `MetricMapping`, and the retired conformance ladder |

## How something leaves this directory

```
note here  ->  argued in an issue  ->  ADR  ->  glossary entry  ->  schema  ->  the note is deleted
```

The last step is not optional. A note that has become a rule is a second source for one
decision, and two sources drift. The reasoning is not lost when the note goes: it lands in an
ADR, in a [glossary](../GLOSSARY.md) entry's *Rejected* line, or in the schema itself. What is
deleted is the duplicate, never the argument. [LAYOUT.md](../../LAYOUT.md#how-an-idea-becomes-part-of-the-format)
owns the rule.

The gate a construct has to clear is stated in
[the constitution](../../.specify/memory/constitution.md): *a construct MUST NOT enter the
format unless at least one surveyed target can assert it exactly*. That is a floor and not a
licence — one target being able to assert something is necessary for admission and is not by
itself sufficient.
