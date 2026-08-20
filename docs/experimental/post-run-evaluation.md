# Parked: post-run evaluation

**Status: parked. Last true: 2026-08-21.**

**What would promote it:** a specification that revives the component which turns measurements
into verdicts. Constitution Principle VI already holds a dormant obligation waiting for exactly
that: such a component must not know which target produced the measurements, nor consume a
statistic a target computed for itself.

**What would retire it:** a decision that the format is permanently assertion-first and that no
verdict-producing component returns. Nothing has decided that. The arguments below were not
found wanting — they were found to describe a path the format no longer has.

---

## Why this is here

The format's output is now the target's own assertions. The target evaluates, reports and
decides the run; this project computes nothing after it. Everything below described what
happened *after* the measurements arrived, and the vocabulary it is written in — verdicts,
outcomes, a gate policy, a result document — names things nothing in scope produces.

Each entry is moved rather than deleted because the reasoning cost more to reach than the
words did, and because a reader meeting one of these words in an older document needs
somewhere to go.

---

## gate

The policy that turned many verdicts into a single run outcome.

```yaml
gate:
  onBlocker: fail
  onWarning: warn
  onInfo: ignore
  onNoData: fail              # silence is not success
  onGuardViolation: inconclusive
```

The line worth keeping is the comment: **silence is not success**. That survives the parking
and is now enforced at render time instead — a predicate is either rendered or named as one the
target cannot express, and there is no third bucket.

**Known defect, recorded before parking.** `onNoData: fail` produces a *silent red*: a run in
which nothing failed emits no series carrying an error attribute, which is no data, which under
this policy fails the run because the system was perfect. Whatever revives this must answer
that.

## severity

`blocker | warning | info`, feeding the outcome through `gate`.

**Rejected: a fourth level.** Three, not four — in practice nobody distinguishes a `critical`
sitting between `blocker` and `warning`, and a level nobody can apply consistently is a level
that gets applied inconsistently.

## enforcement

Where a criterion was checked.

| Value | Meaning |
|---|---|
| `post` | computed by the backend after the run from collected metrics (**default**) |
| `inline` | rendered into the tool's assertion and checked during the run |
| `both` | both of the above |

`post` was the default *because it was achievable for every tool*. That sentence is the whole
argument and also the whole reason it is parked: with post-run evaluation out of scope, the
default is unreachable and only `inline` remains, which makes the field a constant.

If this returns, it returns under these names rather than three new ones.

## onViolation

`continue` (default) | `abort` — stop the run. For `enforcement: inline` only.

Note for whoever revives it: **the admission floor is already met.** k6 has `abortOnFail` with
`delayAbortEval`, and Taurus has stop-as-failed, so at least one surveyed target can assert it
exactly. It is parked not for want of a target but because the field it depends on is parked.

## Verdict

The result of checking one criterion or guard. `status: pass | warn | fail | noData | skipped`.

**`noData` is the durable part.** Missing data is an outcome in its own right, not a silent
green. That argument outlives the vocabulary: it is why the format now insists a predicate the
target cannot express is *named* rather than dropped, and why a target that can pass an
assertion which matched nothing must declare it.

**Known defect, recorded before parking.** `skipped` appeared in this enum and in the report
sketch, and no `gate` key handled it. Silence was undefined behaviour in a project whose
founding principle forbids exactly that.

## Outcome

The aggregated result of the whole run: `pass | warn | fail | inconclusive`.

`inconclusive` was a first-class outcome, not a special case of `fail`. It meant *"the test did
not happen"*, which is a fundamentally different engineering decision from *"the system does
not hold"*.

**Why it went.** No surveyed target has a third outcome. Gatling's report is OK/KO per
assertion result; k6's is pass or fail per threshold. Requiring a third would have forced every
rendering either to fabricate it or to drop the construct that produced it.

**Where the distinction went instead.** It is still statable in a document, it still renders
into an assertion the target actually runs, and it is still attributable — through the
rendering, which records for each entry the identity the target derives its own report line
from, and whether that entry states a condition of the run rather than a property of the
system. One place fewer than an outcome, and every part of it is something a target can do.

## EvaluationReport

`kind: EvaluationReport` — the format's proposed second normative schema.

The claim behind it: *without a standard output, "parses into any backend" is unmet — a backend
needs a standard output, not only a standard input.* That is still a good argument. It is
parked because nothing in scope produces output.

**The part worth carrying**, because it is a finding rather than a proposal: run identity needs
**no fields of our own**. `service.name`, `service.version`, `deployment.environment.name`,
`test.suite.name`, `cicd.pipeline.run.id` and `vcs.ref.head.revision` are all existing
OpenTelemetry attributes. That is what would let a report correlate with the traces of the same
run without glue, and it is why Principle II's "borrow, never invent" survived contact with the
one place a new namespace would have been most tempting.

**Also parked with it:** the sketch of a result document that lived at
`docs/examples/checkout-perf.report.yaml`. Its argument is here; the file itself is not, because
this area is markdown only. What it illustrated is the shape above.

---

## What is deliberately not here

The **guard** construct itself. Preconditions were not parked — they stay in the format, render
into the target's own assertions like any criterion, and are told apart by their entry in the
rendering rather than by an outcome. Only the third outcome went.
