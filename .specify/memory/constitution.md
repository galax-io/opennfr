<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0
Bump rationale: MINOR on both limbs of the versioning policy simultaneously — three
principles are added (VI, VII, VIII), and an existing binding constraint is materially
expanded to cover a second class of target.

Principles added:
  VI.   Evaluation Is Target-Blind
  VII.  Architecture Before Implementation
  VIII. Experiments Are Parked, Not Merged

Principles renamed or removed: none. I-V are untouched.

Sections materially expanded:
  - Compatibility Constraints — "Support for a load testing tool MUST be expressible as
    data" widened to "Support for any target", naming both classes. Widened rather than
    duplicated: a parallel bullet saying nearly the same thing is what spec 001 § FR-011
    forbids.
  - Governance → Compliance review — "five principles above" → "eight".

Grandfather clause, stated in VIII rather than hidden: `docs/semconv/loadtest.md` and the
`errorSignal` sketch in `docs/examples/mapping-k6.yaml` both practise labelling without
containment and predate this amendment. VIII binds work admitted after 2026-08-18.

Templates and docs reviewed:
  ✅ .specify/templates/plan-template.md   — stale pointer "(v1.0.0)" corrected to
                                             "(v1.1.0)"; three Constitution Check gates
                                             added for VI, VII and VIII
  ✅ .specify/templates/spec-template.md   — no change needed; the added principles impose
                                             no new mandatory spec section, and all three
                                             are checked at plan time
  ✅ .specify/templates/tasks-template.md  — no change needed; task categories stay generic
  ✅ .specify/templates/checklist-template.md — no change needed
  ✅ AGENTS.md                             — no change needed; VII generalises its
                                             Spec-first rule rather than restating it
  ✅ docs/                                 — no change needed; VI cites compatibility.md
                                             § Layering, which already says it

Citations, each resolvable by file and section without reading git history:
  VI   → docs/compatibility.md § Requirements for the Go implementation → Layering
  VII  → AGENTS.md § Commits & PRs (Spec-first), co-cited with Principle I's ordering rule
  VIII → Principle III's "Any artifact nothing validates MUST say so in its own text",
         which grounds the notice half; the containment half is new, which is why the
         grandfather clause exists.

Deferred / TODO: whether the compatibility-surface list should also cover names the format
defines under `loadtest.*` — currently it covers only names the format *borrows*. Argued in
specs/001-nfr-format-architecture/research.md § D4b; not taken here because it may exceed
MINOR.
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

### VI. Evaluation Is Target-Blind

The component that turns measurements into verdicts is the only thing standing between one
document and one meaning. It stays blind, or the meaning becomes the tool's.

- The component that produces verdicts MUST NOT know which target produced the measurements,
  nor how they were obtained.
- A statistic a target computed for itself MUST NOT be consumed as a verdict. Verdicts are
  computed from normalised series under canonical names.
- How a target derives a percentile MUST be recorded alongside any result that rests on it.
- A measurement taken at one vantage point MUST NOT stand in for one taken at another. A gap
  is declared, never filled by the nearest available number.

**Rationale**: `docs/compatibility.md` § Requirements for the Go implementation → Layering
already says it — "the evaluation layer knows nothing about tools or sources" — and calls that
"the only reason the format can promise compatibility with an arbitrary tool". But that section
is a proposal and nothing is built against it yet, which is exactly when the rule is cheap to
fix. The moment a verdict depends on a tool's own arithmetic, one document stops meaning one
thing and every portability claim the format makes is void.

### VII. Architecture Before Implementation

- Every change that adds or alters a component MUST name the architectural role it fills, and
  MUST stay inside it.
- A specification that needs a role the architecture does not have MUST amend the architecture
  first, in an earlier pull request. Diverging from it silently is FORBIDDEN.
- Implementation MUST NOT arrive ahead of the specification that names its role.
- Amending the architecture MUST NOT require a decision record. It is not a
  compatibility-sensitive surface, and the sanctioned route has to stay cheaper than the
  workaround, or people take the workaround.

**Rationale**: `AGENTS.md` § Commits & PRs already orders the artifacts — "**Spec-first.**
`specs/NNN-*/` artifacts → `docs(speckit): add NNN-<feature> spec/plan/tasks` commit BEFORE any
`feat`/`fix`. Never folded into implementation." — and Principle I orders the vocabulary the
same way. This generalises both from a commit rule into a design rule. Deciding the
architecture and the implementation in one pass is how a design notebook becomes a codebase
nobody can argue with: the architecture stops being reviewable the moment it arrives attached
to working code.

### VIII. Experiments Are Parked, Not Merged

Unsettled work is contained. A notice on something load-bearing is not containment — but a
notice on something already contained is exactly what Principle III requires, so the two rules
meet here rather than compete.

- Work whose correctness is not yet established MUST live in the experimental area and MUST
  NOT enter a compatibility-sensitive surface.
- Every artifact in that area MUST state, in its own text, that it is experimental, what would
  promote it, what would retire it, and the date the statement was last true.
- The experimental area MUST be removable in one operation without changing anything outside
  it, and nothing outside it may link into it.
- This principle binds work admitted **after 2026-08-18**. Two artifacts predate it and are
  grandfathered: `docs/semconv/loadtest.md`, an unsubmitted upstream proposal that core
  constructs already depend on, and the `errorSignal` sketch in
  `docs/examples/mapping-k6.yaml`. Both carry the notice Principle III requires. Neither may
  be cited as precedent for admitting new unsettled work.

**Rationale**: the failure this prevents is "it mostly works, call it v1" — a four-query-language
experiment with four different percentile implementations treated as settled because it is
nearly right. The grandfather clause is written down rather than hidden because two committed
artifacts already practise labelling without containment, and a principle that made them
retroactively non-compliant on the day it shipped would be a rule the repository breaks on
arrival.

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
- Support for any target MUST be expressible as data, not as code in the reference
  implementation. This covers both classes: a load generator that produces the traffic, and a
  monitoring backend that holds telemetry and answers a query. A target list that only
  maintainers can extend is not tool-agnostic.

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
eight principles above before Phase 0 research and again after Phase 1 design. PR review
MUST verify compliance; a violation is either fixed or the constitution is amended, but
never silently accepted. Complexity that appears to require a violation MUST be
justified in writing in the plan's Complexity Tracking section.

**Runtime guidance**: `AGENTS.md` for process, `docs/GLOSSARY.md` for vocabulary,
`docs/adr/` for why any of it is the way it is.

**Version**: 1.1.0 | **Ratified**: 2026-08-10 | **Last Amended**: 2026-08-18
