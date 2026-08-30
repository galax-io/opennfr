# Data Model — The Constitution Catches Up

**Feature**: `010-constitution-catches-up` | **Date**: 2026-08-30

There is no data. This feature adds no field, no value and no term, and changes nothing a renderer
reads. What it has instead is a set of **normative statements**, each with one home and a status, and
the milestone is a change to four of them and to the two files that quote them. This document is the
inventory: where each statement lives, what it says now, and what it says after.

## The statements this milestone touches

| # | Statement | Home | Now | After |
|---|---|---|---|---|
| S1 | what adding a target may change | `.specify/memory/constitution.md:144-146` | *"…or any existing document"* — false of the repository since v0.5.0 | the format, the schema and the corpus stay out of reach; **one** existing document is reachable, named by role |
| S2 | what a target's description *is* | nowhere | undefined, though three clauses already constrain one | defined in Principle VI: what a renderer reads to turn a document into that target's assertions |
| S3 | whether this repository describes a target | `.specify/memory/constitution.md:225` | *"nothing in this repository describes a target"* — false since v0.5.0 | one exists, `README.md` § *What any tool can actually run*; the surface stays off the compatibility list, and why is recorded |
| S4 | which quantities may not become metrics | `.specify/memory/constitution.md:83-84` | three names under one reason, false of the third | two names under the reason true of them; a second clause for composite quantities, naming apdex |
| S5 | where a second target goes | `AGENTS.md:35` | the rule, plus a parenthetical declaring it a departure | the rule alone |
| S6 | the Principle VI gate a plan answers | `.specify/templates/plan-template.md:61-63` | quotes S1's withdrawn wording | quotes S1 as amended, and asks after S2's singularity |
| S7 | which aggregations the format has | `docs/ideas.md:81` | six names and the percentile pattern | seven names and the pattern, with the seventh's disposition stated |

S1–S4 are the constitution. S5–S7 are what follows it. Nothing else in the repository changes.

## Where each statement is allowed to be repeated

The amendment turns a *structural* containment into a *counted* one, so the count is the model.

| Statement | Copies permitted | Copies today | Enforced by |
|---|---|---|---|
| a target's description | exactly one per target | one — `README.md` § *What any tool can actually run*; `specs/004-strip-to-schema/contracts/gatling-reach.md` is a redirect that says it carries no rule | review. No script reads for this |
| the reason a description's row gives | the description, plus the gate implementing it | two, by v0.6.0's FR-023, which required it | review |
| a survey fact naming a tool | unbounded — not a description | `README.md:49`, `:56`, `:478`, `:759`, `docs/ideas.md:130` | nothing; the rule does not reach them |
| the rule about what may not become a metric | the constitution states it; `README.md` § *Names* restates the author-facing half | two, agreeing | review, and #75 is what happens when they stop agreeing |
| the argument for why apdex is not a metric | `docs/ideas.md`, once | one | Principle VIII's entry/condition count |

The middle row is the one Phase 0 changed. A rule forbidding every second statement of a target fact
would have made the gate's comments, and the survey sentence at `README.md:478`, violations of a MUST
in the constitution ([research.md](./research.md) R1).

## Two classes of quantity, and the aggregation set they are decided against

S4 splits one class into two. The split is not new vocabulary — `docs/ideas.md:84-86` already draws it
— it is the constitution catching up to a distinction the repository was already making.

| Class | Reduces to | Example | Why it is not a metric |
|---|---|---|---|
| **derived** | one construct the format has | throughput → `aggregation: rate`; error rate → a `bad` fraction | an aggregation already computes it, so a metric would be a second spelling |
| **composite** | nothing the format has | apdex | it needs a banded classification carrying a second threshold and an aggregation weighting the bands, and there are neither |

The set it is decided against, from `$defs/aggregation` — an `anyOf` of an enum and a pattern:

```text
avg  min  max  count  rate  sum  stddev        ^p\d{1,2}(\.\d+)?$
```

Seven names. `docs/ideas.md:81` lists six of them, which is S7's defect. `sum` adds up the values a
metric carries; nothing in the format classifies a request into a band or gives a band a weight, so
no weighted sum of counts is available to any of the seven.

## The invariant

**Every normative statement has one home, and the home is where a reader looking for the rule goes
first.** Both issues in this milestone are that invariant broken the same way: a statement was
corrected where readers meet it and left standing where authority sits. The amendment does not add
machinery for it — nothing here reads `.specify/memory/constitution.md`, and that is stated in the
principle rather than implied away.

What the milestone leaves behind is one countable property a reviewer can check without judgment:
**one description per target**, and a gate that points at it rather than restating it.
