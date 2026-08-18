---

description: "Task list for 001-nfr-format-architecture"
---

# Tasks: Repository Architecture and Operating Principles

**Input**: Design documents from `/specs/001-nfr-format-architecture/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: No test tasks. This feature ships documentation and governance only (FR-025); there
is nothing to unit-test. Verification is `bash scripts/verify.sh` plus the six executable
checks in [quickstart.md](quickstart.md), which appear as verification tasks in their phases.

**Organization**: Grouped by user story. One phase per story, each independently reviewable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1–US4, matching [spec.md](spec.md)
- Exact file paths in every description

## Path Conventions

Repository root. Format artifacts live in `docs/`; governance in `.specify/`. There is no
`src/` and no `tests/` — this feature writes markdown.

---

## ⚠️ Phase order is not priority order

US1 (architecture) is **P1** and the MVP, but its phase sits **after** US2's. This is
deliberate and load-bearing:

> The constitution says a conflicting document "is wrong and MUST be fixed". An architecture
> document written against unamended text is born wrong. And the amendment PR may contain
> nothing but the constitution and the templates it affects — which forbids it from carrying
> the glossary entry its own new wording needs.

So the sequence is **glossary → amendment → architecture → layout → follow-up list**. Priority
still decides what matters most; the constitution decides what lands first. Where they
disagree, the constitution wins.

---

## Phase 1: Setup

**Purpose**: Unblock CI. No PR in this feature can merge until these exist.

- [ ] T001 Create milestone `v0.2.0` in `galax-io/opennfr` via `gh api repos/galax-io/opennfr/milestones -X POST -f title=v0.2.0 -f description="Repository architecture and operating principles…"` — no open milestone exists, so `scripts/check-linkage.sh` exits 2 on every PR until this lands
- [ ] T002 Create issue "Settle the vocabulary this architecture introduces" on milestone `v0.2.0`, per Principle I's rule that naming disagreements are argued in an issue before files change
- [ ] T003 [P] Create issue "Amend the constitution to v1.1.0" on milestone `v0.2.0`
- [ ] T004 [P] Create issue "Publish the architecture document" on milestone `v0.2.0`
- [ ] T005 [P] Create issue "Publish the repository layout document" on milestone `v0.2.0`
- [ ] T006 [P] Create issue "Name the follow-up specs the implementation travels through" on milestone `v0.2.0`
- [ ] T006a [P] Create issue "Publish the 001 architecture spec, plan and tasks" on milestone `v0.2.0` — T007 requires a closing link, and every other Phase 1 issue is already claimed by a later PR
- [ ] T007 Commit the spec artifacts as `docs(speckit): add 001-nfr-format-architecture spec/plan/tasks` covering `specs/001-nfr-format-architecture/` and the `.gitignore` entry for `.specify/feature.json`, assigned to `v0.2.0` with a closing link
- [ ] T008 [P] Delete the merged leftovers `origin/chore/speckit-extensions` and `origin/docs/constitution`, both empty against `main` after squash-merge

**Checkpoint**: `bash scripts/check-linkage.sh` resolves an open milestone; PRs can merge.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Settle every contested word before any document uses it. Both new documents are
made of these words, so nothing downstream can start.

**⚠️ CRITICAL**: No user story work begins until this phase is complete.

- [X] T009 Add `### Target` to `docs/GLOSSARY.md` inside `## Layer 2. Runtime`, between `### Assertion` and `### Adapter`, defining both target classes with at least one rejected alternative — no fourth layer is created (FR-012)
- [X] T010 Define `monitoring backend` inside that same `### Target` entry in `docs/GLOSSARY.md` as the second class, because `backend` already carries a different sense in the `enforcement` table and the `EvaluationReport` entry — this reverses the 2026-08-18 clarification, which predates the collision
- [X] T011 Drop the noun `binding` project-wide in favour of `tool mapping`: it collides with `MetricMapping` and with `binding` used as an adjective meaning normative. Edit `specs/001-nfr-format-architecture/spec.md` (the Key Entities artifact-class list and FR-012's parenthetical)
- [X] T012 [P] Extend the ASCII layer diagram in `docs/GLOSSARY.md` so the monitoring class is visible — today it shows only `(k6/Gatling)`, leaving the second target class absent from the only picture the glossary has
- [X] T013 Fix the traced path's endpoint in `specs/001-nfr-format-architecture/spec.md`: FR-001, SC-001 and User Story 1 end at *verdict*, but a `Verdict` is the result of checking one criterion — what a CI job prints is an `Outcome`. The path is `requirement → criterion → verdict → gate → outcome`
- [ ] T014 Open the glossary PR with issue T002's closing link and milestone `v0.2.0`; confirm `bash scripts/verify.sh` passes

**Checkpoint**: Every contested word has exactly one home and one meaning.

---

## Phase 3: User Story 2 — Principles that end arguments (Priority: P2)

**Goal**: The project gains ratified rules that decide the recurring arguments the
architecture creates, through the constitution's own amendment procedure.

**Independent Test**: For each principle, produce its citation — committed text named by file
and section, or a decision already taken here. A principle that can produce neither is
removed.

**Lands before US1** — see the phase-order note above.

- [X] T015 [US2] Decide the fate of "Experiments Are Parked, Not Merged" — **needs the author**. Its offered citation (ADR-0001 § D7) was refuted as an abstention, not a parking; the nearest committed text, Principle III's "Any artifact nothing validates MUST say so in its own text", blesses labelling, which the draft rejects; and `docs/semconv/loadtest.md` plus the `errorSignal` block in `docs/examples/mapping-k6.yaml` already practise labelling over containment. See [research.md](research.md) § D2
- [X] T016 [US2] Draft `### VI. Evaluation Is Target-Blind` in `.specify/memory/constitution.md`, after Principle V and before `## Compatibility Constraints`, citing `docs/compatibility.md` § Requirements for the Go implementation → Layering — and noting that section is in the document's proposal half
- [X] T017 [US2] Draft `### VII. Architecture Before Implementation` in `.specify/memory/constitution.md`, immediately after VI, co-citing `AGENTS.md` § Commits & PRs and constitution Principle I's ordering rule, because AGENTS.md declares its lower half boilerplate reused across projects
- [X] T018 [US2] Draft `### VIII` last in `.specify/memory/constitution.md` if T015 keeps it, so dropping it renumbers nothing
- [X] T019 [US2] Widen the Compatibility Constraints bullet in `.specify/memory/constitution.md` from "Support for a load testing tool MUST be expressible as data" to cover any target — a widening, not a parallel bullet (FR-011)
- [X] T020 [US2] Update Governance → Compliance review in `.specify/memory/constitution.md`: "five principles above" → the surviving count
- [X] T021 [US2] Update the version footer in `.specify/memory/constitution.md` to `1.1.0` with today's Last Amended date
- [X] T022 [US2] Rewrite the SYNC IMPACT REPORT comment block at the top of `.specify/memory/constitution.md` in place — it is a current-state report, not a changelog
- [X] T023 [US2] Fix the stale pointer in `.specify/templates/plan-template.md`: "See `.specify/memory/constitution.md` (v1.0.0)" → `(v1.1.0)`. This is exactly the drift the amendment exists to prevent
- [X] T024 [US2] Add Constitution Check gate bullets for the new principles to `.specify/templates/plan-template.md`, before the Compatibility gate
- [X] T025 [US2] Verify `.specify/templates/spec-template.md`, `tasks-template.md` and `checklist-template.md` need no edit, and that the amendment PR touches **exactly two files**
- [ ] T026 [US2] Open the amendment PR — `.specify/memory/constitution.md` and `.specify/templates/plan-template.md` and nothing else — with issue T003's closing link
- [X] T027 [US2] Run the SC-004 checks from [quickstart.md](quickstart.md) § 3: version footer, template pointer, principle count, Compliance review sentence all agree

**Checkpoint**: The constitution is v1.1.0 and every later document can be written against it.

---

## Phase 4: User Story 1 — Someone new understands how it works (Priority: P1) 🎯 MVP

**Goal**: One document traces a requirement from authoring to outcome, naming every component
and what each may not know, worked through concretely for three load generators.

**Independent Test**: Hand `docs/architecture.md` to someone who has read nothing else and ask
them to trace one requirement end to end, naming each component. A step they cannot name, or a
point where they must guess what a component knows, is a defect.

- [X] T028 [US1] Create `docs/architecture.md` with its own split-status declaration: component roles, their forbidden dependencies and the follow-up boundaries bind later specs; every description of a component that does not exist is marked proposed; no statement is unmarked (FR-013, SC-014)
- [X] T029 [US1] Write the component-role table in `docs/architecture.md` from [contracts/component-roles.md](contracts/component-roles.md) — four roles, each with input, output and at least one forbidden dependency (FR-002). State that these contracts are authored here, not inherited from `docs/compatibility.md` § Layering, which gives responsibilities without contracts and sits in that document's proposal half
- [X] T030 [US1] State in `docs/architecture.md` that Render and Ingest are sub-roles of the glossary's `Adapter`, not a rival decomposition — Principle I forbids a second decomposition of one pipeline. Note that `interpreter` in the original request means `Adapter`
- [X] T030a [US1] State in `docs/architecture.md` what happens when a target cannot honour a construct (FR-007): a named failure, never a substitution, an approximation or a silent omission — US1 Acceptance Scenario 6 requires this of the MVP
- [X] T031 [US1] Write the k6 walkthrough in `docs/architecture.md` over `docs/examples/checkout-perf.yaml`, tracing requirement → criterion → verdict → gate → outcome. Declare the gap: the ratio indicator cannot render as a k6 threshold, because selectors become k6 tags and `error.type` is derived from a separate metric via `errorSignal`
- [X] T032 [US1] Write the JMeter walkthrough in `docs/architecture.md` over the same document. Declare conformance `report`, addressing via `routeHints`, and that no criterion renders natively
- [X] T033 [US1] Write the Gatling walkthrough in `docs/architecture.md` over the same document, **from the dated survey alone** — `docs/examples/` has no Gatling mapping and FR-025 forbids creating one here. Declare every gap, including `onViolation: abort` being impossible, and name `target-gatling` as the follow-up that will supply the mapping
- [X] T034 [US1] Define the two target classes in `docs/architecture.md` and state that support for each is added as data. Mark the four monitoring backends as an **explicitly unverified, dated claim** owned by the parked follow-up spec (FR-004)
- [X] T035 [US1] Cite `data source` from ADR-0002 § D18 in `docs/architecture.md` rather than redefining it, and cite `monitoring backend` from the glossary entry created in T010. Always write `data source` in full — the bare noun already carries four committed senses
- [X] T036 [US1] State the architecture document's own amendment procedure in `docs/architecture.md`: an ordinary PR editing it, landing before the diverging spec, **no decision record required** — the sanctioned route must stay cheaper than the workaround (FR-023)
- [X] T037 [US1] Create `docs/experimental/README.md` as the parked monitoring direction's status page: experimental status, promotion conditions, retirement conditions, the date, and the follow-up spec that owns it (FR-018, SC-011)
- [X] T038 [US1] Add the two containment rules to `docs/experimental/README.md` and to the architecture document: no markdown link points into the area from outside it, and the area holds markdown only. Without both, SC-007's one-operation deletion turns `scripts/verify.sh` red
- [X] T039 [US1] [P] Add `docs/architecture.md` to the Documents tables in `README.md` and `docs/README.md` — a document nothing links to is not published, and nothing in `verify.sh` catches the omission
- [X] T040 [US1] Run the SC-007 check from [quickstart.md](quickstart.md) § 2: `git rm -r docs/experimental && bash scripts/verify.sh` must stay green, then restore
- [ ] T041 [US1] Open the architecture PR with issue T004's closing link

**Checkpoint**: MVP. A newcomer can trace a requirement to an outcome from one document.

---

## Phase 5: User Story 3 — A contributor changes exactly one thing (Priority: P3)

**Goal**: Every artifact class has one home, one rule for changing it, and a published list of
what is currently mis-filed.

**Independent Test**: Hand `docs/layout.md` to someone who has not read the rest and ask them
to list every file they would create to add a new load generator, and every file they would
need permission to touch.

- [X] T042 [US3] Create `docs/layout.md` with the artifact-class table from [data-model.md](data-model.md) § 1 — six classes, one home each, following the row shape in [contracts/repository-shapes.md](contracts/repository-shapes.md)
- [X] T043 [US3] Make the "who may change it" column uniform in `docs/layout.md` — "Anyone, by pull request" in every row — and add the two sentences that carry the argument: classes differ by what a change obliges, not by who may propose it. Introduce no role vocabulary (FR-014)
- [X] T044 [US3] State in `docs/layout.md` who assigns the milestone and closing link on an outside contributor's behalf, since `scripts/check-linkage.sh` gates on both and a fork PR normally cannot set a milestone — without this the uniform column is theatre
- [X] T045 [US3] File `docs/semconv/` into the normative core in `docs/layout.md` by widening that class's definition: it includes the `loadtest.*` registry, the only core artifact whose upstream status is unratified, which states so in its own dated text (FR-015)
- [X] T046 [US3] Define the governance words in `docs/layout.md` — `artifact class`, `home`, `normative core`, `compatibility-sensitive surface`, `experimental area`, `follow-up spec`, `obligation`, `non-conformance list`, `component role`, and the two words this feature invents, `tool mapping` and `file adapter` — each with one rejected alternative, and none of them also in the glossary (FR-012, SC-013)
- [X] T047 [US3] Publish the non-conformance list in `docs/layout.md` — six entries, each with the obligation its eventual move carries. Record that moving the two tool mappings out of `docs/examples/` slips them past the sketch-label check, which is hardcoded to that directory (FR-013)
- [X] T047a [US3] Publish the target-contribution procedure in `docs/layout.md` (FR-020): what artifact to write, what conformance level it claims, and how that claim is evidenced — a dated manual verification against the tool's documentation, declared unenforceable until the conformance corpus lands
- [X] T048 [US3] Add the sentence excluding `specs/` from the layout table in `docs/layout.md`, plus the one-directional flow rule: a follow-up spec writes into the homes this table names and never becomes one
- [X] T049 [US3] Discharge FR-017 in `docs/layout.md` with a **pointer** to the constitution's compatibility-surface list plus the per-class yes/partly/no column — republishing would create a second copy that can drift, which the constitution's supremacy clause makes wrong by definition
- [X] T050 [US3] Answer FR-016 in `docs/layout.md`: which side is authoritative when a tool-native integration in another repository drifts. No committed text answers this today — `grep -r authoritative` returns nothing. Assign detection to the conformance-corpus follow-up, since every mechanism is an artifact FR-025 forbids
- [X] T051 [US3] [P] Add `docs/layout.md` to the Documents tables in `README.md` and `docs/README.md`
- [X] T052 [US3] Run the SC-013 check from [quickstart.md](quickstart.md) § 4: every introduced word defined in exactly one home, and no artifact class still called a "binding"
- [ ] T053 [US3] Open the layout PR with issue T005's closing link

**Checkpoint**: A contributor can find one home for any change.

---

## Phase 6: User Story 4 — The work ahead is cut into separate specs (Priority: P4)

**Goal**: A named, non-overlapping list of the follow-up specs, with dependencies stated rather
than implied by numbering.

**Independent Test**: Check every entry for a boundary, a dependency and an architectural role.
Check that no individual deliverable appears in two entries.

- [X] T054 [US4] Add the follow-up list to `docs/architecture.md` — eleven entries, each with what it delivers (concrete files), what it depends on, and the component role it fills, in the row shape from [contracts/repository-shapes.md](contracts/repository-shapes.md)
- [X] T055 [US4] Name entries by slug, never by ordinal, and add the sentence saying `specs/NNN-` records creation order and not completion order — `001-nfr-format-architecture` already sets a numbering a reader will read as a schedule
- [X] T056 [US4] State the dependency graph explicitly in `docs/architecture.md` as edges between slugs
- [X] T057 [US4] Give the parked monitoring entry promotion and retirement conditions instead of a schedule position (SC-011): promotion requires one unchanged requirement document assembling a valid query for **all four** backends, each check dated and sourced. Three of four is a narrower scope, and narrowing amends the architecture
- [X] T058 [US4] Identify `target-gatling` as the entry serving `gatling-picatinny#236` and record the concrete answer (FR-024, SC-009): picatinny 2.0 removes `assertionFromYaml` without a one-to-one replacement and documents the native Gatling DSL, while the migration note names OpenNFR's Gatling target as the intended successor
- [X] T059 [US4] Reconcile `docs/README.md`'s stated next step — "A JSON Schema for the requirement and result documents" — with the list, naming the core-schema entry as exactly that and first in dependency order
- [X] T060 [US4] Verify SC-008 by enumerating every claimed file across all eleven entries and counting deliverables claimed twice; the expected count is zero
- [ ] T061 [US4] Open the follow-up-list PR with issue T006's closing link

**Checkpoint**: Every later spec has a boundary and knows what it depends on.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T062 [P] Open an issue for the `overall-availability` silent RED: a run where nothing fails produces no series carrying `error.type` → `noData` → `onNoData: fail`, so the run fails because the system was perfect
- [ ] T063 [P] Open an issue for the unmeasurable-guard misrouting: a guard on a metric a target cannot measure lands on `onNoData: fail` rather than `onGuardViolation: inconclusive`, so a tool limitation reads as a system failure
- [ ] T064 [P] Open an issue for the `skipped` verdict status having no `gate` key in `docs/GLOSSARY.md` — it appears in the status enum and in `docs/examples/checkout-perf.report.yaml`, but no gate key handles it, and silence is undefined behaviour under Principle III
- [ ] T065 [P] Open an issue for `indicatorRef: checkout-latency` in `docs/examples/checkout-perf.yaml` pointing at a Requirement name while ADR-0001 § D10 describes `Indicator` as a reusable kind of its own
- [X] T066 Run the full [quickstart.md](quickstart.md) sweep — all six executable checks — and record the seven read-only criteria as reviewed
- [X] T067 Verify SC-010 with `git diff --name-only main...HEAD | grep -vE '\.(md)$|^specs/|^\.gitignore$'` returning empty: nothing executable shipped
- [ ] T068 Confirm every PR in this feature carries milestone `v0.2.0` and a closing link, then close each issue as its PR lands on `main`

---

## Dependencies

```text
Phase 1 (setup)
   └─> Phase 2 (glossary)          ← blocks everything; both documents are made of these words
          └─> Phase 3 / US2 (amendment)   ← must land before any document written against it
                 └─> Phase 4 / US1 (architecture)  🎯 MVP
                        ├─> Phase 5 / US3 (layout)
                        └─> Phase 6 / US4 (follow-up list, appends to architecture.md)
                               └─> Phase 7 (polish)
```

**Story dependencies**, which are unusually tight for this template because the constitution
imposes an order priority does not:

- **US2 → US1**: the architecture document must be written against the amended constitution.
- **US1 → US3**: the layout document names homes the architecture document already refers to.
- **US1 → US4**: the follow-up list is a section of `docs/architecture.md`, so it needs the
  file to exist. It ships as its own PR because the decomposition is a separate concern.
- **US3 and US4 are independent of each other** and can run in parallel once US1 lands.

## Parallel opportunities

- **Phase 1**: T003–T006 are four independent issue creations. T008 is unrelated cleanup.
- **Phase 2**: T012 touches only the diagram; the rest touch entries.
- **Phase 4**: T039 (index rows) is independent of the walkthrough tasks. The three
  walkthroughs T031–T033 touch one file and must be serialised.
- **Phase 5 and Phase 6** run in parallel once Phase 4 lands.
- **Phase 7**: T062–T065 are four independent issue creations.

## Implementation strategy

**MVP is Phase 4 (US1)** — but it cannot ship alone. Phases 1–3 are its price of entry: without
the milestone CI rejects the PR, without the glossary the document uses unsettled words, and
without the amendment it is written against text the constitution will overrule.

The smallest thing worth showing anyone is therefore **Phases 1 → 4**: a newcomer can trace a
requirement to an outcome, three walkthroughs prove the format reaches three tools, and the
parked experiment is honestly labelled and provably removable.

**One decision blocks Phase 3 and needs the author, not an implementer**: T015, the fate of
"Experiments Are Parked, Not Merged". Everything else in this list can be executed as written.
