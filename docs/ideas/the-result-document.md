# The result document

> The format itself is [README.md](../../README.md) and [the schema reference](../../schema/README.md); how it works is [ARCHITECTURE.md](../../ARCHITECTURE.md).

**Notes, not rules.** Nothing in this repository produces a result, and no schema describes
one. The vocabulary below was designed when this project expected to compute the answer itself.
It is kept because the arguments in it survive the change of direction, and because the
question it answers — *where does the answer come from?* — did not go away.

---

## What changed, and why this page is not simply deleted

The first design had this project evaluating: a component would read normalised series,
compute each statistic itself, and emit a document saying what happened. That is what made a
result document necessary — *"parses into any backend"* is unmet if a backend has a standard
input and no standard output.

Constitution 2.0.0 reversed it. The format is assertion-first: **the target computes its own
statistic, asserts against it, and reports**. This project does not recompute. The reason is
stated in Principle VI and is not a preference —

> 1.1.0 placed this obligation on a component that was never built and cited a proposal as its
> authority.

— a rule about a component nobody had started is not a guarantee, and it read as one.

The cost is named rather than hidden: two targets asserting the same criterion need not produce
the same number, and no rule here can make them. What the format can honestly promise is that
the *statement* is one statement, and that every place two targets disagree is written down
where a reader will find it.

So a result document is not currently owed by anything. Designing an output before something
computes it is guessing, and a guess in a schema is harder to withdraw than a guess in a note.

---

## The vocabulary, as it stood

### Verdict

The result of checking **one** criterion or guard.

`status`: `pass | warn | fail | noData | skipped`

`noData` was mandatory and was not a success: missing data is an outcome in its own right, not
a silent green. That part of the argument is untouched by the change of direction, and now
lands in a different place — where a target's own evaluation can pass on absent data, that has
to be declared in the target's description, dated and sourced.

Known hole while it stood: `skipped` appeared in the enum and in the report sketch, and no
`gate` key handled it. Silence about a state is undefined behaviour in a project whose third
principle forbids exactly that.

### Outcome

The aggregated result of the whole run: `pass | warn | fail | inconclusive`.

`inconclusive` was a first-class outcome and meant *"the test did not happen"* — a
fundamentally different engineering decision from *"the system does not hold"*.

**It is struck.** No surveyed target has a third outcome, so nothing could produce one, and
constitution 2.0.0 is explicit: *"The format MUST NOT define a third report state for it."* The
distinction it protected is not abandoned — it survives as a statement the document can make
(a [guard](../GLOSSARY.md#guard)), as an assertion a target actually runs, and as a record of
which entries state a condition of the run rather than a property of the system. That is one
place fewer than before, and every part of it is something a real target can do.

Rejected, then and now: folding it into `fail`. The two call for different actions — one sends
you to the system, the other to the test rig.

### EvaluationReport

`kind: EvaluationReport`, the second schema that would have existed.

The durable part is what it did **not** define: run identity used existing OpenTelemetry
attributes — `test.suite.name`, `cicd.pipeline.run.id`, `service.name`, `service.version`,
`deployment.environment.name` — rather than fields of its own. That is what would let a report
correlate with the traces of the same run without glue, and it stays the right answer whenever
something does emit a report.

Rejected: a `loadtest.run.id` of our own — `cicd.pipeline.run.id` and `test.suite.name` already
exist, and [Principle II](../../.specify/memory/constitution.md) forbids inventing a name where
one is available.

---

## What would have to be true first

1. Something computes or collects a result — today nothing does.
2. The result's vocabulary is a target's, or is declared per target. A report that asserts two
   targets computed the same percentile the same way would be a lie the format cannot detect.
3. Whatever it says about missing data can actually be produced by a surveyed target. That is
   the constraint that killed `inconclusive`, and it applies to every state a report could name.
