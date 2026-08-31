# Specification Quality Checklist: Identity Has One Scope

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-30
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

- **Iteration 1** raised three questions the user owns, answered on 2026-08-30 and recorded in spec.md § *Decisions*:
  - **Identity scope** — the **list**, `criteria` and `guards` counted apart. The requirement scope, which the schema states today, is the rejected alternative and is recorded as one in FR-007.
  - **How the four places are reconciled** — **one home and pointers**, not four corrected copies. `README.md` § *A predicate* states the scope; the schema and `GLOSSARY.md` name it without repeating it.
  - **The shape of the `name` reach row** — a new `#### Identity` subsection carrying a **third verdict**. A bullet under *Two things Gatling cannot do at all* and a narrowed partition claim were the rejected alternatives, recorded in the Assumptions.
- **Iteration 2** re-ran the checklist with all three resolved. All items pass.
- "Non-technical stakeholders" reads as *a consumer of the format who did not write it* here — concretely, the author of the first OpenNFR renderer, who is named as the reader of all four user stories. There is no end user below that: this repository ships a vocabulary, a schema and a gate, and the people downstream of it build tools.
- Every functional requirement names a document, a sentence or a published row, and every success criterion is decidable by reading the shipped files or running the gate. `scripts/verify.sh` appears throughout because it is the repository's gate and one of the artifacts this milestone changes — it is a deliverable here, not an implementation detail of one. The same is true of the schema.
- **SC-004**, **SC-005**, **SC-006** and **SC-009** are stated as mutations that must redden the gate. That is the standard `scripts/verify.sh` already sets for itself — *"a rule nothing probes is a rule nothing checks"* — and the phrasing is deliberate: #72 exists because a rule that was merely *stated* read as a rule that was checked.
- **One dependency is external and is flagged.** FR-025 and FR-026 rest on Gatling's `Assertion` field list, which cannot be checked from this repository. It is the only claim in the milestone in that position, and the milestone description says so.
- **Iteration 3 (Phase 0)** amended three items and is recorded in spec.md § *What Phase 0 changed* and [research.md](../research.md) § *What Phase 0 changed*. FR-026 stopped requiring a version nobody could open — the row is dated at Gatling **3.13.5**, which `javap` was actually run against. FR-034 went from four files to six: the two identity checks are in separate processes, so the single implementation FR-019 requires has to be a module on disk, and `AGENTS.md` § *Structure* names what the gate shares. SC-008 now requires the version difference to be visible on the page. All three move the spec toward claiming less, and the checklist still passes at every item.
- Items marked incomplete require spec updates before `/speckit-clarify` or `/speckit-plan`. None are.
