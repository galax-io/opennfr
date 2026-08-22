---
description: "Task list for 003-assertion-first-format"
---

# Tasks: An Assertion-First Requirement Format

**Input**: Design documents from `/specs/003-assertion-first-format/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/)

**Tests**: **Required, and they are a user story of their own.** FR-028 through FR-037 and User
Story 5 make the corpus part of the deliverable, not an optional extra. Every phase below that
publishes a document also publishes what proves it.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelisable — different files, no dependency on an incomplete task
- **[Story]**: which user story the task serves (US1–US5)
- Every task names the exact file it touches

## Path conventions

This repository ships JSON Schema and Markdown, no product code. Paths are repository-relative:
`schema/opennfr.io/v1/`, `mappings/`, `conformance/`, `examples/`, `docs/`, `scripts/`.

## Rules that bind every task below

Taken from `AGENTS.md` and the constitution, restated because they change how the work is cut:

- **One concern per PR**, and **one issue → one semantic commit**, each carrying a milestone and a
  closing link. `scripts/check-linkage.sh` gates this in CI.
- **`bash scripts/verify.sh` must pass on every commit.** A task that would leave it red is split.
- **A term reaches `docs/GLOSSARY.md`, with a rejected alternative, before it appears in a schema or
  an example.** This is why Phase 2 puts vocabulary ahead of schema.
- **A published example is a compatibility-sensitive surface.** Any field name in one needs an ADR
  to change later, so the first document published fixes the vocabulary in place.

---

## Phase 0: Prerequisite amendments — NOT THIS FEATURE'S PRs

**Purpose**: Principle VII requires the architecture and the constitution to be amended in **earlier**
pull requests, never diverged from silently. Nothing in Phase 2 onward may merge until these land.

**⚠️ Eleven amendments, landing as three pull requests.** They are listed here because they block
everything, not because this feature performs them. The written text for each is in
[research.md § R10](research.md).

| PR | Covers | Why it cannot be split further |
|---|---|---|
| Constitution → **2.0.0** | T001–T004 | Its own amendment procedure: a PR that changes "this file and any templates the change affects, **and nothing else**". One version stamp |
| `ARCHITECTURE.md` | T005 | § 4 clause 11 is the fourth copy of the rule § 1 clause 3 retires; separating them moves the stale rule |
| ADR-0002 § D13 | T006 | The conformance levels are a compatibility-sensitive surface; only an ADR may re-derive them |

**Two of these block the specification itself, not a later task.** Principle VI and
`ARCHITECTURE.md` § 1 are what make this feature formally permitted, and Principle VII requires the
architecture amended "first, in an earlier pull request". The specification was opened for review
ahead of both. The conservative reading is that PR #14 waits for them; that call has not been made,
and it should be made rather than defaulted into.

- [ ] T001 Amend Principle III in `.specify/memory/constitution.md`: its letter mandates a run that missed its conditions "MUST be reported as inconclusive"; no surveyed target has a third outcome. Keep the spirit, state what carries the run-time half now
- [ ] T002 Amend § Compatibility Constraints in `.specify/memory/constitution.md`: the binding "no construct expressible only at conformance level `assert` or above" is inverted by FR-020, and `report` ceases to be a conformance level
- [ ] T003 Amend Principle VI in `.specify/memory/constitution.md`: decide narrow-or-remove; it is vacuous rather than satisfied under an assertion-first format
- [ ] T004 Correct the versioning-policy limb in `.specify/memory/constitution.md` § Governance so T001–T003 can be stamped honestly, and stamp the document **2.0.0 (MAJOR)**
- [ ] T005 [P] Amend `ARCHITECTURE.md` §§ 1, 2, 3, 4, 5, 6, 7 in **one** pull request — clauses 1–3, the R1–R4 role table and "what no role may do", the target classes, the walkthroughs, "support is data", clause 20 in the monitoring direction, and the § 7.1 follow-up table. § 2 is where the rendering gets a definition to point at; § 4 clause 11 is the fourth copy of the rule the constitution inverts, so splitting the sections would move the stale rule rather than retire it
- [ ] T006 Amend ADR-0002 § D13 (conformance levels) — the levels are an ADR-gated surface, so re-deriving them cannot be done by editing a note

**Checkpoint**: the repository permits what this feature does. Until then FR-020 is formally
forbidden by the constitution, and Governance says the constitution wins.

**Nothing has landed.** Three pull requests were opened for this phase and all three were
reverted; `main` carries none of it. The written text for each amendment survives in
[research.md § R10](research.md), which is where a reader should start when this is picked up
again.

**What did land is one slice of Phase 2** — T016 only: `displayName` and `examples` on the
RequirementSet schema, with the gate checking both. Nothing else in this list is done.

---

## Phase 1: Setup

**Purpose**: create the two homes `LAYOUT.md` already reserves, and wire the gate so an empty corpus
fails instead of passing.

- [ ] T007 [P] Create `mappings/` with a `README.md` stating what a target description is and that it is the only artifact class where a tool name is legitimate
- [ ] T008 [P] Create `conformance/README.md` stating what the corpus binds and — required by FR-037 — what it does **not** establish, drawn from [spec Appendix C](spec.md#appendix-c-what-the-corpus-will-not-establish)
- [ ] T009 Update `LAYOUT.md` § 1: the `mappings/` and `conformance/` rows lose "once it exists"; `mappings/` names `kind: TargetDescription` instead of `kind: MetricMapping`. **Lands in the same PR as T013** — the Development Workflow requires a PR that changes a term to update `docs/GLOSSARY.md` in that same PR, and this is where `TargetDescription` first appears
- [ ] T010 Update `LAYOUT.md` § 5 step 1 and § 6 so the relocation trap it already documents is closed: extend the sketch-label check beyond `docs/examples/*.yaml` in the same change that adds `mappings/`
- [ ] T011 Add a `Conformance corpus` section to `scripts/verify.sh` that **fails** when the corpus is empty or its runner is missing — never skips (FR-035). **Lands in the same commit as T040 and T044**, the first corpus cases: a section that fails on an empty corpus turns the gate red on the commit that introduces it, and the constitution requires `verify.sh` green on every commit. Writing it to tolerate an empty corpus instead would be the silent green it exists to prevent

**Checkpoint**: the two homes exist and `LAYOUT.md` describes them. The gate is unchanged until
T011 lands with its first cases.

### Task-ordering constraints found while planning execution

Two tasks in this phase cannot land alone, and both are the same shape — a rule this repository
already binds, hit from an unexpected direction:

| Task | Cannot land alone because |
|---|---|
| T009 | It introduces `TargetDescription` into a published document. A PR that changes a term updates `docs/GLOSSARY.md` in the same PR, so T009 and T013 are one PR |
| T011 | A section that fails on an empty corpus is red on the commit that adds it, and `verify.sh` must be green on every commit. It lands with T040 and T044 |

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: vocabulary, then schema, then the one shared check implementation. Every user story
depends on all three.

**⚠️ CRITICAL**: no user story work begins until this phase is complete.

### Vocabulary before schema (Principle I)

- [ ] T012 [P] Add the `Display name` entry to `docs/GLOSSARY.md` with its rejected alternatives — `label` (in one surveyed tool a label *is* the sampler name, i.e. a selector value), `title` (collides with the document title and with JSON Schema's `title`), `description` (invites paragraphs)
- [ ] T013 [P] Add the `Target description` entry to `docs/GLOSSARY.md` with a rejected alternative, and mark the incumbent `MetricMapping` entry superseded rather than deleting it
- [ ] T014 [P] Add the `Unrenderable criterion` entry to `docs/GLOSSARY.md` with a rejected alternative
- [ ] T015 Add the `Rendering` entry to `docs/GLOSSARY.md`, and record in the entry itself that it is **not a fourth concept** — it names the output of an act the glossary diagram, `ARCHITECTURE.md` R2 and the spec already call *render*. SC-011's budget depends on that judgement being written down, not assumed

### Schema

- [X] T016 Add optional `displayName` to `metadata`, each requirement and each predicate in `schema/opennfr.io/v1/requirementset.schema.json` — string, `minLength: 1`, additive so every existing document stays valid (FR-007)
- [ ] T017 Create `schema/opennfr.io/v1/targetdescription.schema.json` per [data-model.md § 2](data-model.md): `evidence` with `minItems: 1` cited by every claim, `native.fields`, `report.derivedFrom`, `units` as integer numerator/denominator pairs, `names.unlisted` **required**, and `assertable` with gaps partitioning each axis
- [ ] T018 Create `schema/opennfr.io/v1/rendering.schema.json` per [data-model.md § 3](data-model.md): one ordered `predicates` list, `predicate.role`, `oneOf` between `rendered` and `unrenderable`, `minItems: 1` on both `assertions` and `reasons`, and `native.text` as a string with **no `pattern`**
- [ ] T019 Extend the schema section of `scripts/verify.sh` to validate `mappings/*.yaml` and `conformance/**/*.yaml` against their kinds, and to fail on a `kind` with no schema rather than passing over it

### One rule, one implementation (FR-036)

- [ ] T020 Extract the gate's inline heredoc checks into `scripts/opennfr_check.py` — YAML-event scan, JSON-mappability, schema validation, predicate identity — importable as a module and runnable as a script
- [ ] T021 Replace the corresponding sections of `scripts/verify.sh` with calls into `scripts/opennfr_check.py`, so the corpus later asserts against the gate that actually runs rather than a copy
- [ ] T022 Fix predicate identity in `scripts/opennfr_check.py` to be unique across `criteria` **and** `guards` together — today the gate resets its seen-set per section, so a guard and a criterion may collide silently ([data-model.md § 1.2](data-model.md))

**Checkpoint**: vocabulary, three schemas and one shared checker. User stories can now proceed in
parallel.

---

## Phase 3: User Story 1 — A requirement becomes a Gatling assertion (Priority: P1) 🎯 MVP

**Goal**: an engineer writes a requirement and it becomes an assertion the tool can run, with no tool
name anywhere in the document.

**Independent test**: express the six statements the prior NFR-YAML could carry, and show the
assertion each becomes. Six for six, or the format is narrower than what it replaces.

- [ ] T023 [US1] Write `mappings/gatling.yaml` — the capability table, every claim citing dated evidence per FR-026/SC-007. Source the assertion surface from [spec Appendix A](spec.md#appendix-a-what-gatling-can-actually-assert), which is already dated and sourced
- [ ] T024 [US1] Declare in `mappings/gatling.yaml` that `report.carriesAuthorName: false`, with the evidence from [spec Appendix D](spec.md#appendix-d-why-a-precondition-cannot-be-named-in-the-targets-report) — this is what makes SC-012 checkable rather than aspirational
- [ ] T025 [US1] Declare the numeric domain in `mappings/gatling.yaml` as integer milliseconds, so FR-013 has something exact to decide against
- [ ] T026 [P] [US1] Write `conformance/render/six-statements/document.yaml` — all six statements in one document: the 50th, 75th, 95th and 99th percentiles of response time, the maximum, and the failed-request share, addressed at one request and across all
- [ ] T027 [US1] Write `conformance/render/six-statements/rendering.gatling.yaml` — one entry per predicate, in document order, each `rendered` with the assertion the target receives
- [ ] T028 [P] [US1] Write `conformance/render/request-in-a-group/` — document and rendering for a request addressed inside a group, proving FR-008's hierarchical addressing needs no new term
- [ ] T029 [P] [US1] Write `conformance/render/precondition-named/` — a requirement carrying a guard, its rendering marking `role: guard`, demonstrating FR-009's repair
- [ ] T030 [US1] Copy the six statements into `examples/` as validated examples so FR-023's "published in this repository" is discharged by an artifact the gate holds up, not by a claim

**Checkpoint**: the MVP. One document, no tool named in it, and the assertions it becomes.

---

## Phase 4: User Story 2 — The same document is reused for another tool (Priority: P2)

**Goal**: the requirement document does not change; only the choice of target does.

**Independent test**: render one unchanged document for two targets and compare. The assertion lists
differ; the document is byte-identical.

- [ ] T031 [US2] Write `mappings/k6.yaml` — the second capability table, with the eleven axes of difference recorded in [research.md § R3](research.md), each cited and dated
- [ ] T032 [US2] Declare in `mappings/k6.yaml` the `0..1` rate against `0..100` percent conversion and the float threshold domain — the pair that makes FR-014 concrete rather than theoretical
- [ ] T033 [US2] Write `conformance/render/ratio-not-assertable/` — one `document.yaml`, two renderings, opposite outcomes on the same predicate
- [ ] T034 [US2] Write `conformance/render/threshold-does-not-convert/` — a fractional-millisecond threshold, exact on one target and **unrenderable** on the other. The three-orders-of-magnitude hazard, in one case
- [ ] T035 [US2] Add a corpus check that every `document.yaml` under `conformance/render/` is byte-identical across the targets that render it — the claim of this story, made mechanical

**Checkpoint**: two targets, one unchanged document, and the difference is entirely in the mappings.

---

## Phase 5: User Story 5 — Every rule is checked by machine (Priority: P2)

**Goal**: a change that breaks a stated rule is caught by the build, not by a reader months later.

**Independent test**: plant, one at a time, each defect the gate exists to catch. The build goes red
every time and names the case.

### The runner

- [ ] T036 [US5] Write `scripts/check-conformance.py` with the exit contract from [contracts/corpus-runner.md § E1](contracts/corpus-runner.md): `0` passed, `1` a case failed, `2` **could not run**. No skip branch anywhere
- [ ] T037 [US5] Implement the check codes `SCHEMA`, `IDENTITY`, `SUM`, `ORDER`, `CONVERT`, `GAP`, `PARTITION`, `EVIDENCE`, `COLLIDE`, `NOTOOL` in `scripts/check-conformance.py`, calling `scripts/opennfr_check.py` for anything the gate also checks
- [ ] T038 [US5] Implement `CONVERT` in exact rational arithmetic from the description's `units` — a float comparison cannot decide exact representability, which is the whole point of FR-013
- [ ] T039 [US5] Implement `COLLIDE` to **report rather than fail**: two predicates with equal `report.derivedFrom` projections are a fact about the target, and failing on it would push authors to hide collisions (SC-012)

### The parse corpus

- [ ] T040 [P] [US5] Write `conformance/parse/accept/` — valid documents covering both indicator shapes, an empty selector, a fractional percentile, a guard with its own indicator, and two named criteria sharing an aggregation
- [ ] T041 [US5] Write `conformance/parse/reject/` — one mutation per case, each differing from a valid document by **exactly one** change (FR-030): unknown field at root, in a criterion and in a guard; missing unit; misspelled unit, operator and aggregation; percentile over a ratio; both indicator shapes; neither; `good` and `bad` together; uppercase name; non-scalar selector value; a threshold that is a date; anchors and aliases; duplicate identity; empty `requirements`
- [ ] T042 [US5] Write one `.expected.yaml` sidecar per rejection case naming the **exact path** the error must report (FR-031) — never an `expect:` key inside the case, which would itself be an unknown field and mask the finding
- [ ] T043 [P] [US5] Write `conformance/parse/known-gaps/` for rules the schema cannot yet express, each dated, so a gap is a register entry rather than a silent pass

### The gate mutation suite

- [ ] T044 [US5] Write `scripts/test-gate.py`, which copies the tree, plants one defect and requires the gate to go red (FR-034)
- [ ] T045 [US5] Add the mandatory control case to `scripts/test-gate.py`: an unmutated copy must exit `0`, or the whole suite can pass because the gate is red for an unrelated reason
- [ ] T046 [US5] Add mutation cases for the four checks repaired in `9657819` — Cyrillic in a document, a shimmed-away library, an emptied sketch corpus, a broken link pipeline. These are the most valuable pins in the suite: each guards a section that reported `ok` for the life of the project ([spec Appendix B](spec.md#appendix-b-four-checks-that-could-not-fail-and-what-they-cost-to-find))
- [ ] T047 [US5] Add mutation cases for every remaining check in `scripts/verify.sh`, so SC-014 is 100% and not "the ones we thought of"
- [ ] T048 [US5] Add a mutation case asserting **no line matches `skip`** when a dependency is removed — assert on the word, not the exit code, because other sections turn the run red and would mask a section that quietly passes
- [ ] T049 [US5] Wire `scripts/check-conformance.py` and `scripts/test-gate.py` into `scripts/verify.sh`, propagating exit codes into `fail`

**Checkpoint**: every rule the specification states about a document is now falsifiable.

---

## Phase 6: User Story 3 — An unrenderable requirement is named, never dropped (Priority: P3)

**Goal**: the engineer is told, by name and before the run, what their tool cannot check.

**Independent test**: a document mixing renderable and unrenderable criteria. Every criterion is in
exactly one of two lists and the counts add up.

- [ ] T050 [P] [US3] Write `conformance/render/comparison-not-available/` — a predicate using an operator one target lacks, unrenderable with a reason citing the comparison gap, never approximated (FR-011)
- [ ] T051 [P] [US3] Write `conformance/render/statistic-not-available/` — unrenderable for a **different** named reason, so the spec's three kinds of unrenderability are distinguishable by which axis the gap partitions
- [ ] T052 [US3] Add negative corpus cases under `conformance/render/negative/` that the runner MUST trip: a silently dropped predicate, a fabricated assertion for a predicate nobody wrote, a rounded threshold, and a predicate refused for a capability the description **does** declare
- [ ] T053 [US3] Implement the second direction of `GAP` in `scripts/check-conformance.py` — declaring something unrenderable that the target can in fact assert is as much a defect as the reverse, and only one of the two is uncomfortable to report
- [ ] T054 [US3] Implement `PARTITION` so a combination declared in neither capabilities nor gaps is reported as a **defect of the description**, which is FR-017 stated as an executable rule

**Checkpoint**: no criterion can disappear between a document and a rendering.

---

## Phase 7: User Story 4 — A reader can predict the assertions (Priority: P4)

**Goal**: someone who has never seen the tooling reads a document and a description and can say what
will be asserted, and against what number.

**Independent test**: give a reader both files and ask them to write down the assertions; compare.

- [ ] T055 [US4] Rewrite the "Deliberately not in it — yet" table in `FORMAT.md`: several rows are now settled permanently rather than "yet", and `enforcement`, `onViolation`, `gate` and `severity` are rejected rather than pending
- [ ] T056 [US4] Document `displayName` in `FORMAT.md` together with FR-007a — a display name never restates a threshold, a unit or an operator, because that is a second source for one number and the two diverge the first time the threshold moves
- [ ] T057 [US4] State in `FORMAT.md`, where the field is introduced, that a display name **does not reach the target's report**. A field named this invitingly will otherwise be assumed to
- [ ] T058 [US4] Add the `--strip-display-names` mode to `scripts/check-conformance.py` and the SC-013 case: stripping every display name must leave every rendering byte-identical
- [ ] T059 [US4] Write `docs/targets/gatling.md` and `docs/targets/k6.md` explaining each mapping in prose, so the capability tables are readable by someone who will not read YAML

**Checkpoint**: the format is predictable from reading, which is the testable form of "good-looking".

---

## Phase 8: Polish and the deletion sweep

**Purpose**: FORMAT.md's rule — a note accepted, parked or rejected is deleted in the same change
that settles it — applied in the order [spec § What leaves the notebook](spec.md#what-leaves-the-notebook-and-in-what-order) establishes. **Tier order is not a preference.** A rule written in four places cannot be
removed from the notebook copy alone.

### Tier 0 — no binding twin, safe now

- [ ] T060 [P] Delete rule 1 and rule 3 from `docs/units.md`, and the "units inside the value" rejection row. Rule 1 restates verbatim a rule stated eleven lines above it **in the same file**
- [ ] T061 [P] Drop the `EvaluationReport.spec.run.attributes` field path from the run-identity heading in `docs/semconv/loadtest.md`, keeping the table and the correlation finding — Principle II rests on them
- [ ] T062 [P] Delete `report` as a conformance level from `docs/compatibility.md`, and the sentence naming target-blind evaluation as the source of the format's portability claim
- [ ] T063 [P] Delete the `severity` entry from `docs/GLOSSARY.md`, the `gate` clause from `RequirementSet`, and the `→ fail` clause from `Criterion`

### Tier 1 — after T001 (Principle III)

- [ ] T064 Move `gate`, `Verdict`, `Outcome` and the `inconclusive` half of `Guard` out of `docs/GLOSSARY.md` into a parked note under `docs/experimental/`, carrying each argument and its rejected alternatives with a date (FR-041)
- [ ] T065 Delete `docs/examples/checkout-perf.report.yaml`, carrying its argument into the same markdown parked note — the parked area is markdown-only, so the YAML has no compliant home ([research.md § R7](research.md))

### Tier 2 — after T002 and T005

- [ ] T066 Remove all four copies of the superseded admission rule in one change — `.specify/memory/constitution.md`, `ARCHITECTURE.md` § 1, `docs/compatibility.md` and `docs/adr/0002-compatibility.md`. Removing the notebook copy alone would leave the repository formally forbidding what FR-020 requires
- [ ] T067 Update the `Target`, `Adapter` and `MetricMapping` entries in `docs/GLOSSARY.md` to match the amended architecture, and fix every same-file anchor in the same change

### Tier 3 — dated notes on decision records, never rewrites

- [ ] T068 [P] Append dated supersession notes to ADR-0002 §§ D11, D12, D13 in `docs/adr/0002-compatibility.md`, leaving the original arguments readable (FR-040)
- [ ] T069 [P] Append dated supersession notes to ADR-0001 §§ D6, D9, D10 in `docs/adr/0001-terminology.md`

### The two open questions, into issues rather than files

- [ ] T070 [P] Open an issue for the `ratio` readability problem: an error-rate requirement names `http.client.request.duration`, a metric it does not measure. Carry the four options and their costs from [spec § Open](spec.md#open--a-problem-this-specification-has-not-solved). Principle I puts a naming disagreement in an issue before any file changes
- [ ] T071 [P] Open an issue for the requirement-identifier convention, carrying the three drift hazards recorded in the same section
- [ ] T072 [P] Open an issue for the link checker's false positive: it greps for `](`, so a regular expression written in prose reads as a dangling link. Untouched by `9657819` because the extraction is unchanged

**Checkpoint**: `docs/` holds live ideas only, and every settled note has been deleted or parked in
the change that settled it.

---

## Dependencies

```text
Phase 0 (amendments, separate PRs)
   │
   ├──> Phase 1 (setup) ──> Phase 2 (vocabulary, schema, shared checker)
   │                              │
   │                              ├──> Phase 3  US1  (P1) 🎯 MVP
   │                              │       │
   │                              │       └──> Phase 4  US2  (P2)
   │                              │
   │                              ├──> Phase 5  US5  (P2)  — independent of US1/US2
   │                              │
   │                              ├──> Phase 6  US3  (P3)  — needs US1 for cases to exist
   │                              └──> Phase 7  US4  (P4)
   │
   └──> Phase 8 Tier 0 (safe now)
        Phase 8 Tier 1 needs T001
        Phase 8 Tier 2 needs T002 + T005
```

**Story independence**

| Story | Depends on | Why |
|---|---|---|
| US1 | Phase 2 | Needs both new schemas and the vocabulary |
| US2 | Phase 2 | Independent of US1 — a second mapping can be written in parallel; only T033/T035 need US1's documents |
| US5 | Phase 2 | The parse corpus and the gate mutation suite need nothing from US1 or US2 and can be built first |
| US3 | US1 | Needs a target description and at least one document to declare something unrenderable against |
| US4 | US1, US2 | Prose about mappings needs the mappings |

**Soft dependency worth stating**: US1 publishes renderings that only become *checked* when US5's
runner lands. Reviewing them by hand in between is exactly the state this feature exists to end, so
prefer landing T036–T039 early even though the phase is numbered later.

## Parallel opportunities

- **T007, T008** — two new directories, no overlap
- **T012, T013, T014** — three glossary entries in one file; parallel only if authored separately and merged in one commit, since the Development Workflow requires a term change and its glossary update in the same PR
- **T026, T028, T029** — three independent corpus case directories
- **T040, T043** — accept and known-gaps corpora, different directories
- **T050, T051** — two unrenderable cases, different reasons
- **T060, T061, T062, T063** — Tier 0 deletions, four different files
- **T068, T069** — two ADRs
- **T070, T071, T072** — three issues, no files touched

## Implementation strategy

**MVP is Phase 3 alone.** US1 delivers the whole claim of the feature: a requirement written with no
tool named in it becoming an assertion the tool runs. Everything after it either widens the claim
(US2), makes it falsifiable (US5), makes it honest under failure (US3) or makes it readable (US4).

**Suggested landing order**, one concern per PR:

1. Phase 0 amendments — three or four PRs, each amending one document
2. Phase 1 + Phase 2 — setup, vocabulary, schema; the vocabulary PR lands before the schema PR
3. Phase 5, T036–T039 — the runner, early, so nothing below is reviewed by eye
4. Phase 3 — the MVP
5. Phase 4, Phase 5 remainder, Phase 6, Phase 7
6. Phase 8 — the sweep, in tier order, each tier after its amendment

**What must not be batched**: Tier 2's four copies of the admission rule are one change precisely
because splitting them leaves the repository self-contradictory between merges. The opposite applies
to Tier 0, where four independent files can go separately.
