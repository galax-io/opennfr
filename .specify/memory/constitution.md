<!--
SYNC IMPACT REPORT
==================
Version change: (template, unversioned) → 1.0.0
Bump rationale: MAJOR — first ratification. The file was an unfilled template; every
placeholder is now a concrete, binding principle, which is a new governance baseline
rather than an amendment to an existing one.

Principles defined (all new — no prior titles to rename):
  I.   Vocabulary Before Features (NON-NEGOTIABLE)
  II.  Borrow Names, Never Invent Them
  III. No Silent Green (NON-NEGOTIABLE)
  IV.  Honest Status
  V.   Structure Over Grammar

Sections added:
  - Compatibility Constraints  (template slot SECTION_2)
  - Development Workflow       (template slot SECTION_3)
  - Governance

Sections removed: none.

Templates and docs reviewed:
  ✅ .specify/templates/plan-template.md   — "Constitution Check" filled with the five
                                             concrete gates below (was a placeholder)
  ✅ .specify/templates/spec-template.md   — no change needed; it is stack-agnostic and
                                             adds no constraint the constitution contradicts
  ✅ .specify/templates/tasks-template.md  — no change needed; task categories are generic.
                                             Revisit when an implementation exists and
                                             Principle V starts generating schema tasks
  ✅ AGENTS.md                             — no change needed; it is the runtime process
                                             guide and the constitution now points at it
                                             rather than restating it
  ✅ README.md, docs/                      — no change needed; the principles were derived
                                             from them, not imposed on them

Deferred / TODO: none. RATIFICATION_DATE is today because this is the first adoption;
there is no earlier date to recover.
-->

# OpenNFR Constitution

## Core Principles

### I. Vocabulary Before Features (NON-NEGOTIABLE)

The vocabulary is the product. This repository ships terms, not code, and a term is
harder to withdraw than a feature.

- A new term MUST appear in `docs/GLOSSARY.md` before it appears in an example, a
  schema, or an implementation.
- Every glossary entry MUST record at least one rejected alternative and the reason it
  was rejected. The rejection outlives the term it protects.
- Renaming a term MUST update the glossary and the ADR that argued for it in the same
  change. Contradicting an ADR elsewhere is not permitted; amend it instead.
- Naming disagreements MUST be argued in an issue before files change.

**Rationale**: every added word is a permanent cost paid by every reader and every
implementation. The surveyed formats did not fail for lack of features; they became
unusable across tools because their words meant different things in different places.

### II. Borrow Names, Never Invent Them

- A metric or attribute name MUST come from OpenTelemetry semantic conventions whenever
  an equivalent exists there.
- Names of our own are permitted only under the `loadtest.*` namespace, and only where
  semconv has no equivalent.
- Aliases and second spellings for the same concept are FORBIDDEN, including
  human-friendly shorthands.
- Derived quantities (throughput, error rate, apdex) MUST NOT become metrics. They are
  computed by aggregation from metrics that already exist.

**Rationale**: a second vocabulary is a second source of truth, and the two diverge as
soon as either changes. Borrowing is also what makes a result report correlate with the
traces of the same run without glue.

### III. No Silent Green (NON-NEGOTIABLE)

Nothing may report success by omission. Every state that is not a verified pass MUST be
representable and distinguishable.

- Missing data MUST produce an outcome of its own, never a pass.
- A run that did not meet the conditions a requirement assumes MUST be reported as
  inconclusive — "the test did not happen" — never as a pass or a fail.
- An unknown field in an input document MUST be a parse error, not an ignored key.
- Any artifact nothing validates MUST say so in its own text.
- Any new check that can fail to find data MUST define what that means before it ships.

**Rationale**: this is the failure mode the entire format exists to address. A load test
that under-delivered its load shows green thresholds and a false verdict, and no
surveyed format catches it. A project built to fix that must not reproduce it.

### IV. Honest Status

- A document MUST NOT read as more settled than it is. Notes are labelled as notes.
- An ADR's status MUST reflect reality: `proposed` until something validates or
  implements it.
- Verified facts MUST be separated from speculation, and the reader MUST be able to tell
  which is which without reading the git history.
- A claim about an external tool MUST be checked against that tool's documentation and
  carry the date it was checked.

**Rationale**: a design notebook presenting itself as a specification attracts the wrong
contributions and, worse, invites someone to build against names that will change.

### V. Structure Over Grammar

- Format fields MUST be validatable by a schema without a bespoke parser.
- String DSLs and embedded expressions are FORBIDDEN in the format's own documents.
- Value sets MUST be closed enumerations rather than open grammars.
- Any construct that would require custom decoding logic MUST be justified in an ADR,
  naming what it buys and what it costs.

**Rationale**: a grammar inside a specification has to be reimplemented, identically, in
every backend that reads it — and it never is. This is precisely where the string-DSL
formats surveyed in `docs/references.md` fail.

## Compatibility Constraints

Compatibility-sensitive surfaces, which MUST NOT change without an ADR:

- any OpenTelemetry name the format borrows;
- any field name that appears in a published example;
- the conformance levels and what each one guarantees.

Binding constraints:

- The format MUST NOT contain a construct expressible only at conformance level `assert`
  or above. Anything checkable during a run MUST also be checkable after it, or the
  format silently excludes every tool that cannot assert inline.
- Requirement documents MUST remain portable across observability stacks. The data
  source is a parameter of evaluation, never part of the requirement.
- Support for a load testing tool MUST be expressible as data, not as code in the
  reference implementation. A tool list that only maintainers can extend is not
  tool-agnostic.

## Development Workflow

`AGENTS.md` is the operative process guide; it is not restated here. The constitution
adds only the constraints that outrank convenience:

- `bash scripts/verify.sh` MUST pass on every commit. A change that requires weakening
  the gate MUST justify it in the PR, not in the script.
- Every change MUST travel through an issue, a branch, and a PR carrying a milestone and
  a closing link, as enforced by `scripts/check-linkage.sh`.
- A PR that changes a term MUST update `docs/GLOSSARY.md` in the same PR. Vocabulary
  drift between a change and its documentation is not acceptable, however brief.
- A PR that contradicts an ADR MUST amend that ADR instead.

## Governance

This constitution supersedes other practices in this repository. Where it and any other
document conflict, this document wins and the other document is wrong and MUST be fixed.

**Amendment procedure**: amendments are made by a PR that changes this file and any
templates the change affects, and nothing else. The PR MUST state which principle is
added, altered, or removed, and why the current wording fails. Amendments follow the
same issue/milestone/linkage rules as every other change.

**Versioning policy**: semantic versioning of this document.

- MAJOR — a principle is removed or redefined in a way that permits what it previously
  forbade;
- MINOR — a principle or binding section is added, or existing guidance is materially
  expanded;
- PATCH — clarification, rewording, or a fix that changes no obligation.

**Compliance review**: `/speckit-plan` MUST evaluate its Constitution Check against the
five principles above before Phase 0 research and again after Phase 1 design. PR review
MUST verify compliance; a violation is either fixed or the constitution is amended, but
never silently accepted. Complexity that appears to require a violation MUST be
justified in writing in the plan's Complexity Tracking section.

**Runtime guidance**: `AGENTS.md` for process, `docs/GLOSSARY.md` for vocabulary,
`docs/adr/` for why any of it is the way it is.

**Version**: 1.0.0 | **Ratified**: 2026-08-10 | **Last Amended**: 2026-08-10
