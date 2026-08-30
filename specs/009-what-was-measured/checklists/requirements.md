# Specification Quality Checklist: What Was Actually Measured

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-30 | **Revised**: 2026-08-30, after adversarial review
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

## Constitution Check *(this repository's own gates, checked here rather than deferred)*

- [x] **I. Vocabulary before features** — no term is added; `GLOSSARY.md` gains three *Rejected* lines and no entry (FR-005, FR-012, FR-018, FR-024)
- [x] **II. Borrow names, never invent** — nothing is minted, and the text does not claim a naming gap where conventions already name the operation (FR-016, FR-018)
- [x] **III. No silent green** — FR-001 ends the one place a field did nothing without a message; FR-006 gives three unprobed axes their first probe list and its floor
- [x] **IV. Honest status** — no new claim about an external tool (FR-022, SC-011); both decisions state what would reopen them
- [x] **V. Structure over grammar** — the schema gains no rule; two descriptions state meanings it already enforces or already leaves open
- [x] **VI. The requirement is target-blind** — the format is narrowed in neither direction (FR-002, FR-014), and one target fact is *removed* from a field description (FR-013)
- [x] **VIII. Ideas are parked, not merged** — no entry is added to `docs/`; the existing registry entry gains one clause, keeping the isolation gate's two counts equal (FR-019)
- [x] **Compatibility** — no borrowed name and no field name changes; the corpus does not narrow and neither does the format, which is the constraint that reversed the first draft's schema rule

## What the adversarial review changed

This checklist passed on the first draft too, which is why the review was run rather than trusted to
it. Two decisions were reversed and three corrected; the spec's § *What the review changed* carries
each finding and how it was verified. The two that this checklist had wrongly ticked:

- **Compatibility** was ticked while the draft narrowed the format to one target's reach, deleting a
  format-level claim from `README.md` to make the schema agree with a Gatling table. The binding
  constraint says the opposite in as many words.
- **I. Vocabulary before features** was ticked on "no term is added" while the draft added a
  taxonomy — two kinds of `cannot`, defined once and marked on rows. Its own contract then misfiled
  `good` under the wrong kind. A category is an entity even when it is not a term.

Both are now the other way, and both are visible in the file-change table rather than only in prose.

## Notes

Two items deserve their reading recorded rather than a silent tick, because this repository's product
is text:

- **"No implementation details" and "technology-agnostic success criteria."** The deliverables here
  *are* a JSON Schema, `README.md`, `GLOSSARY.md`, `docs/` and one gate script — naming them is
  naming the product, not an implementation of it. What the checklist forbids is a stack decision
  smuggled into a requirement, and none appears.
- **"Written for non-technical stakeholders."** The audience is an implementer building a renderer.
  Each user story opens with the concrete failure a reader meets today and what they can do
  afterwards, which is the closest honest reading of that item for a format spec.

Items marked incomplete would require spec updates before `/speckit-tasks`. None are.
