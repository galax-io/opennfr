<!--
SYNC IMPACT REPORT
==================
Version change: 1.1.0 → 2.0.0

Bump rationale: MAJOR on three counts, each independently sufficient under this document's
own policy — "a principle or a binding constraint is removed, or redefined in a way that
permits what it previously forbade".

  1. Principle III no longer mandates the outcome `inconclusive`, which it previously
     required and which no surveyed target can produce.
  2. The first binding constraint is INVERTED. It forbade a construct expressible only by
     asserting; the replacement requires that at least one target be able to assert it.
  3. Principle VI permitted nothing it now permits: consuming a target's own statistic to
     decide a run was forbidden and is the design.

Principles renamed:
  VI. "Evaluation Is Target-Blind" → "The Requirement Is Target-Blind"
      The number is kept. Numbers are cited from templates, specifications and
      ARCHITECTURE.md, and a reused or renumbered principle silently redirects every
      citation without touching a citing file. The versioning policy now says so.

Principles removed: none. I, II, IV, V, VII, VIII are untouched.

Sections materially changed:
  - Principle III — rewritten. The guarantee is unchanged; where it is enforced moved. It
    now names the two places silence can actually enter under an assertion-first format: a
    predicate dropped at render time, and a target passing an assertion that matched
    nothing. Both were observed in a surveyed target's own source and tests, not inferred.
  - Principle VI — rewritten. 1.1.0 placed the obligation on a component that was never
    built and cited a proposal as its authority. The obligation is not deleted; it is made
    dormant and binds the specification that revives that component.
  - Compatibility Constraints — the surface list's third item changes from "the conformance
    levels and what each one guarantees" to what a target's description may declare. The
    ladder is RETIRED rather than edited, and until the ADR retiring it lands, no artifact
    may cite a conformance level.
  - Governance → versioning policy — a limb correction, PATCH in isolation, carried here so
    2.0.0 can be stamped honestly. Adds the highest-limb rule and the principle-number rule.

Grandfather clause from 1.1.0 (VIII, docs/semconv/loadtest.md and the errorSignal sketch)
is untouched and still binds work admitted after 2026-08-18.

Templates and docs reviewed:
  ✅ .specify/templates/plan-template.md   — pointer corrected to (v2.0.0); the III, VI and
                                             Compatibility gates rewritten to ask what the
                                             amended principles actually require
  ✅ .specify/templates/spec-template.md   — no change needed; no new mandatory section
  ✅ .specify/templates/tasks-template.md  — no change needed
  ✅ .specify/templates/checklist-template.md — no change needed

Owed by this amendment, in their own pull requests:
  - ARCHITECTURE.md §§ 1–7. Its clause 3 is the fourth copy of the inverted constraint, and
    its § 2 role table is where a rendering gets a definition to point at.
  - An ADR superseding ADR-0002 § D13. The Compatibility Constraints text forbids only NEW
    citations; the four documents that carry existing ones — ARCHITECTURE.md, docs/GLOSSARY.md,
    LAYOUT.md, docs/adr/0002-compatibility.md — are corrected by the PRs above, and specs/ is
    history and stays as written.

Deferred: whether the compatibility-surface list should also cover names the format defines
under `loadtest.*` — carried forward unresolved from 1.1.0.
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
representable and distinguishable — and where nothing on the path can represent one, the
format MUST NOT pretend otherwise.

- An unknown field in an input document MUST be a parse error, not an ignored key.
- Every predicate in a document — a criterion, or a statement of the conditions a
  requirement assumes — MUST be accounted for when the document is rendered for a target:
  either rendered into that target's own assertions, or reported by name, with a reason, as
  one that target cannot express. The two lists MUST cover the document exactly, and the
  report MUST arrive before the run starts. A predicate that produced neither is a check
  that never ran and a run that looks clean.
- A predicate a target can express only approximately MUST be reported as one that target
  cannot express. An approximation is a silent green with a plausible number in it.
- A run that did not meet the conditions a requirement assumes MUST be statable in the
  document, and MUST render into the target's own assertions, so that such a run fails
  where the target reports rather than passing quietly. The format MUST NOT define a third
  report state for it. No surveyed target can produce one, and a construct nothing can
  honour is a silent green of its own.
- Why such a failure happened MUST be recoverable after the run. Where a target derives
  every line it prints from the assertion itself and accepts no name of the author's
  choosing, that attribution is carried by the rendering — which records, per entry, the
  identity the target will derive its own report line from, and which entries state a
  condition of the run rather than a property of the system. It is never carried by a field
  the target does not have.
- Where a target's own evaluation can pass on absent data — an assertion whose scope
  expands to nothing, a selection that received no samples — that MUST be declared in that
  target's description, dated and sourced. An undeclared one is a defect of the
  description, not of the format.
- Any check that can fail to find data MUST define what that means before it ships, and any
  check that cannot run MUST fail rather than skip. A suite that skips reads exactly like a
  suite that passes.
- Any artifact nothing validates MUST say so in its own text.

**Rationale**: this is the failure mode the entire format exists to address. A load test
that under-delivered its load shows green thresholds and a false verdict, and no surveyed
format catches it. A project built to fix that must not reproduce it.

What changed in 2.0.0 is where the guarantee is enforced, not the guarantee. While post-run
evaluation was the path, this principle could name outcomes — `inconclusive` for a run that
did not happen as intended, an outcome of its own for missing data — because this project
would have produced them. Nothing in scope produces an outcome now; the target does, and no
surveyed target has a third one. An obligation written in a vocabulary nobody emits is not a
guarantee but an unenforceable sentence, and while it stood it read as the guarantee — which
left the two places silence can now actually enter unguarded: a predicate dropped at render
time, and a target passing an assertion that matched nothing. Those are what the bullets
above name, and they are named because both have been observed in a surveyed target's own
source and its own tests, not inferred.

The distinction the removed outcome protected — "the test did not happen" against "the
system does not hold" — is not abandoned. It survives as a statement the document can make,
an assertion the target actually runs, and an entry in the rendering that says which line of
the target's report it will become. That is one place fewer than before, and every part of
it is something a surveyed target can do.

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

### VI. The Requirement Is Target-Blind

One document means one thing because the document — not the machinery under it — is the thing
that stays free of targets.

- A requirement document MUST NOT name a target: not in a field, a value, a metric name, or an
  example. It carries no per-target section, override or conditional.
- The correspondence between the document's vocabulary and a target's own MUST live in that
  target's description. Adding a target MUST NOT change the format, the schema, or any
  existing document.
- A target's own statistic MAY decide the run. That is what an assertion-first format is: the
  target computes its percentile, asserts against it, and reports. This project does not
  recompute it. What the format MUST NOT do is imply that two targets asserting the same
  criterion compute the same number. Where a derivation differs — how a percentile is taken,
  at what vantage point a measurement is made, in what unit and at what precision a threshold
  is held — that difference MUST be recorded in each target's description, dated and sourced,
  and MUST NOT be closed by the format.
- A measurement taken at one vantage point MUST NOT stand in for one taken at another. A load
  generator measures latency as a client; a production stack usually measures it as a server.
  A gap is declared, never filled by the nearest available number.
- Should a component that turns measurements into verdicts ever return to scope, it MUST NOT
  know which target produced the measurements nor how they were obtained, and MUST NOT consume
  a statistic a target computed for itself. That obligation is dormant, not deleted: it binds
  the specification that revives the component, and binds nothing today.

**Rationale**: 1.1.0 placed this obligation on a component that was never built and cited a
proposal as its authority. Under an assertion-first format the obligation is vacuous — nothing
in scope produces a verdict — while reading, to anyone opening the file, as a prohibition on
the feature the project is now built around. Principle IV forbids a document reading as more
settled than it is; a rule that forbids nothing while appearing to forbid everything is the
same defect pointed inward.

What actually carries the portability claim is the document: the same file, unedited, reaching
a second target through a second description. That is checkable — two renderings, one file —
whereas the old claim was checkable only once a component existed that nobody had started. The
cost of the change is stated rather than hidden: two targets asserting one criterion do not
necessarily produce the same number, and no rule here can make them. The most the format can
honestly promise is that the *statement* is one statement, and that every place the targets
disagree is written down where a reader will find it.

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
- what a target's description may declare — the shape of the statements it makes about how a
  target names things, what it can and cannot assert, how its units convert, and where it can
  report success on absent data.

Binding constraints:

- A construct MUST NOT enter the format unless at least one surveyed target can assert it
  exactly. A construct is never admitted on the promise that something will be able to check
  it later. This is a floor and not a licence: one target being able to assert a construct is
  necessary for admission and is not by itself sufficient, and a construct MUST NOT enter the
  format solely to reach one target's feature.
- Requirement documents MUST remain portable. Neither the target that will assert a
  requirement nor the source of any measurement is part of the requirement — see
  Principle VI.
- Support for any target MUST be expressible as data — a description of that target — and not
  as code in a reference implementation. A target list that only maintainers can extend is not
  tool-agnostic. Only a target that can host assertions has a path in this format today; the
  monitoring-backend class named in 1.1.0 keeps no path in scope and is parked under
  Principle VIII.

**On the conformance levels.** `report`, `assert` and `abort` were cumulative rungs on a path
that ended in post-run evaluation, and the bottom rung — mapping metrics and attributes to
canonical names — guaranteed the whole format precisely because evaluation would do the rest.
With evaluation out of scope the bottom rung guarantees nothing anything can consume, so the
ladder is retired rather than edited. A tool that cannot host assertions is a tool this format
does not serve, and the difference between the tools that remain is not one ordinal: each has
capabilities the other lacks in both directions. What a target can assert, what it cannot, how
it names things, how its units convert and where it can pass on absent data are declared per
capability in that target's description, each claim dated and sourced. Aborting a run survives
as one such declared capability rather than as a rung.

Retiring the ladder changes a compatibility-sensitive surface and therefore requires an ADR of
its own, which supersedes ADR-0002 § D13 with a dated note rather than rewriting it. From this
amendment, **no new artifact may cite a conformance level**. Existing citations are not
retroactively invalid and are not to be edited out one by one: `ARCHITECTURE.md`,
`docs/GLOSSARY.md`, `LAYOUT.md` and `docs/adr/0002-compatibility.md` are corrected by the
pull requests this amendment already owes, and the `specs/` directory is a record of what was
decided when — it is read as history and left alone.

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

- MAJOR — a principle or a binding constraint is removed, or redefined in a way that permits
  what it previously forbade; or an item is removed from the list of
  compatibility-sensitive surfaces;
- MINOR — a principle or binding section is added, or existing guidance is materially
  expanded;
- PATCH — clarification, rewording, or a fix that changes no obligation.

Where one amendment carries material at more than one limb, the highest limb governs and the
document takes one version number.

A principle keeps its **number** when its heading changes, and a withdrawn number stays
withdrawn. Numbers are cited from the templates, from specifications and from
`ARCHITECTURE.md`; a reused number silently redirects every citation without touching a single
citing file.

**Compliance review**: `/speckit-plan` MUST evaluate its Constitution Check against the
eight principles above before Phase 0 research and again after Phase 1 design. PR review
MUST verify compliance; a violation is either fixed or the constitution is amended, but
never silently accepted. Complexity that appears to require a violation MUST be
justified in writing in the plan's Complexity Tracking section.

**Runtime guidance**: `AGENTS.md` for process, `docs/GLOSSARY.md` for vocabulary,
`docs/adr/` for why any of it is the way it is.

**Version**: 2.0.0 | **Ratified**: 2026-08-10 | **Last Amended**: 2026-08-21
