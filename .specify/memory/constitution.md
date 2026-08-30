<!--
SYNC IMPACT REPORT
==================
Version change: 3.0.0 -> 4.0.0

Bump rationale: MAJOR. Principle VI's second bullet is "redefined in a way that permits what it
previously forbade" — adding a target may now change one existing document, the one holding the
target descriptions, where the previous wording forbade changing any.

Travelling with other work: no. This amendment IS the work. Milestone v0.7.0 exists to make this
file stop contradicting the documents that follow it, and the pull request carrying it says so in
its first paragraph, as the amendment procedure requires.

What breaks without it: v0.5.0 consolidated the Gatling correspondence into README.md on the
argument of #68 — the tables existed twice and had drifted, with four issues closed a release
earlier live again in the copy on the page most readers meet. AGENTS.md states that consolidation
as settled architecture. Principle VI forbade it in terms, and Governance says that where the two
disagree this document wins and the other is wrong and MUST be fixed. Left alone, the repository
ships two normative documents that contradict each other, with the reconciliation filed in a
feature plan under a directory AGENTS.md itself reads as history (#83). Every milestone after this
one writes another target fact into the document Principle VI forbids changing.

Sections materially changed:
  - Principle VI — the second bullet becomes two. A target's DESCRIPTION is defined as what a
    renderer reads to turn a requirement document into that target's assertions; exactly one is
    required per target; a description MAY be a section of an existing document; and a gate
    implementing one is not a second one. Adding a target still may not change the format, the
    schema or the published corpus. The amendment record is appended to the principle, and it
    states that nothing checks the rule, because nothing does.
  - Compatibility Constraints — "nothing in this repository describes a target" was made false by
    v0.5.0 and is corrected. The list of compatibility-sensitive surfaces is unchanged at two
    items; restoring the third, what a target's description may declare, is recorded there as the
    rejected alternative rather than left undiscussed.

Owed and not settled here: nothing validates this file. Principle III's third clause — any artifact
nothing validates MUST say so in its own text — is unmet by this document, and that is why the
contradiction above stood through two releases. It is not one of milestone v0.7.0's issues and gets
its own, because the honest fix is an argument about what such a check could decide, not a sentence.

Numbers: no principle is removed. VII remains the only withdrawn number.

Templates and docs reviewed:
  ✅ .specify/templates/plan-template.md   — the VI gate and the version pointer follow
  ✅ .specify/templates/spec-template.md   — no change needed
  ✅ .specify/templates/tasks-template.md  — no change needed
  ✅ .specify/templates/checklist-template.md — no change needed
  ✅ AGENTS.md § Architecture — the departure parenthetical is removed; its rule stands unchanged
-->

# OpenNFR Constitution

## Core Principles

### I. Vocabulary Before Features (NON-NEGOTIABLE)

The vocabulary is the product. This repository ships terms, not code, and a term is
harder to withdraw than a feature.

- A new term MUST appear in `GLOSSARY.md` before it appears in an example, a
  schema, or an implementation.
- Every glossary entry MUST record at least one rejected alternative and the reason it
  was rejected. The rejection outlives the term it protects.
- Renaming a term MUST update `GLOSSARY.md` in the same change, and the entry MUST record
  what the old term got wrong. The argument for a rename lives in its issue.
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

Nothing may report success by omission.

- An unknown field in an input document MUST be a parse error, not an ignored key.
- Any check that cannot run MUST fail rather than skip, and any check that scanned nothing MUST
  say so. A suite that skips reads exactly like a suite that passes.
- Any artifact nothing validates MUST say so in its own text.

**Rationale**: this is the failure mode the entire format exists to address. A load test that
under-delivered its load shows green thresholds and a false verdict, and no surveyed format
catches it. A project built to fix that must not reproduce it.

3.0.0 cut this principle to three obligations, and the cut is the principle applied to itself.
The clauses removed governed rendering a document into a target's assertions, what a target's
description must declare, and where a target can pass on absent data — none of which any artifact
in this repository does or contains. An obligation on machinery nobody has built cannot be
broken, and a rule that cannot be broken reads, to anyone opening the file, as though the
guarantee were being enforced somewhere. What survives is the part this repository can actually
violate: a gate that skips, a check that scanned nothing, an artifact claiming a validation that
does not happen. All three have happened here.

### IV. Honest Status

- A document MUST NOT read as more settled than it is. Notes are labelled as notes.
- A construct's status MUST reflect reality. Nothing may be described as working, checked
  or supported until something in this repository demonstrates it.
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
- Any construct that would require custom decoding logic MUST be justified in the issue that
  proposes it, naming what it buys and what it costs.

**Rationale**: a grammar inside a specification has to be reimplemented, identically, in
every backend that reads it — and it never is. This is precisely where the string-DSL
string-DSL formats this project surveyed fail.

### VI. The Requirement Is Target-Blind

One document means one thing because the document — not the machinery under it — is the thing
that stays free of targets.

- A requirement document MUST NOT name a target: not in a field, a value, a metric name, or an
  example. It carries no per-target section, override or conditional.
- A target's **description** is what a renderer reads to turn a requirement document into that
  target's assertions. The correspondence between the document's vocabulary and a target's own
  MUST live there, and there MUST be exactly **one** description per target: a second copy is
  what drift is made of. A description MAY be a section of an existing document. A gate that
  implements a description is not a second description — it MAY name the reason a row gives,
  and MUST NOT carry a second copy of the rows.
- Adding a target MUST NOT change the format, the schema, or the published corpus, and MUST NOT
  change any existing document other than the one holding the target descriptions.
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

4.0.0 split the second bullet in two and rewrote what it forbids. It read "Adding a target MUST NOT
change the format, the schema, or any existing document", and by v0.5.0 the repository was doing the
opposite on purpose: #68 found the Gatling correspondence stated in two places and drifted, with four
issues closed a release earlier live again in the copy on the page most readers meet. One home was
the fix, and `README.md` was chosen as that home — which made adding a second target a change to an
existing document, which this bullet forbade in terms. The departure was declared in a feature plan,
under a directory `AGENTS.md` reads as history and nowhere a contributor looks for rules, so the
repository shipped two contradicting normative documents for two releases (#83).

What was wrong was the unit, not the rule. The property a separate file bought was not separateness;
it was that there is one place to look, and the drift #68 fixed was two copies disagreeing. The
bullet now requires that property directly, and defines what has to be singular before requiring it.
The definition earns its keep rather than decorating the rule: without it the clause would forbid
every statement about a target outside a description, and this repository would violate it in four
places, two of them deliberately — a sentence naming what three load generators each call a request,
which is the argument for the field existing at all, and a gate comment giving the reason one of its
own rows gives, which v0.6.0 required. A renderer reads neither, so neither is a description, and the
rule reaches what it was written for. Nor does `specs/` count: it is read as history, not as
documentation, and Principle VIII says so where that reading is enforced.

Nothing checks any of this. `scripts/verify.sh` does not read this file, which is why the
contradiction stood through two releases, and "is this sentence a target description" is not a
question a script decides. The bullet is enforced in review or not at all, and says so here rather
than reading as though a gate were watching — which is Principle IV pointed at this principle.

### VII. *(withdrawn in 3.0.0)*

**Architecture Before Implementation** bound every change to name the architectural role it
filled and to amend `ARCHITECTURE.md` before diverging from it. That document is deleted: it
described four component roles of which none was built, and a path from requirement to outcome
that 2.0.0 had already put out of scope. Its own § 1 carried a superseded marker instructing
readers not to apply it.

The number stays withdrawn and is not reused. Numbers are cited from the templates and from
specifications, and a reused number silently redirects every citation without touching a citing
file.

### VIII. Ideas Are Parked, Not Merged

Unsettled work is contained, and the containment is checkable rather than declared.

- `docs/` holds **ideas and nothing else**: constructs the format does not have, each to be
  built, reworked or dropped. Documentation of what the format *is* MUST NOT live there.
- **Nothing outside `docs/` may link into it.** An outside reference names a path in prose,
  inside a code span, never as markdown link syntax. Links out of `docs/` into the format are
  permitted and expected — an argument about a construct has to name what it would change.
- Every idea MUST state what would have to become true before it could enter the format.
- `scripts/verify.sh` MUST fail on any markdown link crossing the boundary the wrong way, and
  `git rm -r docs && bash scripts/verify.sh` MUST stay green. `specs/` is exempt: it is read as
  history, not as documentation.

**Rationale**: the failure this prevents is "it mostly works, call it v1". A notice on something
load-bearing is not containment, which is why the boundary is a gate and not a convention.

The property bought is one you can run: every idea can be dropped in a single operation without
breaking a real document. An idea nobody can cheaply abandon is an idea that gets kept for the
wrong reasons.

3.0.0 dropped the separate experimental area and the two artifacts grandfathered in 1.1.0. Both
are deleted by the work this amendment travels with, and `docs/` is now what that area was.

## Compatibility Constraints

Compatibility-sensitive surfaces, which MUST NOT change without an issue that argued the change,
and a `GLOSSARY.md` entry recording the alternative that was rejected:

- any OpenTelemetry name the format borrows;
- any field name that appears in a published example.

3.0.0 replaced "MUST NOT change without an ADR" with the sentence above. The decision records are
deleted with `reference/`, and a requirement to record a decision in a directory that does not
exist is not a requirement. Both instruments that replace it already existed under Principle I:
a naming disagreement is argued in an issue before files change, and every glossary entry carries
a rejected alternative. The third surface, what a target's description may declare, was removed in
3.0.0, when nothing in this repository described a target. One does now: `README.md` § *What any tool
can actually run*, added in v0.5.0. The surface is **not** restored, and that is a decision rather
than an oversight — restoring it would put an argued issue and a `GLOSSARY.md` entry recording a
rejected alternative behind every edit to a reach row, and `GLOSSARY.md` is the vocabulary document,
where a rejected table row does not belong. Reach rows change through the ordinary issue and
milestone rules, as four of them did in v0.6.0.

Binding constraints:

- A construct MUST NOT enter the format unless at least one surveyed target can assert it
  exactly. A construct is never admitted on the promise that something will be able to check it
  later. This is a floor and not a licence: one target being able to assert a construct is
  necessary for admission and is not by itself sufficient, and a construct MUST NOT enter the
  format solely to reach one target's feature.
- **The published corpus MAY be narrower than the format, and the format MUST NOT be narrowed to
  match it.** Examples are restricted to what a real target can run, because an example nothing
  can execute teaches a shape nobody can use. The schema keeps what no target reaches, and the
  field description says which parts those are.
- Requirement documents MUST remain portable. Neither the target that will assert a requirement
  nor the source of any measurement is part of the requirement — see Principle VI.
- Support for any target MUST be expressible as data — a description of that target — and not as
  code in a reference implementation. A target list that only maintainers can extend is not
  tool-agnostic.

## Development Workflow

`AGENTS.md` is the operative process guide; it is not restated here. The constitution
adds only the constraints that outrank convenience:

- `bash scripts/verify.sh` MUST pass on every commit. A change that requires weakening
  the gate MUST justify it in the PR, not in the script.
- Every change MUST travel through an issue, a branch, and a PR carrying a milestone and
  a closing link, as enforced by `scripts/check-linkage.sh`.
- A PR that changes a term MUST update `GLOSSARY.md` in the same PR. Vocabulary
  drift between a change and its documentation is not acceptable, however brief.
- A PR that contradicts a decision recorded in `GLOSSARY.md` MUST amend that entry instead.

## Governance

This constitution supersedes other practices in this repository. Where it and any other
document conflict, this document wins and the other document is wrong and MUST be fixed.

**Amendment procedure**: an amendment PR MUST state which principle is added, altered or
removed, and why the current wording fails. It follows the same issue/milestone/linkage
rules as every other change.

An amendment MAY travel with the work that motivated it. The earlier rule — this file and
its templates "and nothing else" — was written to stop an amendment being smuggled through
inside unrelated work, and it did that; but it also forbade the only PR that can show a
principle is wrong, which is the one that hits the wall. A rule whose sanctioned route is
more expensive than the workaround is not a route.

What replaces it is a disclosure rule rather than a size rule: where an amendment ships
with other changes, the PR MUST say so in its first paragraph, and MUST show what breaks
without it. An amendment a reviewer has to find by reading a diff is smuggled however small
the diff is.

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
withdrawn — VII is withdrawn as of 3.0.0. Numbers are cited from the templates and from
specifications; a reused number silently redirects every citation without touching a single
citing file.

**Compliance review**: `/speckit-plan` MUST evaluate its Constitution Check against the
seven principles above before Phase 0 research and again after Phase 1 design. PR review
MUST verify compliance; a violation is either fixed or the constitution is amended, but
never silently accepted. Complexity that appears to require a violation MUST be
justified in writing in the plan's Complexity Tracking section.

**Runtime guidance**: `AGENTS.md` for process, `GLOSSARY.md` for vocabulary, `README.md` for
the format itself.

**Version**: 4.0.0 | **Ratified**: 2026-08-10 | **Last Amended**: 2026-08-30
