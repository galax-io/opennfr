# Implementation Plan: Strip the repository to the schema, the examples and the fields

**Branch**: `004-strip-to-schema` | **Date**: 2026-08-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-strip-to-schema/spec.md`

## Summary

Delete `ARCHITECTURE.md` and `LAYOUT.md`; merge the two documents that each half-describe the
fields into one; replace a corpus in which eight of twelve predicates cannot be run by any
available tool; and disperse `reference/` and the four files under `docs/` into the four documents
that remain. The schema is not touched.

The approach is a **document inventory with no blanks**: every current file has a row saying where
what it carried has gone, and every rule that lived in only one place is either moved or dropped
by name. The bar is not "less prose" — OpenSLO specifies seven object types in 57 KB, and its
README alone is larger than this repository's. The bar is that every page describes something
that exists, which today 66.6 KB of this repository does not.

## Technical Context

**Language/Version**: None. Markdown, YAML and one JSON Schema (Draft 2020-12).

**Primary Dependencies**: `python3` with `pyyaml` and `jsonschema`, used only by the gate.

**Storage**: N/A — files in git.

**Testing**: `bash scripts/verify.sh`, plus the predicate-by-predicate corpus check in
[quickstart.md](quickstart.md) § 2.

**Target Platform**: A git repository read by humans and, eventually, by tool adapters living
elsewhere.

**Project Type**: Format specification. One artifact (the schema), one specification document, a
validated corpus.

**Performance Goals**: N/A.

**Constraints**: The schema does not change (FR-014) — no document valid today may become invalid.
The published corpus must be wholly assertable by Gatling v3.15.1, per
[contracts/gatling-reach.md](contracts/gatling-reach.md). The gate must stay green at every commit,
and `rm -rf docs && bash scripts/verify.sh` must stay green after.

**Scale/Scope**: 29 markdown files to 5. 196 KB of prose to roughly 60 KB, of which ~2 KB describes
something other than the format. 12 corpus predicates to about 10, all runnable.

## Constitution Check

*Evaluated against `.specify/memory/constitution.md` v2.1.0, which this feature amends to 3.0.0.*

- [x] **I. Vocabulary Before Features** — no term is introduced or renamed. Terms *move*:
      `reference/glossary.md` → `GLOSSARY.md`, reduced to definitions and rejected alternatives.
      Every entry keeps its rejection line. Nothing in the schema changes, so no ADR is
      contradicted — and the three ADRs are dropped, which is why research R5 replaces the ADR
      requirement rather than leaving it dangling.
- [x] **II. Borrow Names, Never Invent Them** — no name is coined. The one borrowed-name question
      this touches is made *more* honest: FR-018 requires `README.md` to state that
      `loadtest.request.name` and `loadtest.group.name` are not OpenTelemetry names and that after
      FR-011 the corpus depends on them. Today that debt is recorded in `reference/names.md`, a
      file being deleted.
- [x] **III. No Silent Green** — the sharpest gate here, and it points at this feature's own work.
      A section of `scripts/verify.sh` whose input disappears must be **deleted with its input**,
      not left to pass on an empty scan: `contracts/verify-sections.md` names the one section that
      applies to (§ 8, sketch labels) and confirms the other six still scan something. Issue #37 —
      the self-check whose probes pass vacuously — is recorded as **inherited and not fixed here**,
      so a green gate is not mistaken for a checked one.
- [x] **IV. Honest Status** — the only external claim this feature makes is what Gatling can
      assert, and it is dated 2026-08-20 and sourced to four named files of Gatling v3.15.1
      ([contracts/gatling-reach.md](contracts/gatling-reach.md)). The comparison with OpenSLO in
      the spec is dated 2026-08-22. Deleting a document does not delete the argument it carried:
      FR-020 requires each removal to say what it was for.
- [x] **V. Structure Over Grammar** — no field is added; nothing needs decoding.
- [x] **VI. The Requirement Is Target-Blind** — the load-bearing check of this feature.
      **Restricting the corpus is not restricting the format.** The schema keeps `http.route`,
      `sum` and `neq`, and FR-014 makes that explicit. No requirement document names Gatling in a
      field, a value or a metric name; what names Gatling is `README.md`, saying which parts of
      the format nothing available can currently run — which is the vantage-point honesty this
      principle asks for, not a violation of it.
- [ ] **VII. Architecture Before Implementation** — **removed by this feature** (FR-019). It binds
      every change to name an architectural role and to amend `ARCHITECTURE.md` first; this change
      deletes that document. Justified in Complexity Tracking below.
- [x] **VIII. Experiments Are Parked, Not Merged** — `docs/` becomes the parked area entire, one
      file. The property is kept and stays checkable: nothing outside links in, and
      `rm -rf docs && bash scripts/verify.sh` stays green (quickstart § 3). The grandfather clause
      goes with the two artifacts it named — one is deleted, the other split between `README.md`
      and `docs/ideas.md`.
- [x] **Compatibility** — no construct is added, so the admission floor does not apply. Two of the
      three compatibility-sensitive surfaces are touched only in where they are documented, not in
      what they say: no borrowed OpenTelemetry name changes meaning, and no field name changes. The
      third surface — what a target description may declare — **ceases to exist**, because nothing
      in the repository describes a target after this. Nothing this feature adds cites a
      conformance level; the documents that carried old citations are deleted or rewritten, which
      closes #36 by removal rather than by argument.

**Gate result: passes with one removal, justified below.** The removal is the feature.

## Project Structure

### Documentation (this feature)

```text
specs/004-strip-to-schema/
├── spec.md                        the requirement
├── plan.md                        this file
├── research.md                    Phase 0 — six questions, six decisions
├── data-model.md                  Phase 1 — every current file, and where what it carried went
├── quickstart.md                  Phase 1 — how to check the result, command by command
├── contracts/
│   ├── gatling-reach.md           what Gatling can assert — the bar FR-010 tests against
│   └── verify-sections.md         what each gate section checks after the cut
└── checklists/requirements.md
```

### Repository (after the change)

```text
README.md                                      the specification: what the format is, every field,
                                               per-field notes, and what Gatling can reach
GLOSSARY.md                                    terms, definitions, rejected alternatives
CONTRIBUTING.md                                how to propose a change
LICENSE
schema/opennfr.io/v1/requirementset.schema.json
examples/one-request-is-fast.yaml
examples/fast-and-reliable.yaml
examples/the-run-held-up.yaml
docs/ideas.md                                  everything considered and left out
scripts/verify.sh
scripts/check-linkage.sh
```

Deleted: `ARCHITECTURE.md`, `LAYOUT.md`, `schema/README.md`, all of `reference/`, all of `docs/`
except the new `ideas.md`, both current examples. Reduced: `AGENTS.md`, the constitution, the
plan template, the GitHub templates.

**Structure Decision**: Flat. Six entries a reader has to consider, matching the shape checked
against `github.com/OpenSLO/OpenSLO` on 2026-08-22: one document that *is* the specification, a
small glossary, an ideas file, examples as cases, and a contributing note. The one place this
repository stays ahead is that the schema is here rather than in a separate SDK.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| **Principle VII removed** — every change must name an architectural role and amend the architecture first | The principle binds against `ARCHITECTURE.md`, which this feature deletes as its primary purpose. Left standing it would be the third rule in three changes that points at a file that is gone: Principle I pointed at a moved glossary, and the principle's own § 1 clause 3 already carries a superseded marker instructing readers not to apply it | *Keep VII and keep a smaller `ARCHITECTURE.md`* — rejected: the document describes four component roles, none built, and a path from requirement to outcome that constitution 2.0.0 put out of scope. A smaller version of a document about nothing is a smaller document about nothing. *Rewrite VII to bind against the schema* — rejected: the schema is not an architecture, and a principle renamed to survive its subject is how the repository got a superseded clause it was told to ignore |
| **MAJOR constitution bump to 3.0.0** | A principle is removed and a binding constraint — "MUST NOT change without an ADR" — is redefined to permit what it forbade (research R5). The constitution's own versioning policy makes either one MAJOR | *PATCH, as paths-only* — rejected: it is not paths-only, and the last amendment (2.1.0) already established that an amendment travelling with its motivating work must disclose exactly what it changes |
| **The published corpus is narrowed to one tool** | An example nothing can run teaches a shape nobody can use. Gatling is the only target with a waiting counterparty, and eight of twelve current predicates fail on it | *Keep unrunnable examples and label them* — rejected: a labelled example still teaches the shape, which is User Story 2's whole complaint. *Narrow the schema to match Gatling* — rejected outright by FR-014 and Principle VI: the format is not one tool's feature set |

## Constitution re-check, after Phase 1

Re-evaluated against the design rather than against the intention. Two gates moved.

**III. No Silent Green — strengthened by the design, and by an accident.** Writing
`contracts/verify-sections.md` forced a section-by-section pass over the gate and turned up
something the specification had not: section 8 does not merely become redundant, it **fails** on
an absent `docs/examples/`, because its empty-glob guard cannot tell a dropped directory from a
broken pattern. Deleting the section with its input is now a named task rather than a
consequence someone would meet at the end.

Separately, `quickstart.md` § 3 tripped the link checker twice while being written: the probe
command it documents contains literal markdown link syntax, which the gate's extractor reads as a
real link. That is issue #43, unfixed, and this is the second workaround written for it in two
features. Recorded in the Risks table rather than fixed here — but two workarounds is the point at
which the issue stops being cosmetic.

**VI. The Requirement Is Target-Blind — verified rather than asserted.** The corpus check in
quickstart § 2 was run against the current tree during planning. It prints eight `UNRUNNABLE`
lines, all `http.route`, matching research R2 exactly. The check reads only the corpus and the
capability contract; it never reads the schema, which is what makes "the corpus narrows, the
format does not" a checkable claim rather than a promise.

No other gate changed. **VII stays removed**, justified in Complexity Tracking.

## Phase progress

- [x] Phase 0 — [research.md](research.md): R1 the Gatling record's home, R2 what the corpus
      fails, R3 what replaces it, R4 which arguments are load-bearing, R5 what replaces the ADR
      requirement, R6 what happens to the gate.
- [x] Phase 1 — [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md).
- [ ] Phase 2 — `tasks.md`, by `/speckit-tasks`.

## Risks

| | |
|---|---|
| **A rule is lost in the deletion.** 66.6 KB goes, and some of it is load-bearing | The disposition table in `data-model.md` has a row per file and no blanks; SC-007 is a review against it. The three rules `LAYOUT.md` alone carried are named there with destinations |
| **The corpus check is done by eye and drifts** | quickstart § 2 is a runnable script applying `contracts/gatling-reach.md`. It should be run before the change as well, where it prints the eight failures being fixed |
| **The gate goes green having checked nothing** | `contracts/verify-sections.md` states, per section, what it scans afterwards. § 8 is deleted with its input rather than allowed to pass empty |
| **The next tool cannot be added because the corpus is Gatling-shaped** | FR-014 and Principle VI: the *schema* keeps `http.route`, `sum` and `neq`. What narrows is what is published, and `README.md` says which parts nothing can currently run |
| **`.copier-answers.yml` regenerates `AGENTS.md` against a two-cuts-old tree** | Out of scope, issue #46, and now worse. Recorded rather than silently accepted |
