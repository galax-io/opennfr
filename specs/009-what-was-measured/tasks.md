---

description: "Task list for 009-what-was-measured (milestone v0.6.0)"
---

# Tasks: What Was Actually Measured

**Input**: Design documents from `specs/009-what-was-measured/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/)

**Tests**: This repository has no test framework and none is added. `bash scripts/verify.sh` is the gate, and the mutation checks in Phase 7 are the only thing resembling a test suite. Tasks that verify are written as verification tasks, not as test files.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel — different file, no dependency on an incomplete task
- **[Story]**: which user story the task belongs to (US1…US6, from [spec.md](spec.md))
- Every task names the exact file it touches

## Path Conventions

There is no source tree. The five files this feature changes are at the repository root:
`schema/opennfr.io/v1/requirementset.schema.json`, `README.md`, `GLOSSARY.md`, `scripts/verify.sh`,
`docs/ideas.md`. `examples/` is not edited.

## Phases are commits, and they are not in priority order

Two repository rules override the template's default shape and both are deliberate:

- **1 issue = 1 commit**, each green on `bash scripts/verify.sh` on its own. So a phase is a commit,
  and User Stories 1 and 2 share Phase 7 because both are issue #57.
- **The contestable commit lands last.** Phases run #78 → #77 → #62 → #52 → #57, which is *reverse*
  priority order. #57 (US1, US2) carries the milestone's only contestable argument — that
  `{metric, count}` stays valid in the format — and putting it last means a reviewer who disagrees
  reverts one commit and rebases nothing. Recorded in [plan.md](plan.md) § *The commit sequence*.

The smallest shippable increment is therefore **Phase 3 (#78)**, not "User Story 1".

---

## Phase 1: Setup (baselines)

**Purpose**: capture the numbers every later checkpoint compares against. The quickstart's checks are
written as before/after comparisons, and without the "before" they cannot fail.

- [X] T001 Run `bash scripts/verify.sh` at the branch point and record its printed counts — `24 embedded examples valid, 58 closures still reject`, `10 predicates assertable … 10 selection probes … 5 still rendered`, `198 checked`, `157 files` — in the PR description as the baseline
- [X] T002 [P] Run the four discriminating snippets in [quickstart.md](quickstart.md) checks 3, 5, 7 and 8 and confirm each reports the branch-point value (`False`, `GLOSSARY.md: 2`, `1 / 2 / 0 / 15`, three `False`). A snippet that already reports the post-feature value is a broken check, not a finished task
- [X] T003 [P] Confirm all five issues (#62, #52, #57, #78, #77) are assigned to milestone **v0.6.0** via `gh api repos/galax-io/opennfr/milestones`

**Checkpoint**: the before-state is written down and every quickstart check is known to discriminate.

---

## Phase 2: Foundational (blocking prerequisite)

**Purpose**: the spec-first rule. `AGENTS.md` requires the `specs/NNN-*/` artifacts to land in their
own commit **before** any `feat`/`fix`, never folded into one.

**⚠️ CRITICAL**: no issue commit may be made until T004 is done.

- [X] T004 Commit `specs/009-what-was-measured/` as `docs(speckit): add 009-what-was-measured spec/plan/tasks` — spec, plan, research, data-model, quickstart, both contracts and the checklist, with no repository-root file in the same commit

**Checkpoint**: the argument is on record and reviewable before anything it argues for is built.

---

## Phase 3: User Story 3 — the schema decides what the quantified document selects (#78, Priority: P2) 🎯 first increment

**Goal**: `$defs/selector` carries the anchoring rule's exception, so a consumer reading the artifact
that decides can evaluate the rule's trigger without opening another file.

**Independent Test**: print `$defs/selector.description` alone and answer three questions from it —
does `{loadtest.request.name: "*"}` trigger the anchoring rule, what positions does it range over,
and what may each key's value be. All three must be answerable from that text.

- [ ] T005 [US3] Add to `$defs/selector.description` in `schema/opennfr.io/v1/requirementset.schema.json`, immediately beside the anchoring rule, that `"*"` is not a name and therefore does not trigger it
- [ ] T006 [US3] Correct the same description's closing sentence about value types so it is true of `loadtest.group.name`, whose only admissible value is an array — correct it, do not delete it: it is what justifies `additionalProperties: {type: [string, number, boolean]}`
- [ ] T007 [US3] Verify `GLOSSARY.md` still contains **two** occurrences of `is not a name`. The first draft's deduplication is withdrawn (FR-010) — a `1` here means it was shipped anyway
- [ ] T008 [US3] Run `bash scripts/verify.sh`; confirm `58 closures still reject` is unchanged, since no schema rule is added
- [ ] T009 [US3] Run [quickstart.md](quickstart.md) checks 4 and 5; check 5 must now print `README.md: 1`, `GLOSSARY.md: 2`, schema `1` or more
- [ ] T010 [US3] Commit `fix(schema): the schema says "*" is not a name (#78)`, closing #78

**Checkpoint**: `examples/every-request-is-fast.yaml` is decidable from the schema. Shippable alone.

---

## Phase 4: User Story 4 — a `"*"` group element means one thing (#77, Priority: P3)

**Goal**: `"*"` means presence in every position it can occupy, in all three artifacts, and the
withdrawn reading is recorded with the argument that would revive it.

**Independent Test**: take `{loadtest.group.name: ["*"], loadtest.request.name: POST /checkout}` to
the schema, to `GLOSSARY.md` and to `README.md`. All three must answer *a group at that position with
any name*, and none may also say *a group whose recorded name is `*`*.

- [ ] T011 [US4] Add to `$defs/selector.description` in `schema/opennfr.io/v1/requirementset.schema.json` that a `"*"` element of `loadtest.group.name` is presence — a group at that position with any name — and never a group recorded under the name `*`
- [ ] T012 [P] [US4] Carry the same exception onto the literal-element sentence in `GLOSSARY.md` § *selector*, and add to its *Rejected* line the literal reading in its strongest form: an element of a list is not a value of the attribute
- [ ] T013 [P] [US4] Rewrite the `loadtest.group.name` cell in `README.md` § `selector` so it states one reading, and remove from it the clause `and no scope carries a wildcard path part` — a target fact belongs in the reach row, where it already is
- [ ] T014 [US4] Verify the document above still **validates** against the published schema — the format is not narrowed — and that `scripts/verify.sh` still refuses it with the `QUANTIFIED` reason, with `10` and `5` selection probe counts unchanged
- [ ] T015 [US4] Run [quickstart.md](quickstart.md) check 5, including its second snippet: the target fact must be `False` in the field description and `True` in the reach row
- [ ] T016 [US4] Commit `fix(schema): a "*" in a hierarchy element is presence (#77)`, closing #77

**Checkpoint**: one valid document, one published meaning. Nothing in the gate moved.

---

## Phase 5: User Story 5 — the metric axis says what it does not name (#62, Priority: P4)

**Goal**: the class #62 reports appears in the published text with its reason, and the reason
separates the half the format cannot spell from the half where the obstacle is missing evidence.

**Independent Test**: ask the published text what a document should say when the thing measured was
not one HTTP client request. It must answer for each half, and must assert nothing about an external
tool that the repository has not already dated.

- [ ] T017 [US5] In `README.md` § *Names* § *Metrics*, state the boundary the format genuinely cannot spell: a duration recorded for a span an author bracketed across several requests, for which `http.client.request.duration` is false
- [ ] T018 [US5] In the same section, state the other half differently — where semantic conventions name the operation, the general Names rule applies and such a document is valid today. Do **not** claim no name exists, and do **not** name a specific convention: this branch cannot check and date one (FR-016)
- [ ] T019 [US5] Amend the existing `any other` row of `README.md`'s Gatling Metrics table with its reason. Add no row: the left column holds metric names, and a prose class can never be matched in a table whose law is "matches a row exactly"
- [ ] T020 [P] [US5] Add to `GLOSSARY.md` § *metric*'s *Rejected* line the name this milestone declined to mint, and why — the minting bar, which is this milestone's durable decision
- [ ] T021 [P] [US5] Add one clause naming the composite-span case to the **existing** `loadtest.*` registry entry in `docs/ideas.md`. Add no entry: the isolation gate requires the count of `^**…**` entries to equal the count of `*Would need*` lines
- [ ] T022 [US5] Run `bash scripts/verify.sh` and confirm the `docs/ is isolated` section still passes with equal counts; run `git rm -r docs && bash scripts/verify.sh` in a scratch clone to confirm it stays green, then discard
- [ ] T023 [US5] Run [quickstart.md](quickstart.md) check 9: no added line may assert a new property of `responseTime`, of `logResponse` or of any scope without a source and a date added in the same change
- [ ] T024 [US5] Commit `fix(contract): the metric axis says what it does not name (#62)`, closing #62

**Checkpoint**: the case appears with its reason, and no name was minted.

---

## Phase 6: User Story 6 — the group-only selection is decided, not open (#52, Priority: P5)

**Goal**: the row stops deferring, and its reason holds for every predicate shape it governs —
including one carrying no metric, which the old reason did not cover.

**Independent Test**: read the row and answer whether a renderer should implement the shape. The
answer must be no, for a reason that holds with a metric and without one, and that depends on nothing
undated.

- [ ] T025 [US6] Rewrite the reason on the group-only row of `README.md`'s Selection table: it denotes the requests whose hierarchy is exactly those groups, and **no scope denotes the requests a path encloses** — the scopes are `Global`, `ForAll` and `Details(parts)`, and `Details` on a group's path resolves to the group. Add that what the group scope does compute is a cumulated response time no name in § *Names* is true of
- [ ] T026 [US6] Remove the deferral `Whether a group-scoped statement should exist at all is open, as [#52](…)` from that row, and with it the only issue reference in the reach tables that stands in place of a reason. #61's reference stays: it records a real limitation with its provenance
- [ ] T027 [P] [US6] Remove the trailing `(#52)` from the comment above `SELECTIONS` in `scripts/verify.sh` and keep the sentence that gives the reason. Do **not** copy the row's paragraph in: `README.md` is the only place the tables are stated
- [ ] T028 [US6] Verify no behaviour changed — `SELECTIONS`, `QUANTIFIABLE`, `selection_why`, every probe and both floors untouched, and `{loadtest.group.name: ["Checkout"]}` still refused with `selector ['loadtest.group.name'] is not an assertion path`
- [ ] T029 [US6] Run [quickstart.md](quickstart.md) check 7; it must now print `0` deferrals and `1` issue reference, against the branch point's `1` and `2`
- [ ] T030 [US6] Commit `fix(contract): a group-only selection is a decided cannot (#52)`, closing #52

**Checkpoint**: no verdict in the reach tables is deferred.

---

## Phase 7: User Stories 1 and 2 — the gate stops rendering what the tables reject (#57, Priority: P1) — **last, deliberately**

**Goal**: the gate stops producing an assertion from a shape the tables refuse and stops discarding a
field silently; the tables list the shape instead of excluding it by silence; and three reach axes
that have never been probed get their first probe list.

**Both stories are one commit** because both are issue #57.

**Independent Test**: put `{metric: http.client.request.duration, aggregation: count, …}` through the
schema — it must validate — and then through the gate inside `examples/` — it must be refused by
name. Then restore the deleted `TABLE["metric"]` row and confirm the gate goes red.

### The gate and the tables (US1)

- [ ] T031 [US1] Delete the `"count"` and `"rate"` entries from `TABLE["metric"]` in `scripts/verify.sh`. They are byte-identical to the `"requests"` rows, which is why the `metric` key resolved to nothing and was reported nowhere
- [ ] T032 [P] [US1] Add `count` and `rate` rows marked **cannot** to `README.md` § *Aggregations* → *Over a metric*, each with its reason, so the shape is matched by a row rather than excluded by the table's silence
- [ ] T033 [P] [US1] Add to `GLOSSARY.md` § *aggregation*'s *Rejected* line the schema-rule outcome and the binding constraint it would have broken, plus the outcome declaring the `metric` ignored, which Principle III forbids by name
- [ ] T034 [US1] Verify the **withdrawn** edits were not made: `README.md` § *What a criterion can be about*'s `metric` row still lists `count` and `rate`, § *A predicate*'s note about rule 4 is intact, and § *What you will see when it is wrong* has no new row
- [ ] T035 [US1] Verify `git diff main -- schema/` shows changes inside `$defs/selector.description` and nowhere else — no `allOf` branch, no `properties`, no `required`, no keyword

### The probe list (US2)

- [ ] T036 [US2] Add a predicate probe list to the Gatling section of `scripts/verify.sh`, in the shape `SELECTION_PROBES` has: each entry a predicate the tables refuse, paired with the reason its row gives. Cover `{metric, count}`, `{metric, rate}`, `{metric, sum}`, a non-addressable metric, `op: neq`, a percentile in `%`, and a fractional-millisecond threshold — the seven listed in [contracts/predicate-axes.md](contracts/predicate-axes.md)
- [ ] T037 [US2] Add its floor beside it, set to the probe count, with the comment the selection floors already carry: a probe that is gone cannot fail
- [ ] T038 [US2] Mutation check — restore `"count": ("allRequests.count", COUNT, True)` to `TABLE["metric"]`, run the gate, confirm it **fails** naming the `{metric, count}` probe, then revert
- [ ] T039 [US2] Mutation check — delete one predicate probe without lowering the floor, run the gate, confirm it **fails** naming the floor, then revert

### Close

- [ ] T040 [US1] Run `bash scripts/verify.sh`; confirm `58 closures still reject` and the corpus's `10 predicates assertable` are unchanged, and that the new predicate probe count is printed
- [ ] T041 [US1] Run [quickstart.md](quickstart.md) checks 1, 2, 3 and 6 in full, including copying the probe document into `examples/` to see the gate fail and removing it again
- [ ] T042 [US1] Commit `fix(contract): the gate stops rendering what the tables reject (#57)`, closing #57

**Checkpoint**: all five issues closed. This commit is revertable on its own.

---

## Phase 8: Polish, and what this milestone found but does not fix

- [ ] T043 Run every check in [quickstart.md](quickstart.md), all nine, against the finished branch
- [ ] T044 [P] Verify `GLOSSARY.md` still has fifteen `###` entries and that § *aggregation*, § *selector* and § *metric* each record what was rejected — quickstart check 8
- [ ] T045 [P] Verify `git diff main -- examples/` is empty
- [ ] T046 Confirm every pull request carries milestone **v0.6.0** and every issue is closed by the commit that landed its fix, per `scripts/check-linkage.sh`
- [ ] T047 [P] File a new issue for `$defs/aggregation.description`, which defines `rate` over a `distribution` and a `ratio` — neither is a term this schema contains, and `GLOSSARY.md` already carries the correct wording. Out of scope here: out-of-scope improvements do not travel inside an issue commit
- [ ] T048 Propose to the maintainer that the v0.6.0 milestone description be corrected. It says #62's answer *"also names the quantity a group path measures"* and that #52 *"adds its Selection row"*; neither is what is delivered, and under Principle IV a published artifact must not read as differently settled than the work. Editing the milestone is the maintainer's call, not this branch's

---

## Dependencies & Execution Order

### Phase dependencies

- **Phase 1 (Setup)** — no dependencies. T002 in particular must run *before* any file changes, or the discriminating checks cannot be shown to discriminate
- **Phase 2 (Foundational)** — depends on Phase 1. **Blocks every issue commit**: spec-first is a repository rule, not a preference
- **Phase 3 (#78)** — depends on Phase 2
- **Phase 4 (#77)** — depends on **Phase 3**. This is the milestone's only true story-to-story dependency: a `"*"` element is presence *because* `"*"` is never a name, and both edit `$defs/selector.description`
- **Phase 5 (#62)** and **Phase 6 (#52)** — depend on Phase 2 only. Independent of each other in content; sequenced because both edit `README.md` § *What any tool can actually run*
- **Phase 7 (#57)** — depends on Phase 2 only, and is placed last so it is revertable
- **Phase 8 (Polish)** — depends on Phases 3–7

### Story independence

Every story is independently shippable and independently revertable except the #78 → #77 pair. No
story consumes another's output: this milestone produces no artifact that another part reads.

### Parallel opportunities

Within a phase, tasks touching different files are marked `[P]`:

- Phase 1: T002 and T003 together
- Phase 4: T012 (`GLOSSARY.md`) and T013 (`README.md`) together, after T011 (schema)
- Phase 5: T020 (`GLOSSARY.md`) and T021 (`docs/ideas.md`) together, after the `README.md` tasks
- Phase 6: T027 (`scripts/verify.sh`) alongside T025–T026 (`README.md`)
- Phase 7: T032 (`README.md`) and T033 (`GLOSSARY.md`) together, after T031 (`scripts/verify.sh`)
- Phase 8: T044, T045 and T047 together

**Across phases: none.** A phase is a commit that must be green on its own, so two phases cannot be
open at once. That is the cost of the commit rule and it is deliberate.

---

## Parallel Example: Phase 4 (#77)

```bash
# T011 first — the schema, alone:
Task: "Add the presence rule for a '*' hierarchy element to $defs/selector.description"

# then T012 and T013 together, different files:
Task: "Carry the exception and the Rejected line into GLOSSARY.md § selector"
Task: "State one reading in README.md's loadtest.group.name cell and drop the target fact"
```

---

## Implementation Strategy

### First increment

Phases 1, 2 and 3. That closes #78 — the artifact that decides can decide the corpus's own flagship
document — and it is shippable, reviewable and revertable on its own. It is **not** "User Story 1":
the priority order and the commit order deliberately differ, and [plan.md](plan.md) records why.

### Incremental delivery

1. Phases 1–2 → the argument is on record
2. Phase 3 → #78 closed → the schema decides
3. Phase 4 → #77 closed → one meaning per `"*"` position
4. Phase 5 → #62 closed → the metric axis says what it does not name
5. Phase 6 → #52 closed → no deferred verdict in the reach tables
6. Phase 7 → #57 closed → the gate stops rendering what the tables reject
7. Phase 8 → the two follow-ups filed, neither of them this milestone's work

Stopping after any phase leaves the repository green and the milestone partly delivered, with the
undelivered issues untouched.

### If the review goes the other way on #57

Revert the Phase 7 commit. Nothing else moves — no other phase reads anything it produced. Then ship
`research.md` R1's form A, which is written and validated, plus the two closure probes it needs. The
condition that would justify that is in R2, and running it is one dated check against k6 and
Prometheus documentation.

---

## Notes

- `[P]` = different file, no dependency on an incomplete task
- Every phase ends with a gate run before its commit task; a commit that is not green on its own
  breaks the repository's own rule
- The corpus is never edited. If a task appears to require editing `examples/`, the task is wrong
- No task adds a term. If one appears to, it belongs in `GLOSSARY.md` as a rejected alternative
  instead, which is where this milestone's decisions live
