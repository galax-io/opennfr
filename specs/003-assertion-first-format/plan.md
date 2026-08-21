# Implementation Plan: An Assertion-First Requirement Format

**Branch**: `003-assertion-first-format` | **Date**: 2026-08-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-assertion-first-format/spec.md`

## Summary

The format stops being the input to an evaluation engine this project has not built and becomes the
input to the load tool's own assertions. Concretely, this feature delivers four things and blocks on
three amendments it may not make itself.

**Delivers**

1. One change to the container, and it is additive: an optional **display name** on the document,
   each requirement and each predicate (FR-007) — free human text beside the machine identifier,
   inert by construction. A precondition is identified through the rendering rather than through the
   target's report (FR-009).
2. Two new document kinds: the **target description** in `mappings/` — what a target names things,
   what it can and cannot assert, how units convert — and the **rendering**, the expected native
   assertions plus the named list of criteria that could not be produced.
3. A **conformance corpus** in `conformance/`, in three parts: documents that must be rejected and
   where, rendering triples any implementation must reproduce, and mutations of the gate itself that
   must turn the build red.
4. A **sequenced deletion sweep** of `docs/`, of which only Tier 0 is inside this feature.

**Blocks on** three amendments that must land in earlier pull requests, per Principle VII: two to the
constitution and one to `ARCHITECTURE.md`. They are not optional and they are not this feature's to
make in passing — see [Constitution Check](#constitution-check).

**Approach.** The container already fits Gatling's assertion surface almost exactly (spec Appendix
A), so the work is not a redesign. It is: two small format changes, two new schemas, a corpus that
makes every claim falsifiable, and a documentation sweep whose ordering matters more than its
content.

## Technical Context

**Language/Version**: None. This repository ships JSON Schema and Markdown; it has no product code
and this feature adds none. Python 3 is the gate's tooling, not the deliverable.

**Primary Dependencies**: JSON Schema draft 2020-12 (the format's definition); OpenTelemetry
semantic conventions (borrowed names, never invented — Principle II); PyYAML and `jsonschema` for
`scripts/verify.sh`. No new dependency is introduced — both are already required and already
installed by CI.

**Storage**: N/A. Files in a git repository.

**Testing**: `bash scripts/verify.sh` is the gate (AGENTS.md, and the constitution's Development
Workflow). This feature extends it with the conformance corpus and requires that every check it
performs be provably able to fail (FR-034).

**Target Platform**: N/A for the format. **Non-trivial for the gate**: it must behave identically on
macOS (BSD userland) and Linux (GNU userland). Spec Appendix B records four places where it did not
— one of which had never executed on macOS — all repaired on `main` while this feature was being
specified. The lesson survives the repair: none was caught by a test.

**Project Type**: Specification and schema repository. Not a library, service, or application.

**Performance Goals**: N/A.

**Constraints**:

- The container stays one file and small. Feature 002 set the bar at under 6 KB; two added fields
  must not become an excuse to relax it.
- Unknown fields are rejected everywhere (FR-006).
- **FR-020 is the admission gate for every construct below**: nothing enters the format unless at
  least one surveyed target can assert it *exactly*. This is the constraint that shapes the design,
  and it is also the one that contradicts the constitution as currently written.
- At most three new glossary terms for the whole feature (SC-011), and all three are committed: the
  display name, the target description, the unrenderable criterion. A fourth entry, *rendering*, is
  owed but is not a fourth concept — it names the output of an act already called *render*.

**Scale/Scope**: 42 functional requirements, 19 success criteria, 5 user stories. Two targets
(Gatling, k6). Roughly 80 corpus cases across the three parts. Seventeen files in `docs/` audited;
four deletion tiers.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against `.specify/memory/constitution.md` v1.1.0.

- [x] **I. Vocabulary Before Features** — three terms are introduced and all three are recorded as
      owed by FR-042, each requiring a rejected alternative before it reaches the schema or an
      example. The Development Workflow's rule that a PR changing a term updates `docs/GLOSSARY.md`
      in the same PR is what FR-042 discharges. **One live tension**: the glossary's `Assertion`
      entry argues the word must stay out of the document, calling it "the single strongest
      constraint". This feature upholds it — no target syntax enters a requirement document
      (FR-001, SC-004) — but the entry needs the FR-020 tension recorded as an argument, not
      silently left to contradict it.
- [x] **II. Borrow Names, Never Invent Them** — no metric or attribute name is invented. **One
      declared cost**: hierarchical addressing (FR-008) rests on `loadtest.group.name`, which lives
      in `docs/semconv/loadtest.md` — an unsubmitted upstream proposal that Principle VIII
      grandfathers *with the explicit warning that it may not be cited as precedent for admitting
      new unsettled work*. This feature does not admit new unsettled names; it depends on an
      existing grandfathered one. That dependency is stated in the spec rather than hidden, and it
      is a reason the addressing question is not fully closed.
- [ ] **III. No Silent Green** — **FAILS as written, and the failure is the point.** The principle's
      spirit is upheld and does most of the work in this feature: FR-010 through FR-013 make every
      criterion either rendered or named, FR-024 forbids success by omission at render time, and
      FR-034 through FR-036 turn the same rule on the project's own gate. But its *letter* mandates
      that a run which did not meet its assumed conditions "MUST be reported as inconclusive", and
      decision D1 removes that outcome because no surveyed target has one. **Prerequisite amendment
      A.**
- [x] **IV. Honest Status** — Appendix A is dated and sourced to Gatling's own source; Appendix B was
      confirmed by hand against `scripts/verify.sh`; Appendix C states what the corpus will not
      establish. FR-026 and SC-007 carry the obligation into every target description.
- [ ] **V. Structure Over Grammar** — *deferred to the post-design re-check.* Two new document kinds
      are the largest surface this project has added at once, and the question "can every field be
      validated by JSON Schema with no bespoke parser and no open grammar" cannot be answered before
      the design exists. Recorded here as open rather than assumed.
- [ ] **VI. Evaluation Is Target-Blind** — **requires settlement, and possibly removal.** The
      principle forbids consuming "a statistic a target computed for itself" as a verdict. Under an
      assertion-first format the target computes everything and decides. The principle is not
      *violated*, because nothing in scope produces a verdict — but a principle that is vacuous
      rather than satisfied is a trap for the next reader. Note that removal, or redefinition that
      permits what it previously forbade, is **MAJOR** under the constitution's own versioning
      policy. **Prerequisite amendment B.**
- [ ] **VII. Architecture Before Implementation** — **fails until `ARCHITECTURE.md` is amended.** It
      binds four component roles and a follow-up plan built on post-run evaluation; this feature
      keeps R1 and R2 and takes R3 and R4 out of scope. Principle VII requires the architecture to be
      amended in an **earlier** pull request, never diverged from silently. **Prerequisite
      amendment C.**
- [x] **VIII. Experiments Are Parked, Not Merged** — FR-041 requires a parked construct to arrive in
      the experimental area carrying its argument, its rejected alternatives and a date, which is
      what VIII demands. **One structural problem found:** `docs/experimental/` is **markdown only**
      by LAYOUT.md, so `docs/examples/checkout-perf.report.yaml` — a result-document sketch that
      FR-018 settles — has nowhere compliant to be parked. It is deleted with its argument carried
      into a markdown note, or the layout is amended. Resolved in Phase 0.
- [ ] **Compatibility** — **fails on two counts, both requiring more than an amendment.** First, the
      binding constraint *"The format MUST NOT contain a construct expressible only at conformance
      level `assert` or above"* is exactly what FR-020 inverts. Second, *"the conformance levels and
      what each one guarantees"* is listed as a **compatibility-sensitive surface, which MUST NOT
      change without an ADR** — and with post-run evaluation out of scope, `report` is no longer a
      level at all. So this feature needs a constitution amendment **and** an ADR amending ADR-0002
      § D13. **Prerequisite amendment B (constitution) plus a decision record.**

### Gate result

**Four gates do not pass**, and three of the four are the same three prerequisites the specification
already named. They are recorded in Complexity Tracking below rather than treated as blockers to
planning, because Principle VII's remedy is explicit: amend first, in an earlier pull request. This
plan's Phase 0 writes those amendments; it does not land them.

Principle V is deliberately left open until the post-design re-check.

## Project Structure

### Documentation (this feature)

```text
specs/003-assertion-first-format/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source (repository root)

```text
schema/opennfr.io/v1/
├── requirementset.schema.json     EDITED — the scope distinction (FR-007),
│                                  precondition identity (FR-009)
├── targetdescription.schema.json  NEW — what a target can and cannot assert
└── rendering.schema.json          NEW — expected assertions + named unrenderables

mappings/                          NEW directory, name already reserved by LAYOUT.md § 1
├── gatling.yaml
└── k6.yaml

conformance/                       NEW directory, name already reserved by LAYOUT.md § 1
├── README.md                      what the corpus binds, and what it does NOT establish (FR-037)
├── parse/                         documents that must be accepted / rejected, and where
├── render/                        (document, target description, rendering) triples
└── gate/                          mutations of scripts/verify.sh that must turn the build red

examples/                          the six worked statements (FR-023)
scripts/verify.sh                  EDITED — corpus sections; every check provably able to fail
```

**Structure Decision.** No new artifact class is invented. `LAYOUT.md` § 1 already reserves
`mappings/` ("Tool mappings … once it exists") and `conformance/` ("Conformance corpus … once it
exists, binds later work: **Yes**"); both rows simply lose the words "once it exists". Choosing
`mappings/` over a new `targets/` directory costs one incumbent name — the existing `MetricMapping`
kind — and saves a LAYOUT.md amendment plus a fourth glossary term the budget cannot afford.

`LAYOUT.md` § 6 already records the trap this creates and it must be honoured in the same change:
*"`verify.sh`'s sketch-label check is hardcoded to `docs/examples/*.yaml`. A mapping relocated to
`mappings/` silently stops being checked until the script is extended."* That is a fifth silent-green
site waiting to happen, and FR-034 exists to catch exactly it.

## Constitution Check — post-design re-evaluation

Re-run after Phase 1, as the constitution's Compliance review requires. Only what changed is
restated.

- [x] **V. Structure Over Grammar** — **now passes**, deferred at the pre-design check. Every field
      in all three kinds is validatable by JSON Schema draft 2020-12 with closed enumerations and no
      bespoke parser. Three specifics were the risk and each is resolved:
      - the pinned native literal is a string with **no `pattern`**, and nothing decodes it — it is
        dated evidence, never an input. A pattern would have been the first line of a decoder;
      - unit conversion is integer numerator/denominator pairs, so exact representability is decided
        by arithmetic rather than by a float comparison;
      - the checks JSON Schema genuinely cannot express — identity uniqueness across two arrays, the
        sum rule, conversion, gap traceability — are corpus-runner checks over *two* documents, not
        grammar inside one. The format still decodes without custom code.

      **One borderline call, recorded rather than buried**: `native.fields` is declared per target
      description, so the meaning of an assertion's `parts` array is file-dependent. It is a declared
      ordered enumeration validated by schema, not a grammar — but it is the closest this design
      comes to one, and it exists so that a third target with an unanticipated assertion shape needs
      no schema edit (FR-016).

- [ ] **III / VI / VII / Compatibility** — still fail, unchanged in substance, but the amendments now
      exist as **written text** rather than as an intention. See [research.md § R10](research.md).
      The constitution goes **1.1.0 → 2.0.0 (MAJOR)** under its own versioning policy — three
      principles are redefined in a way that permits what they previously forbade — plus a PATCH limb
      correction so the stamp can be applied honestly. `ARCHITECTURE.md` takes six section amendments.

- [x] **I. Vocabulary** — **settled during Phase 0.** Three concepts, plus a fourth glossary entry
      that is not a fourth concept: *rendering* names the artifact of an act already called *render*
      in the glossary's own diagram, in `ARCHITECTURE.md`'s R2 and in the spec's Key Entities. SC-011
      now says this explicitly, and the entry must record the judgement rather than let a later
      reader assume it.

- [x] **III, applied to the feature's own output** — worth stating separately from the amendment. The
      design makes success-by-omission **unspellable**: one entry per predicate in one ordered list,
      exactly one of two buckets per entry, `minItems: 1` on both. There is no way to write a
      rendering in which a predicate quietly disappears. That is stronger than checking for it
      afterwards.

### One thing the design cannot deliver, found in Phase 0

A per-request assertion that matches nothing **exits successfully** on one surveyed target — zero
results, no failure. It is a silent green inside the tool, after the rendering is finished, and
nothing in this feature can reach it. It is declared in the specification, in the target description
and in the corpus as a known limitation, which is the only honest response available. Recorded here
because a Constitution Check reporting Principle III as satisfied without naming this would be the
kind of quiet pass the principle forbids.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| **Principle III's letter** — `inconclusive` ceases to be a mandated outcome | No surveyed target has a third outcome. Mandating one forces every rendering either to fabricate it or to drop preconditions entirely | *Keep `inconclusive` and make preconditions unrenderable everywhere* — a construct whose only behaviour is to be reported unsupported. *Drop preconditions* — abandons the under-delivered-load failure mode this project was founded on |
| **Principle VI** — may need narrowing or removal | Nothing in scope produces a verdict, so the principle is vacuous rather than satisfied. A vacuous principle reads as a live constraint to the next person | *Leave it alone* — the spec's own Dependencies table already warns that "the ambiguity must be settled before this ships, not discovered afterwards". Silence is the expensive option |
| **The Compatibility constraint** — inverted by FR-020 | With `report` no longer a complete path, the old rule forbids exactly what the feature exists to do | *Keep both rules* — the repository would formally forbid what it requires. This is not a trade-off, it is a contradiction |
| **Two new document kinds at once** | The target description and the rendering are useless separately: a description nothing consumes proves nothing, and a rendering without a description has no oracle | *Ship the target description first* — leaves FR-010's sum rule, the feature's central honesty claim, untested for a whole release |
| **`checkout-perf.report.yaml` has nowhere compliant to be parked** | `docs/experimental/` is markdown-only by LAYOUT.md; the sketch is YAML | **Resolved in Phase 0 (R7)**: delete the YAML, move its argument into a markdown parked note. Amending LAYOUT.md to admit YAML was rejected — weakening a containment rule to preserve one unvalidated file is a bad trade |
| **The target description does not scale** | Roughly 330 lines for a target with one metric family; rows grow as *metrics × path-kinds* | **No alternative found.** Twenty metrics is thousands of lines nobody hand-authors correctly, and generating it makes the file's honesty a generator's honesty — code, which is what FR-016 pushed out of this repository. The first two descriptions are deliberately narrow, and this is why |
| **The corpus cannot falsify itself** | Nothing here renders, so every check is a consistency check between files written here | *Ship a reference renderer* — rejected by the spec: rendering lives where the target lives. The corpus is an oracle and says so in its own text (FR-037) |

---

## Artifacts

| Phase | Artifact | What it settles |
|---|---|---|
| 0 | [research.md](research.md) | Ten research items. **Three contradicted the specification**, which has been amended |
| 1 | [data-model.md](data-model.md) | Three document kinds, the corpus, and what no schema can check |
| 1 | [contracts/document-kinds.md](contracts/document-kinds.md) | What a consumer anywhere MUST and MUST NOT do |
| 1 | [contracts/corpus-runner.md](contracts/corpus-runner.md) | Exit contract, ten check codes, the mutation suite |
| 1 | [quickstart.md](quickstart.md) | Seven runnable scenarios, each mapped to a success criterion |

### What Phase 0 changed in the specification

Recorded here because a plan that quietly repairs its own spec is not reviewable.

| Finding | Spec change |
|---|---|
| No surveyed target can carry an author-chosen name into its report — verified in source | FR-009 and SC-012 restated; decision **D1 revised**, its original rationale withdrawn as factually wrong; Appendix D added |
| The per-request scope ranges over every request *observed*, not over a selection, exists on one target of two, and passes silently on an empty match | **D2 withdrawn** on review: FR-020's own second half forbids admitting a construct solely to reach one target's feature. FR-007's slot now carries the display name; Appendix A's scope row corrected |
| One criterion may legitimately produce several assertions, and one assertion may expand at run time | **FR-033 restated**: predicate → exactly one *bucket*, not one assertion |
| *Rendering* is a fourth glossary entry but not a fourth concept | SC-011 restated to say so, and to require the entry to record the judgement |

*Phase 2 (`tasks.md`) is produced by `/speckit-tasks`, not by this command.*
