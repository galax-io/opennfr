# Specification Quality Checklist: The Denotation Of A Path

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-25
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

- **"Non-technical stakeholders", read for this repository.** The product is a format specification
  and the gate that checks it; its stakeholder is an implementer reading published text. The
  criterion applied is that no requirement names a language, a library or a code structure — and
  none does. Named files, schema nodes and Gatling scopes are the subject matter, not the
  implementation of it.

## Validation history

**Iteration 1** — three `[NEEDS CLARIFICATION]` markers, all load-bearing: where the single copy of
the contract lives, whether depth becomes expressible now, what the quantifier ranges over. Raised
as Q1–Q3.

**Iteration 2** — answers received (`README.md`; make it expressible; one consistent definition).
Markers replaced. The first draft of the resulting rule made an absent `loadtest.group.name`
*unconstrained*, forcing `[]` for a root request and making a bare `{loadtest.request.name: X}`
unrenderable. Rejected in session: an absent group key means an empty hierarchy. That correction is
recorded in Clarifications and cost the corpus three fewer edits.

**Iteration 3** — the design was read back against the repository by five independent reviewers,
one per surface (schema and corpus, gate, prose, neighbouring issues, Gatling evidence). Sixty-three
findings were raised and ten carried to an adversarial refutation round; **none of the ten survived
it**, and the refutation prompt was written to default to *refuted*, so that round is not evidence
of soundness and was not treated as such. What changed the specification is the subset verified by
hand afterwards, listed in § *What the review changed*. Nine items landed. The four that mattered:

- Deleting the contract dangles six markdown links and turns the gate red — reproduced. FR-003 now
  reduces the file to a dated redirect instead, and FR-004 forbids editing any other file under
  `specs/` to achieve it.
- The schema rejects an array **today**, for every attribute, and cannot reject a *scalar*
  `loadtest.group.name` without naming the attribute. FR-008 states the exact edit; the fifth
  clarification records why naming it does not falsify "attribute names are not enumerated".
- "Once of each request the selector admits" counted occurrences — a third granularity after the two
  being replaced. FR-022 now says **request position**, which also makes SC-008 provable rather than
  asserted.
- Rows 2 and 3 are not provably exact: `findPathByParts` has a Group branch and the evidence does
  not settle the resolution order. FR-021 requires it read from source and dated; SC-003 carries the
  exception explicitly until it is.

**Prototype check.** The FR-008 edit was applied to a copy of the schema and probed: list at depth 2
and depth 1, an absent group key, a quantified selector and `{}` all validate; a scalar group value,
an empty list, an array under `http.route`, and a non-string element are all rejected — nine of nine
as the specification requires. SC-005 is therefore achievable as written, and User Story 2's second
acceptance scenario ("the **schema** rejects it, not the gate alone") is true rather than hopeful.

**Open for the user, not blocking.** Two departures are recorded in Assumptions rather than decided
silently, and either can be reversed with a one-line change before planning: making `README.md` the
sole home puts a target correspondence on the format's own page, against constitution Principle VI —
after this, adding a second target changes `README.md`; and the redirect file is a departure from
leaving `specs/` untouched, chosen over deleting because deleting edits three history files instead
of one.
