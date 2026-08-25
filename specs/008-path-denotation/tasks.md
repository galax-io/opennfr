# Tasks: The Denotation Of A Path

**Input**: Design documents from `/specs/008-path-denotation/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/reach-selection.md](./contracts/reach-selection.md), [quickstart.md](./quickstart.md)

**Tests**: this repository has no test suite. `bash scripts/verify.sh` is the whole test model, and the probes inside it are what a test task means here. Nothing below adds a framework.

**Organization**: one phase per issue, in the order [research.md](./research.md) R5 verified by walking each commit against the gate. **1 issue = 1 commit = 1 PR**, and every commit is green on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel — different files, no dependency on an incomplete task
- **[Story]**: US1 = #68, US2 = #53, US3 = #54, US4 = #70, US5 = #71, US6 = #69

## Line numbers

Every line number below is against `HEAD` = `d464de4`, before any task has run. Once a phase lands, later phases' numbers shift — locate by the quoted text, not by the number.

---

## Phase 1: Setup

**Purpose**: make the tree green before the milestone starts.

- [X] T001 Commit the spec-kit artifacts as `docs(speckit): add 008-path-denotation spec/plan/tasks`, carrying **all six** files: `specs/008-path-denotation/spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/reach-selection.md`, `quickstart.md` and `tasks.md`. This is a prerequisite and not a formality — `plan.md` links `./research.md`, so committing the plan without the research leaves the gate failing on a dangling link ([research.md](./research.md) R5).
- [X] T002 Confirm `bash scripts/verify.sh` passes on the committed tree, and record the counts it prints — they are the baseline every later phase is compared against.

**Checkpoint**: `PASS`, and a clean export of the commit passes too.

---

## Phase 2: Foundational

**Purpose**: none. There is no shared prerequisite between the six issues — the gate reads `examples/`, the schema's *constraints* and markdown link targets, and never compares prose or `description` strings against anything, which is why five of the six phases below are green whatever they say ([research.md](./research.md) R5 §1).

The one coupling that exists is inside Phase 4, not between phases, and is handled there.

---

## Phase 3: User Story 1 — the reach contract has one home (#68, P1)

**Goal**: one copy of the correspondence, in `README.md`. The stale summary goes; the maintained tables arrive unchanged.

**Independent test**: `grep -rn 'forAll\|details(' --include='*.md' . | grep -v '^./specs'` — every hit inside `README.md`'s reach section, and `bash scripts/verify.sh` reports no dangling link.

**Why the tables move unchanged**: the contract already carries the post-#55/#56/#60/#64 form (spec 007 edited it); README's summary is the stale copy. This phase edits **zero rows** — folding later phases' row edits in would put three issues in one commit and make the move undiffable as a move.

- [X] T003 [US1] Replace the summary table at `README.md:510-520` with the six tables from `specs/004-strip-to-schema/contracts/gatling-reach.md`, verbatim, under a new `### Gatling` beneath the existing `## What any tool can actually run` (`README.md:499`). The contract's `##` headings become `###`/`####`. Keep `README.md:501-502` as the section opener — it is not in the contract. FR-001, FR-002.
- [X] T004 [US1] Merge `README.md:504-508` (the Gatling paragraph and its provenance note) with the contract's header into one provenance note: keep the four Scala source files and the dates 2026-08-20 and 2026-08-24, and **drop** `Source: mappings/gatling.yaml @ cb7cb58` — `mappings/` was deleted by `02829bd` and does not exist. Add no 2026-08-25 date here: this phase writes no row. FR-007.
- [X] T005 [US1] Delete `README.md:522-525`, a condensed copy of the contract's § *Two things Gatling cannot do at all*; the contract's fuller version arrives with T003 and carries the sentence the summary drops ("Neither is compensated for here"). Merge `README.md:527-530` with the contract's § *How this contract is applied* into one closing paragraph — that paragraph is FR-005's new home for "the gate is the only implementation".
- [X] T006 [US1] Reduce `specs/004-strip-to-schema/contracts/gatling-reach.md` to a single dated line stating that the contract moved to `README.md` § *What any tool can actually run*. Do **not** delete the file: six markdown links resolve to it, in `specs/004-strip-to-schema/quickstart.md:38`, `tasks.md:33`, `tasks.md:97`, `tasks.md:104`, `tasks.md:105`, `plan.md:41` and `plan.md:69`, and deleting it produces six failures under *Internal markdown links resolve* (reproduced, [research.md](./research.md) R5). No other file under `specs/` may be edited. FR-003, FR-004.
- [X] T007 [US1] Repoint `scripts/verify.sh:516-517` from the contract path to `README.md > "What any tool can actually run"`, as prose and **not** as a markdown link — `verify.sh` is not scanned by `scripts/mdlinks.py`, and plain prose keeps it inert to the link gate permanently. Keep the existing source and date; add nothing dated 2026-08-25 yet. FR-005.
- [X] T008 [US1] Resolve the three overlaps the move creates inside one document, each of which would otherwise be the two-copy defect one file smaller ([research.md](./research.md) R3): the contract's sentence saying `"*"`'s meaning is "restated in `README.md`" becomes self-referential and goes; "a selector cannot say an attribute is absent" stays once at `README.md:248-249` with the fraction table's `good` row pointing at it rather than restating it; the contract's list of unreachable units is the complement of README's own unit table at `README.md:360-363` — state which is derived from which or the two drift silently. FR-006, SC-002.
- [X] T009 [US1] Run `bash scripts/verify.sh`; it must pass with the link count unchanged. Commit as `fix(contract): the reach contract has one home, and it is README (#68)`.

**Checkpoint**: one copy, no dangling link, no row edited.

---

## Phase 4: User Story 2 — a hierarchy of any depth (#53, P2)

**Goal**: `loadtest.group.name` carries the enclosing groups as an ordered list, at any depth.

**Independent test**: the three-level requirement in [quickstart.md](./quickstart.md) § 1 validates and the gate accepts it. It cannot be written at all today.

**This phase cannot be split**, proven in both directions ([research.md](./research.md) R5 §2): the corpus alone gives six failures across two sections, the schema alone gives two — the corpus document *and* the schema's own embedded example. Schema, gate, schema example and corpus land together. That is one issue over three surfaces, which the rule permits.

- [X] T010 [US2] Add `properties` to `$defs/selector` in `schema/opennfr.io/v1/requirementset.schema.json`, naming exactly one attribute: `{"loadtest.group.name": {"type": "array", "items": {"type": "string"}, "minItems": 1}}`. Leave `additionalProperties` **exactly as it is** — beside, never instead of — so an array under any other attribute stays rejected. FR-008, FR-009, FR-010.
- [X] T011 [US2] Change `$defs/selector.examples[2]` in the same file from `"loadtest.group.name": "MyGroup"` to `["MyGroup"]`. Required in this commit: § *The schema holds up its own examples* catches it otherwise with `'MyGroup' is not of type 'array'`.
- [X] T012 [US2] Decide and hold **one** home for the list semantics in the schema: either the new `properties.loadtest.group.name` node or `$defs/selector.description`, never both. If both carry it, SC-009 fails at Phase 7 and the fix is a second edit to a node this phase already touched. The recommendation is `$defs/selector.description`, which is where Phase 7 puts everything else.
- [X] T013 [US2] In `scripts/verify.sh`, bind the two addressing attribute names to constants `HIERARCHY = "loadtest.group.name"` and `REQUEST = "loadtest.request.name"` above `SELECTIONS` (line 540), and respell `SELECTIONS` and `QUANTIFIABLE` (lines 540, 545) with them. Their **values do not change**; four literals of one attribute name are four chances to fix three of them.
- [X] T014 [US2] Add `path_parts(sel)` to `scripts/verify.sh` beside `selection_why()`: the enclosing groups outermost first, then the request name — `list(sel.get(HIERARCHY, [])) + ([sel[REQUEST]] if REQUEST in sel else [])`. Its docstring must say it is only ever called once the hierarchy is known to be a list, and why.
- [X] T015 [US2] Rewrite `selection_why()` (`scripts/verify.sh:593-607`) as an `if/elif` chain in this exact order: key set not in `SELECTIONS` → `NOT_A_PATH`; `HIERARCHY` present and not a `list` → `NOT_A_LIST`; `HIERARCHY` present and empty → `NO_GROUPS`; any part of `path_parts(sel)` not a string → `NOT_A_STRING`; any part `== "*"` and the key set not in `QUANTIFIABLE` → `QUANTIFIED`. **The order is a rule, not a style** — measured: a scalar hierarchy flattened before the `isinstance` check becomes one path part per character, `"Checkout"` becoming eight parts, all strings, silently accepted as an eight-deep hierarchy. Carry that reason in a comment. FR-016.
- [X] T016 [US2] Add the two new message constants beside the existing ones (`scripts/verify.sh:588-591`), so the rule and the probes cannot drift into different words: `NOT_A_LIST` ("a hierarchy: the enclosing groups outermost first, a list of names and never one name") and `NO_GROUPS` ("a request with no enclosing group is spelled by omitting the key").
- [X] T017 [US2] Replace the four `SELECTION_PROBES` (`scripts/verify.sh:626-631`) with the ten-row rejection table from [research.md](./research.md) R2 §3, respelled with `HIERARCHY`/`REQUEST`. Two dispositions matter: the probe at line 629 must have its group value become `["Checkout"]` or it trips `NOT_A_LIST` first and stops probing the quantifier at all; the probe at line 630 dies as written — the scalar spelling leaves the format — and is repurposed in place with `NOT_A_LIST` as its expected reason. FR-035.
- [X] T018 [US2] Add the `SELECTION_RENDERS` table — the five selectors that must produce **no** reason at all, ending with `{HIERARCHY: ["Checkout", "Payment"], REQUEST: "GET /test/id"}`. A rejection table cannot show that a row still renders and the corpus cannot either: nothing published nests two groups, so a one-group depth bound would leave every existing check green. Measured; the depth-2 render probe is the sole catcher. FR-035, SC-004.
- [X] T019 [US2] Replace the `if not SELECTION_PROBES` guard (`scripts/verify.sh:635-638`) with numeric floors just under both tables' counts, following the reasoning the closure floor at lines 476-481 already carries: with ten rows the realistic accident is pruning eight, not emptying the table. Extend the `ok` line (lines 696-698) to count the render probes too, so a section that checked nothing says so.
- [X] T020 [US2] Add four probes to § *The schema holds up its own examples, and still rejects* (after `scripts/verify.sh:430`) — a scalar `loadtest.group.name`, an empty list, a non-string element, and `{"http.route": ["a","b"]}`. They belong here and not in the Gatling section, which reads `examples/` and never the schema by a rule it carries in its own comments. Raise `FLOOR` (line 481) from 50 to 54. The fourth probe is the only thing that notices if `additionalProperties` later gains `"array"`. SC-005.
- [X] T021 [US2] Change `examples/fast-and-reliable.yaml`'s selector from `loadtest.group.name: Checkout` to `loadtest.group.name: [Checkout]`. The only corpus edit in the milestone. FR-018.
- [X] T022 [P] [US2] Rewrite `README.md` § `selector` (lines 228-249): the example block gains the list form and loses the scalar; the Values row states the one exception and that an array elsewhere is rejected; a new row states what `loadtest.group.name` is. Add the qualifier FR-013 requires to the Keys row at `README.md:244` — which attribute names are *admitted* is still not enumerated, and the schema names one attribute only to fix its value's shape. Check `README.md:188-189` ("keys are attribute names and cannot be enumerated in advance") and **leave it unchanged** — it stays true; naming one key to constrain its value does not enumerate which keys are admitted. FR-011, FR-013.
- [X] T023 [P] [US2] Rewrite `GLOSSARY.md` § *selector* (lines 53-72) with the arity, and extend its `*Rejected*` line with the three alternatives and why each fails: a separate `loadtest.group.path` key (two keys for one attribute — the name was never what was missing, the arity was, and a second spelling is what Principle II forbids); a scalar-or-array union (two spellings of one hierarchy); `[]` for "no enclosing group" (a third spelling of what omitting the key already says, and one that reads as "unconstrained" to whoever meets it first). Record what the scalar form got wrong. FR-012.
- [X] T024 [US2] ~~Add to `README.md` § *What the schema does not check* that an array under an attribute with no list meaning is valid and meaningless. FR-014.~~ **Withdrawn during review.** It cited an FR-014 that the specification's final rewrite had already dropped, and the sentence is false: FR-008 names the attribute in `properties` rather than widening `additionalProperties`, so an array under any other attribute is **rejected** — as the spec's own Edge Cases say and as T020's fourth closure probe enforces. The bullet was written and is now removed.
- [X] T025 [US2] Run `bash scripts/verify.sh`; expect the embedded-example and closure counts to rise and the selection probe counts to rise, with `PASS`. Run [quickstart.md](./quickstart.md) § 2 — all nine verdicts must match their comments. Commit as `feat(schema): loadtest.group.name spells a hierarchy of any depth (#53)`.

**Checkpoint**: a three-level requirement validates and renders; a scalar and an empty list are rejected by the **schema**, not only by the gate.

---

## Phase 5: User Story 3 — a selection row says which requests it denotes (#54, P3)

**Goal**: the anchoring rule, stated once, and every rendering row naming the set it denotes.

**Independent test**: hand a reader `examples/one-request-is-fast.yaml` and `examples/fast-and-reliable.yaml` — both name `POST /checkout` — and ask which Gatling scope each renders to. Both answers must come from the text.

**No logic changes here.** This phase is prose plus two probes.

- [X] T026 [US3] State the anchoring rule once in `README.md` § `selector`: **where a selector names a request, an absent `loadtest.group.name` means the empty hierarchy.** Say it is the only rule a selector has beyond equality, and that it needs no carve-out for `{}` or `"*"` because neither names a request. FR-014, FR-015, FR-016.
- [X] T027 [P] [US3] State the same rule in `GLOSSARY.md` § *selector*, deriving it from equality rather than from a special case, and say how it reads inside `bad` and `good` — the same, and inertly, since the only numerator any target renders names no request. FR-015, FR-020.
- [X] T028 [US3] Amend the two `details(...)` rows in `README.md`'s Selection table per [contracts/reach-selection.md](./contracts/reach-selection.md) § *Rows amended*: each names the set of recorded requests it denotes, and the two-part row absorbs every depth. FR-017.
- [X] T029 [US3] Add the **cannot** row for `{loadtest.group.name: [G₁…Gₙ]}` with no request name, giving it a meaning — the requests whose hierarchy is exactly those groups — and naming #52 as the open question about whether a group-scoped statement should exist at all. Do not settle #52. FR-019, FR-039.
- [X] T030 [US3] Attach the precondition to both `details(...)` rows: *the rendered path must not also be the full hierarchy of a recorded group*, with the reason and the date. Where it holds otherwise, Gatling resolves the collision out of a hash map and may measure the group's cumulated response time instead. Take the wording and the 2026-08-25 date from [research.md](./research.md) R1 — do not restate it from memory, and label the instability claim as a replication rather than a reading. State that `forAll()` is immune, because it never calls `findPathByParts`. FR-021, SC-003.
- [X] T031 [US3] Add rejection probes 1 and 2 from [research.md](./research.md) R2 §3 to `scripts/verify.sh` — `{"http.route": …}` for `NOT_A_PATH`, which is **unprobed today** (delete the whole key-set branch on the current file and the section stays green), and `{HIERARCHY: ["Checkout"]}` with no request name, which catches the accidental addition of that key set to `SELECTIONS`. FR-019, FR-035.
- [X] T032 [US3] Rewrite the comments at `scripts/verify.sh:538-539` to say what each key set **denotes** — `{}` global, a request name alone that request with no enclosing group, the pair that request at any depth — and why `{HIERARCHY}` alone is absent on purpose.
- [X] T033 [US3] Run `bash scripts/verify.sh`, then commit as `fix(contract): a selection row says which requests it denotes (#54)`.

**Checkpoint**: every rendering row denotes a stated set, under one dated precondition it cannot close.

---

## Phase 6: User Story 4 — the quantifier enumerates what the target enumerates (#70, P4)

**Goal**: one definition — *once of each request position the run records* — in every home but the schema.

**Independent test**: for a simulation recording one request name under two different hierarchies, every home says **two**, and hand-expanding the quantifier into singular rows yields the same two statements.

**This phase does not touch the schema.** The schema's only statement of `"*"` sits on the node Phase 7 exists to correct; writing the new definition there and deleting it one commit later is add-then-remove across a stack, which `AGENTS.md` forbids. FR-024, SC-007 and SC-009 are milestone-end criteria satisfied at Phase 7, and this phase's PR is not to be failed for them ([research.md](./research.md) R5 §4).

- [X] T034 [US4] Replace the quantifier's definition in `README.md` § `selector` with *stated once of each request position the selector admits* — a position being a request's enclosing groups, in order, then its name. Say explicitly what it is not: not once per distinct attribute value, not once per occurrence. One name under two different hierarchies is two statements; one position hit a thousand times is one. FR-022.
- [X] T035 [P] [US4] Replace the same definition in `GLOSSARY.md` § *selector*, and extend `*Rejected*` with both retracted granularities and why each failed: per distinct value (#55/#56, retracted by #70 — it counts names while the run counts positions, so a document could pass on a pooled number while one of its positions failed) and per occurrence (a granularity no target has). FR-025, FR-027.
- [X] T036 [US4] Make the prose gloss beside the definition, in `README.md` § `selector` and `GLOSSARY.md` § *selector*, say what the definition says. "One bar per named request" and "each distinct value is a statement of its own" currently sit in one sentence as though they were one claim; they are not, and that is half of what #70 reports. FR-024.
- [X] T037 [US4] Derive the quantified row from the anchoring rule rather than exempting it: `"*"` is not a name, so the rule does not fire and no hierarchy is claimed — which is why it reaches a scope carrying no path. State that the quantified row now instantiates into the singular rows at every depth, which is what the unbounded hierarchy bought. FR-023, FR-025.
- [X] T038 [US4] Restate the `forAll()` row's count in `README.md`'s Selection table as *one statement per recorded request position*, sourced: `allRequestPaths()` `collect`s only the request keys of a map, so groups are discarded and each `(hierarchy, name)` pair appears once. The verdict is unchanged from #56; only the count changes. FR-022, FR-024.
- [X] T039 [US4] Retext `QUANTIFIED` in `scripts/verify.sh:591`. Its current text asserts the selection *is quantified*, which under FR-022 is false of `{HIERARCHY: ["*"], REQUEST: X}` — `"*"` quantifies only in place of a request name. A diagnostic that misnames the fault is what lines 492-497 already treat as a defect.
- [X] T040 [US4] Add rejection probes 9 and 10 from [research.md](./research.md) R2 §3 — `{HIERARCHY: ["Checkout"], REQUEST: "*"}` and `{HIERARCHY: ["*"], REQUEST: "POST /checkout"}`. The second is the **only** probe that distinguishes `path_parts(sel)` from `sel.values()` in the `"*"` test: under `sel.values()` a hierarchy is a list and never equals `"*"`, so the branch goes silently dead and `{HIERARCHY: ["*"], …}` is accepted, rendering to `details("*" / "X")` — the defect #55 closed, re-entering through the arity change. FR-035.
- [X] T041 [US4] Update the comments at `scripts/verify.sh:542-544` (where a `"*"` may sit, now that a `"*"` group value is a scalar rejection) and `603-605`, which still carry the retracted definition verbatim — that comment is #70's fourth home and the easiest one to miss.
- [X] T042 [US4] Run `bash scripts/verify.sh`, then run [quickstart.md](./quickstart.md) § 5 and confirm three of the four homes agree; the schema's will not until Phase 7, by design. Commit as `fix(contract): the quantifier enumerates what forAll() enumerates (#70)`.

**Checkpoint**: three homes agree and say what the target does.

---

## Phase 7: User Story 5 — the schema's semantics sit on the node that defines one (#71, P5)

**Goal**: `$defs/selector` carries the value semantics; the annotation beside `$ref` carries none of them.

**Independent test**: read `$defs/selector.description` with no other file open. It must state the same rule as `GLOSSARY.md`, and the rule must appear once in the schema.

**Nothing in `scripts/verify.sh` changes.** There is no probe for a `description`, so SC-009 is checked by reading. Recorded here as a known gap rather than left as an omission.

- [X] T043 [US5] Rewrite `$defs/selector.description` in `schema/opennfr.io/v1/requirementset.schema.json` to carry all of it, reading correctly **alone** because `bad` and `good` inherit it: equality; the list form and what it denotes; the anchoring rule; the quantifier over recorded request positions; and that `"*"` does not quantify inside `bad` or `good`. FR-026, FR-028.
- [X] T044 [US5] Strip `$defs/requirement.properties.selector.description` to what is true of a requirement's selector and of no other selector — that it is written once and binds every criterion and guard beneath it — and to nothing else. That sentence is also what Phase 8 needs stated. FR-029.
- [X] T045 [US5] Confirm the rule is in the schema **once**: if Phase 4's T012 put the list semantics on the `properties.loadtest.group.name` node, remove it there now. SC-009.
- [X] T046 [US5] Confirm every constraint in `schema/opennfr.io/v1/requirementset.schema.json` is otherwise byte-identical to its state after Phase 4 — only descriptions change in this phase. FR-030.
- [X] T047 [US5] Run `bash scripts/verify.sh` and [quickstart.md](./quickstart.md) § 5; all four homes must now agree. Commit as `fix(schema): the selector's semantics sit on the node that defines one (#71)`.

**Checkpoint**: FR-024, SC-007 and SC-009 are met — the milestone-end criteria deferred from Phase 6.

---

## Phase 8: User Story 6 — a guard under a quantified selector is quantified too (#69, P6)

**Goal**: the example says where the guard has to sit, and that today it cannot sit alone.

**Independent test**: follow the note in `examples/every-request-is-fast.yaml` to its remedy and check the remedy applies to the document that sent you there.

- [X] T048 [US6] Amend the comment in `examples/every-request-is-fast.yaml` that points at `the-run-held-up.yaml`: the guard that says the run happened works **there** because that document says `{}`, and under a quantified selector it renders `forAll().requestsPerSec…`, stating its condition of each position and expanding to zero assertions on a run that recorded nothing. Say that the guard has to sit on a `{}` requirement, and that today it cannot sit alone — `requirement.required` is `["name","selector","criteria"]` and `criteria` is `minItems: 1`, which is #61. FR-029 of the spec, FR-031.
- [X] T049 [US6] Add the note to `README.md`'s Selection table that a requirement's guards are quantified with its criteria, because the selector is written once for both. FR-032.
- [X] T050 [US6] Add one comment line at `scripts/verify.sh:657` (`for section in ("guards", "criteria")`) saying the same selector judges both because it is written once for both. This is the machine-checkable half of FR-032 and it already works — no logic changes.
- [X] T051 [US6] Confirm this phase adds no per-guard selector and does not relax `requirement.required`; #61 stays open and untouched. FR-033.
- [X] T052 [US6] Run `bash scripts/verify.sh`, then commit as `fix(examples): a guard under a quantified selector is quantified too (#69)`.

**Checkpoint**: the pointer added a release ago resolves in both directions.

---

## Phase 9: Polish and cross-cutting

- [X] T053 Walk [quickstart.md](./quickstart.md) end to end on the finished tree — all seven sections, including § 3's deletion sweep. Every rule must redden the gate when deleted; two are caught by exactly one probe each and neither may be dropped as redundant: a depth bound placed *after* the shape checks (only the depth-2 render probe catches it) and `additionalProperties` gaining `"array"` (only the fourth closure probe). SC-010.
- [X] T054 [P] Confirm `git diff --stat main -- examples/` shows one value and one comment. Three of four published documents unchanged. SC-006.
- [X] T055 [P] Confirm `git rm -r docs && bash scripts/verify.sh` still passes, and restore. Principle VIII.
- [X] T056 [P] Re-read `README.md`, `GLOSSARY.md` and `specs/008-path-denotation/contracts/reach-selection.md` and confirm no premise of #52, #57, #62, #58, #59, #72, #73, #74, #75, #61 or #63 has been settled by implication, and that #52's substantive half — a group assertion measures a cumulated duration the Metrics table cannot name — is intact. FR-039.
- [ ] T057 Assign all six PRs to milestone **v0.5.0** and confirm each closes its issue on merge: #68, #53, #54, #70, #71, #69. A PR without a milestone does not merge.

---

## Dependencies

```text
Phase 1 (setup) ─── blocks everything: the tree is red until research.md is committed
   │
   ├─ Phase 3  #68  one home ......... must precede 5, 6, 8 (they edit rows; two copies would mean two edits)
   │     │
   │     ├─ Phase 4  #53  the hierarchy ...... must precede 5 and 6
   │     │      │
   │     │      ├─ Phase 5  #54  denotation ..... independent of 6
   │     │      └─ Phase 6  #70  quantifier ..... needs 4 (probe 10 needs the array form)
   │     │              │
   │     │              └─ Phase 7  #71  the schema node ... carries what 4, 5 and 6 settled
   │     │
   │     └─ Phase 8  #69  the guard ....... needs only 3 (a table to write the note into)
   │
   └─ Phase 9  polish ....... after all six
```

**Why Phase 3 goes first**: mechanical, not editorial. Every row Phases 5, 6 and 8 touch exists in two copies until #68 lands, and editing one copy is how four closed issues came back to life.

**Why Phase 4 cannot be split**: measured both ways — corpus first gives six failures, schema first gives two, including the schema's own embedded example.

---

## Parallel opportunities

Within phases, `[P]` marks the tasks that touch different files and depend on nothing incomplete:

- **Phase 4**: T022 (`README.md`) and T023 (`GLOSSARY.md`) run alongside the schema and gate work.
- **Phase 5**: T027 (`GLOSSARY.md`) runs alongside the README work.
- **Phase 6**: T035 (`GLOSSARY.md`) runs alongside the README work.
- **Phase 9**: T054, T055 and T056 are three independent confirmations.

**Across phases**: none. Six issues, six commits, each green on its own — the sequence is the point, and stacking PRs with `--force-with-lease` is how they travel.

---

## Implementation strategy

**MVP is Phase 3 alone** (#68). It ships one copy of the correspondence and retires the page that tells a renderer to emit `details("*")` — the only defect in the milestone that hands a reader a rule the repository has already retracted. It edits no row and closes one issue.

**Next increment** is Phase 4 (#53), which is the only phase that changes what validates, and the only construct entering the format.

**Phases 5–8 are corrections to what the text says**, not to what it accepts. Each is independently shippable and each closes one issue.

**Two things this milestone deliberately does not do**: settle whether a group-scoped statement should exist (#52), and let a guard carry its own selection (#61). Both are named in the text this milestone writes, so a reader meeting the limitation finds the open question rather than silence.
