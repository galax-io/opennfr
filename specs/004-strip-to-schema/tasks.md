---
description: "Task list for 004-strip-to-schema"
---

# Tasks: Strip the repository to the schema, the examples and the fields

**Input**: Design documents from `/specs/004-strip-to-schema/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/)

**Tests**: No test tasks. There is no code. What stands in for tests is `scripts/verify.sh`, and
the tasks that change it are implementation tasks in Phase 2 and Phase 4.

**Organization**: By user story, so each is independently deliverable. US1 and US2 are both P1 and
genuinely independent — correcting the corpus fixes what the repository *teaches* even if not one
document is deleted, and deleting the misleading documents makes the rest correct even if the
corpus is untouched.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel — different files, no dependency on an incomplete task
- **[Story]**: US1, US2, US3; absent on Setup, Foundational and Polish

---

## Phase 1: Setup

Nothing is deleted here. This phase records the "before" so every success criterion can be checked
as a delta rather than asserted at the end.

- [X] T001 Confirm the gate is green before any change: run `bash scripts/verify.sh` from the repository root and record that it reports PASS, with the name and scan count of every section, into `specs/004-strip-to-schema/baseline.md`
- [X] T002 [P] Record the "before" counts into `specs/004-strip-to-schema/baseline.md`: documentation bytes (expect 168,591), bytes of `ARCHITECTURE.md` + `LAYOUT.md` + `.specify/memory/constitution.md` + `AGENTS.md` (expect 66,383), and the count of documentation markdown files (expect 20) — stating the basis, since an earlier draft counted tooling as documentation. These are what SC-005 and SC-008 are measured against
- [X] T003 [P] Run the corpus check from [quickstart.md](quickstart.md) § 2 against the current tree and record its output into `specs/004-strip-to-schema/baseline.md`. Expect exactly eight `UNRUNNABLE` lines, all `selector ['http.route']`, matching [research.md](research.md) § R2. If the count differs, stop — the contract in [contracts/gatling-reach.md](contracts/gatling-reach.md) is out of date with the corpus and must be re-checked before anything is deleted

**Checkpoint**: the before-state is written down. Every later claim is checkable against it.

---

## Phase 2: Foundational — blocking prerequisites

**Nothing in Phase 3, 4 or 5 may start until this phase completes.** Principle VII of the
constitution requires every change that alters a component to amend `ARCHITECTURE.md` first; T004
is what makes deleting that document legal rather than a violation. The two new documents are
destinations that must exist before the files feeding them are deleted.

- [X] T004 Amend `.specify/memory/constitution.md` to **3.0.0** per [research.md](research.md) § "Constitution consequences": remove Principle VII entirely and record its number as withdrawn; trim Principle III to what exists (an unknown field is a parse error; a check that cannot run fails rather than skips; an artifact nothing validates says so) and drop its clauses about rendering, target descriptions and absent-data declarations; reduce Principle VIII to `docs/` and delete the grandfather clause naming `docs/semconv/loadtest.md` and `docs/examples/mapping-k6.yaml`; replace "MUST NOT change without an ADR" with "MUST NOT change without an issue that argued it, and a glossary entry recording what was rejected" per § R5; drop the target-description surface from Compatibility Constraints; update every path to the target tree in [data-model.md](data-model.md). Write a Sync Impact Report at the top stating the MAJOR rationale and that the amendment travels with this feature
- [X] T005 Update the Constitution Check gates in `.specify/templates/plan-template.md` to follow 3.0.0: delete the VII gate, rewrite the III gate to the three surviving obligations, rewrite the Compatibility gate to drop the conformance-level paragraph and the target-description surface, and point the vocabulary gate at `GLOSSARY.md`
- [X] T006 [P] Create `CONTRIBUTING.md` at the repository root, roughly two kilobytes (FR-019), carrying the three rules that exist only in `LAYOUT.md` per [data-model.md](data-model.md): a note is deleted once it becomes a rule; the route from an idea into the schema (`docs/ideas.md` → an argued issue → a `GLOSSARY.md` entry with a rejected alternative → the schema → the note is deleted); and how to propose a change — one concern per pull request, the gate green, an issue in a milestone. It MUST NOT restate any field's rules
- [X] T007 [P] Create `GLOSSARY.md` at the repository root from `reference/glossary.md`, reduced per FR-015 to terms, definitions and a rejected alternative each. Drop every sentence restating what the field description says — the schema's rules, the combination tables, the worked example. Target the order of OpenSLO's glossary, a few kilobytes against the current 12,894 bytes. Keep the reserved word `workload` and its reason

**Checkpoint**: Principle VII is gone, so `ARCHITECTURE.md` can be deleted. `CONTRIBUTING.md` and
`GLOSSARY.md` exist, so the files feeding them can be. The gate is still green — the two new files
are linked from nothing yet, which is legal.

---

## Phase 3: User Story 1 — someone lands on the repository and finds the format (P1)

**Goal**: one document describes the format and its fields; every page a reader can reach
describes something that exists.

**Independent test**: hand the repository to a reader who has never seen it, ask them to write a
valid document, and count the files they open. Passes at three.

The README tasks are sequential — one file. Everything after T012 is parallel.

- [X] T008 [US1] Rewrite `README.md` as the specification: what the format is, the model, and **every field** — absorbing the constraint tables, enumerations and rejection messages from `schema/README.md` (FR-006, FR-007). Drop that page's `name`-pattern workaround and its explanatory sentence about the link checker; the workaround's cause disappears with the file
- [X] T009 [US1] Add the unit enumeration and the conversion table to `README.md` from `reference/units.md`. Restate its rule 2 as a **limitation** — the schema does not check that a unit fits the aggregation — rather than as a rule the schema enforces, which closes #39
- [X] T010 [US1] Add to `README.md` from `reference/names.md`: which OpenTelemetry names to write, the vantage-point rule (a generator measures as a client, a production stack as a server, and the two are not comparable), and the dated finding from `reference/compatibility.md` that **no load generator publishes semantic convention names**
- [X] T011 [US1] Add to `README.md` the definitions of `loadtest.request.name` and `loadtest.group.name`, with the statement that they are **not** OpenTelemetry names and that after this change the corpus depends on them to address a request at all (FR-018)
- [X] T012 [US1] Add per-field notes to `README.md` carrying the ten load-bearing arguments from [research.md](research.md) § R4 — D3, D4, D5, D6, D7, D14, D15, D16, D17 and ADR-0003 — each beside the field it justifies, in the manner OpenSLO's README uses. Add the one paragraph on why no surveyed format was adopted, from `reference/prior-art.md`. The other nine decisions are dropped
- [X] T013 [P] [US1] Delete `ARCHITECTURE.md` (FR-001)
- [X] T014 [P] [US1] Delete `LAYOUT.md` (FR-002). Its live rules moved in T006; the nine artifact classes, eleven governance words and target-onboarding procedure are dropped
- [X] T015 [P] [US1] Delete `schema/README.md`, merged into `README.md` by T008
- [X] T016 [P] [US1] Delete `reference/` entirely: `glossary.md`, `units.md`, `names.md`, `compatibility.md`, `prior-art.md`, `README.md` and `adr/` with its three records. Every destination is T007 and T008–T012
- [X] T017 [US1] Create `docs/ideas.md` as the single ideas file (FR-016), one paragraph per construct, from `docs/not-in-the-format.md`, `docs/the-result-document.md`, `docs/tool-support.md`, `docs/experimental/README.md` and the `loadtest.*` registry in `docs/semconv/loadtest.md` minus the two names T011 moved. Name the `errorSignal` sketch as the unsolved problem it is. Each paragraph says what would have to become true first
- [X] T018 [US1] Delete the rest of `docs/`: `not-in-the-format.md`, `the-result-document.md`, `tool-support.md`, `README.md`, `semconv/`, `experimental/`, and `examples/` with its four sketches
- [X] T019 [US1] Delete section 8 of `scripts/verify.sh`, "Examples are labelled as sketches", together with the `docs/`-absent branch added for it. Its input no longer exists, and left standing it fails with `docs/examples/ holds no sketch to check` — the anti-silent-green guard firing on the wrong input ([contracts/verify-sections.md](contracts/verify-sections.md) § 8)
- [X] T020 [US1] Narrow the JSON-mapping section of `scripts/verify.sh` to `examples/*.yaml`, dropping the `docs/examples/**/*.yaml` glob, and confirm the YAML-parse section still finds files through `examples/*.yaml` now that `docs/**/*.yaml` is empty
- [X] T021 [US1] Update the two `description` strings inside `schema/opennfr.io/v1/requirementset.schema.json` that name `reference/glossary.md` and `reference/units.md` to name `GLOSSARY.md` and `README.md`. **No other change to the schema file** — FR-014
- [X] T022 [P] [US1] Update `.github/pull_request_template.md`: the glossary path, and the ADR checklist line becomes the argued-issue line per T004
- [X] T023 [P] [US1] Update `.github/ISSUE_TEMPLATE/naming.yml` and `.github/ISSUE_TEMPLATE/config.yml`: the glossary path, and drop the prior-art link
- [X] T024 [US1] Run the sweep from [quickstart.md](quickstart.md) § 5 and fix every hit: no surviving file may name `ARCHITECTURE.md`, `LAYOUT.md`, `reference/` or `schema/README` — as a link, in prose, in a script, or inside a `description` string, where the link check does not look (FR-003)
- [X] T025 [US1] Run `bash scripts/verify.sh` and confirm PASS with every section reporting what it scanned, and none reporting `ok` on zero files

**Checkpoint**: a reader opens `README.md` and finds the format. Nothing they can reach describes
a component, directory or construct that does not exist. Deliverable on its own.

---

## Phase 4: User Story 2 — the examples are only what a real tool can assert (P1)

**Goal**: zero predicates in the published corpus that Gatling cannot run.

**Independent test**: the script in [quickstart.md](quickstart.md) § 2 prints
`all predicates assertable by Gatling`. It reads the corpus and
[contracts/gatling-reach.md](contracts/gatling-reach.md), never the schema — which is what keeps
"the corpus narrows, the format does not" checkable.

- [X] T026 [P] [US2] Create `examples/one-request-is-fast.yaml`: the smallest valid document, addressing one request by `loadtest.request.name`, one criterion on `http.client.request.duration`. A header comment states the question it answers — "this one call must stay under 500 ms" — not the fields it uses
- [X] T027 [P] [US2] Create `examples/fast-and-reliable.yaml`: one requirement, one `selector` by request name, several criteria — a percentile, the slowest, the failed share as `rate` with `bad: {error.type: "*"}`, and the failed count. It exists to show that a requirement is one human sentence, and that `bad` reads as both a share and a count
- [X] T028 [P] [US2] Create `examples/the-run-held-up.yaml`: `selector: {}` for the whole run, a **guard** on `rate` in `{request}/s` beside criteria on latency and failed share. It is the only document in the corpus carrying a guard, and its header comment says why a green criterion under a violated guard proves nothing
- [X] T029 [US2] Delete `examples/minimal.yaml` and `examples/six-statements.yaml`. Both address `http.route`, which Gatling cannot express; eight of their twelve predicates are unrunnable ([research.md](research.md) § R2)
- [X] T030 [US2] Add a section to `README.md` stating what Gatling can and cannot assert, from [contracts/gatling-reach.md](contracts/gatling-reach.md) — dated 2026-08-20 and sourced to Gatling v3.15.1 — and stating explicitly that the **schema** still permits `http.route`, `sum` and `neq` while the **published corpus** does not (FR-014). Without this the corpus looks like the format
- [X] T031 [US2] Add section 9 to `scripts/verify.sh`, "Examples are assertable by Gatling", per [contracts/verify-sections.md](contracts/verify-sections.md) § "One section is added": it reads `examples/*.yaml`, applies the tables in `contracts/gatling-reach.md`, reports the number of predicates checked, and fails on an empty scan. It carries a comment saying it must never be extended to read the schema, because that would be the format narrowing to one tool
- [X] T032 [US2] Probe section 9 rather than trusting it: temporarily give an example an `http.route` selector, confirm `bash scripts/verify.sh` FAILS naming that file, then restore. A check that cannot fail is not a check
- [X] T033 [US2] Run the corpus script from [quickstart.md](quickstart.md) § 2 and confirm `all predicates assertable by Gatling`, then `bash scripts/verify.sh` and confirm PASS

**Checkpoint**: every published example can be run by the one tool with a waiting counterparty.
Deliverable on its own.

---

## Phase 5: User Story 3 — the repository is small enough to restart from (P2)

**Goal**: the prose that describes no field of the format is one `CONTRIBUTING.md`.

**Independent test**: count the markdown files outside `specs/` and tooling. Five.

- [X] T034 [P] [US3] Reduce `AGENTS.md`: its Structure and Architecture sections shrink to the target tree in [data-model.md](data-model.md), the Stack section stops describing a repository of notes, and every path follows the move. It stays a working file, not published documentation
- [ ] T035 [US3] Close #35 and #36 with a reason (FR-021): both are argued against `ARCHITECTURE.md`, `LAYOUT.md` and documents that no longer exist, and 3.0.0 removes the ADR requirement that made the ladder's retirement owe one. Close #39 and #43 — the claim moved and was restated (T009), and the workaround's cause disappeared with `schema/README.md` (T008). Close #40, #41, #44 and #45 as superseded
- [ ] T036 [US3] Add a comment to #46 recording that `.copier-answers.yml` would now regenerate `AGENTS.md` against a tree two cuts old, and that its own header forbids hand-editing, so the fix is to re-answer. Leave it open. Leave #37, #38 and #42 open — all are schema or gate defects this feature does not touch
- [ ] T037 [US3] Record, in the pull request body, what each removed document was for and why it is gone (FR-020), so a later decision to rebuild any of it starts from the argument rather than from `git log`. The disposition table in [data-model.md](data-model.md) is the source

**Checkpoint**: nothing in the repository is left pointing at an argument nobody can find.

---

## Phase 6: Polish and verification

- [ ] T038 Walk the disposition table in [data-model.md](data-model.md) row by row and confirm every row's destination exists in the tree (SC-007). This is the one criterion no command can check, which is why the table has no blanks
- [ ] T039 [P] Run [quickstart.md](quickstart.md) § 3 both ways: `git rm -r docs && bash scripts/verify.sh` stays PASS, and adding a markdown link from `README.md` into `docs/` makes it FAIL. Restore after each
- [ ] T040 [P] Run [quickstart.md](quickstart.md) § 4 and confirm `aggregation` is described in `README.md` and nowhere else (SC-003)
- [ ] T041 [P] Run [quickstart.md](quickstart.md) § 6 and confirm five markdown files and a `CONTRIBUTING.md` of roughly two kilobytes. Compare against `baseline.md` from T002 and record the deltas (SC-005, SC-008)
- [ ] T042 Confirm `git diff main -- schema/opennfr.io/v1/requirementset.schema.json` shows **only** the two `description` strings from T021. Any other hunk means the format changed, which this feature forbids (FR-014)
- [ ] T043 The reader test from [quickstart.md](quickstart.md) § 7 (SC-001): ask someone who has not seen the repository to write a requirement for one request answering within 400 ms and prove it valid. Passes if they open three files. If they open a fourth, or ask which of two documents to believe, record which and why — that is the next task, not a footnote
- [ ] T044 Delete `specs/004-strip-to-schema/baseline.md` once T041 has recorded its deltas into this file. It is scaffolding for the measurement, not an artifact of the feature

---

## Dependencies

```
Phase 1 Setup (T001-T003)
        │
        ▼
Phase 2 Foundational (T004-T007)          ← BLOCKS EVERYTHING
   T004 constitution 3.0.0 ──► removes Principle VII, which otherwise
        │                       forbids deleting ARCHITECTURE.md (T013)
        ├─► T005 plan template
        ├─► T006 CONTRIBUTING.md ──► destination for LAYOUT.md's rules (T014)
        └─► T007 GLOSSARY.md ─────► destination for reference/glossary.md (T016)
        │
        ├──────────────────────────┬─────────────────────┐
        ▼                          ▼                     ▼
   Phase 3 US1 (P1)          Phase 4 US2 (P1)      Phase 5 US3 (P2)
   T008-T025                 T026-T033             T034-T037
        │                          │                     │
        └──────────────────────────┴─────────────────────┘
                                   ▼
                         Phase 6 Polish (T038-T044)
```

**Between stories**: US1 and US2 are independent in substance and share one file. T030 and T031
touch `README.md` and `scripts/verify.sh`, which T008–T012 and T019–T020 also touch — so if both
stories are worked at once, sequence those two tasks after US1's edits to the same files. Nothing
else collides.

**Within US1**: T008 → T009 → T010 → T011 → T012 are one file and strictly sequential. T013–T016
and T022–T023 are parallel with each other and with the README work. T017 must precede T018 —
create `docs/ideas.md` before deleting what feeds it. T024 and T025 are last: they check the
others.

**Within US2**: T026, T027, T028 are three new files and fully parallel. T029 after them, so the
corpus is never empty. T030 → T031 → T032 → T033 sequential.

## Parallel execution examples

**Phase 2**, after T004 lands:

```
T005  .specify/templates/plan-template.md
T006  CONTRIBUTING.md
T007  GLOSSARY.md
```

**Phase 3**, once T008–T012 have rewritten `README.md`:

```
T013  delete ARCHITECTURE.md
T014  delete LAYOUT.md
T015  delete schema/README.md
T016  delete reference/
T022  .github/pull_request_template.md
T023  .github/ISSUE_TEMPLATE/*.yml
```

**Phase 4**, the whole corpus at once:

```
T026  examples/one-request-is-fast.yaml
T027  examples/fast-and-reliable.yaml
T028  examples/the-run-held-up.yaml
```

## Implementation strategy

**MVP is Phase 1 + Phase 2 + Phase 3 (US1).** At that point one document describes the format,
nothing a reader can reach describes something that does not exist, and the gate is green. The
corpus is still Gatling-hostile, which is a real defect — but it is the defect the repository has
today, and US1 does not make it worse.

**Recommended order is US1 then US2**, despite both being P1. US1 creates the `README.md` that
US2's Gatling section lands in, and US2 done first would write that section into a document about
to be rewritten.

**US3 can land any time after Phase 2** and is mostly issue hygiene. It is P2 because a reader is
served by US1 and US2; US3 serves the author.

**One commit per phase, each green.** `AGENTS.md` requires one concern per pull request and a
commit that passes `bash scripts/verify.sh` on its own. Phase 2 is one commit and discloses in its
first paragraph that it carries a constitutional amendment, as the amendment procedure requires.

## Task summary

| Phase | Tasks | Count |
|---|---|---|
| 1 Setup | T001–T003 | 3 |
| 2 Foundational | T004–T007 | 4 |
| 3 US1 (P1) | T008–T025 | 18 |
| 4 US2 (P1) | T026–T033 | 8 |
| 5 US3 (P2) | T034–T037 | 4 |
| 6 Polish | T038–T044 | 7 |
| **Total** | | **44** |

Parallelisable: 17 tasks carry `[P]`.
