# Specification Quality Checklist: Which Numbers a Predicate May Carry

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-09-01
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- Items marked incomplete require spec updates before `/speckit-clarify` or `/speckit-plan`

### Iteration 3 — 2026-09-01 — all items pass

The `Long`/`Int` finding moved from *Out of Scope* into #59 on the maintainer's call, and checking
it against the spec's own scope rules turned up that it was never separable:

- FR-017 restates what § *Units*' `Target` column **means**; the count cell is wrong under the new
  meaning as much as the old, so a correct FR-017 cannot leave it standing.
- The whole-number rule is worded *"where the target is an `Int`"*. Correcting the cell alone would
  drop counts out of the rule and make `20.5 {request}` renderable — so FR-017e rewords the rule to
  the property it was always testing.
- Neither count row's integral flag is reached by any probe: both can be flipped and the gate stays
  **green**. FR-017f adds the probe and raises the floor.

Three FRs (FR-017d/e/f), three acceptance scenarios, one edge case and two success criteria
(SC-009, SC-010). *Out of Scope* loses its first bullet. Scope is still bounded: no document
changes renderability, and `examples/` is still untouched.

### Iteration 2 — 2026-09-01 — all items pass

Both markers resolved by the maintainer; both went to the recommendation.

- **FR-017** → narrow the attribution, change no rule. FR-017 became FR-017/a/b/c: the `Int` is
  named as the DSL entry points' type, the read is dated and versioned, the whole-number rule is
  held unchanged, and the reason it was not relaxed is recorded so the argument is not reopened.
- **FR-022** → extend the two duration statistics' `Accepts` cells, one row per statistic. The
  issue's separate-row wording is refused in the requirement itself, with the reason.

Both decisions are in *Decisions* § *Session 2026-09-01* as Q&A, so the spec carries the argument
and not only the outcome.

### Iteration 1 — 2026-09-01

Two [NEEDS CLARIFICATION] markers stood, both raised to the maintainer rather than guessed:

- **FR-017** — the fact is settled (re-read locally at Gatling 3.13.5 / shared-model 0.0.11 on
  2026-09-01); what the format does about it is not. No reasonable default: (a) changes no
  document's validity, (b) widens what is renderable and makes reach depend on how a renderer is
  built, (c) leaves a claim this milestone has just shown imprecise standing in a table it is
  editing.
- **FR-022** — whether the Units table extends the two duration statistics' `Accepts` cells or
  gains a separate row as #74's wording proposes. No reasonable default: the issue's words point
  one way, § *Units*' own "units are per statistic" framing points the other.

On the "non-technical stakeholders" item: the stakeholder for a format specification is a renderer
author, and the spec is written to that reader throughout. Version numbers, file paths and type
names appear as **evidence for claims about artifacts that already exist**, which Principle IV
requires be dated and attributed — not as instructions for how to build anything. No requirement
below names how a change is to be implemented.

Three claims in the spec were reproduced rather than quoted from the issues, and two corrected
what the issues say:

- The percentile helper admits **five** shapes the row rejects, not four — `p1.` is a fifth.
- `multipleOf: 0.001` **rejects** `1.001`, `1.003` and `1.005` under `jsonschema` 4.26.0, so #59's
  second proposed close reproduces the defect it was proposed to fix.
- The six duration conversions and the two sub-millisecond refusals were each computed.

And one assumption in the first draft was wrong and is corrected: it said no Gatling jar was
present to re-read. The jars are in the local Coursier cache, #59's closing claim was verified from
them, and the same read turned up a `Long`/`Int` mismatch in § *Units* that no issue mentions —
recorded under *Out of Scope*, because it is nobody's issue yet and AGENTS.md forbids it riding
along.
