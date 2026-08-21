# Specification Quality Checklist: An Assertion-First Requirement Format

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-19
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

**Iteration 1 — 2026-08-19.** Three `[NEEDS CLARIFICATION]` markers, all open by design.

**Iteration 2 — 2026-08-19.** All three resolved into § *Decisions taken during specification*, each
with its rejected alternatives:

| Question | Decision |
|---|---|
| Preconditions, when no target has an `inconclusive` outcome | D1 — render like a criterion, carry a name into the target's own report |
| "Each request individually" versus "the aggregate" | D2 — the format gains the distinction |
| What admits a construct, now that post-run evaluation is out of scope | D3 — at least one surveyed target must assert it exactly |

**Iteration 3 — 2026-08-19.** Three changes of scope, all requested:

1. **Decoupled from the downstream issue.** The specification no longer carries a deliverable in, or
   a prerequisite for, any other project. FR-023 became "publish the six statements as worked
   examples **in this repository**"; SC-010 became the deletion sweep; the cross-repository
   dependency row was removed. A duplicated ADR row was removed in the same pass. The prior format
   remains, framed as evidence.
2. **Tests added.** New User Story 5, requirement block *What must be tested* (FR-028…FR-037), and
   SC-014…SC-017, SC-019. Appendix C states what the corpus will **not** establish, as FR-037
   requires of the corpus itself.
3. **Deletion sweep specified.** Requirement block *What must leave the notebook* (FR-038…FR-042),
   the tiered section *What leaves the notebook, and in what order*, and SC-018.

### One correction to the specification's own claims

Iteration 2 recorded constitution Principle III as surviving **intact**. That was wrong. Its spirit
survives and does most of the work in this feature, but its letter mandates that a run which did not
meet its conditions "MUST be reported as inconclusive", and decision D1 removes that outcome. The
*Dependencies and Constraints* table now records Principle III as **requiring an amendment in an
earlier pull request**, and Tier 1 of the deletion sweep is blocked on it.

### Why most of the deletion sweep is not in this feature

The sweep was audited file by file and every proposed deletion was then argued against. The majority
did not survive, always for one reason: a rule is written in as many as four places, one of which
binds, and the constitution's Governance section says the binding copy wins. Deleting the notebook
copy first would leave the repository formally requiring what this feature forbids. That produced
FR-039 and the four tiers, and it is a finding about sequencing rather than a reduction in scope.

### Carried forward, not checklist failures

- **Appendices A and B name external and internal implementation detail.** Both are marked as dated,
  sourced evidence and explicitly not part of the format. Principle IV forbids an unsourced claim
  about an external tool, so removing them would be the worse defect.
- **Three prerequisite amendments** are recorded in § *Dependencies and Constraints*: constitution
  Principle III, constitution Principle VI, and `ARCHITECTURE.md`. Principle VII requires all three
  to land in **earlier** pull requests.
- **`docs/compatibility.md` and ADR-0002 hold the rule FR-020 inverts.** All four copies are removed
  in one change, after the binding copies are amended — Tier 2.

### Defects found in the gate while validating this specification

Four sites in `scripts/verify.sh` where a check cannot fail, or fails without turning the build red.
Each was read and confirmed by hand; all four are recorded in Appendix B, and they are the evidence
behind FR-034 and FR-035. They are one concern and belong in their own change, not this feature.
