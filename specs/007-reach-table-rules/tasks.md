---

description: "Task list for 007-reach-table-rules (milestone v0.4.0)"
---

# Tasks: The Rules By Which The Reach Tables Are Read

**Input**: Design documents from `/specs/007-reach-table-rules/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/reach-selection.md](./contracts/reach-selection.md), [quickstart.md](./quickstart.md)

**Tests**: this repository's test model is `bash scripts/verify.sh` and nothing else. Tasks that add
a probe are not "test tasks" in the template's sense — a probe is how a **cannot** rule is
demonstrated at all, required by spec FR-008, not an optional extra.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel — different files, no dependency on an incomplete task
- **[Story]**: which user story the task serves (US1…US5 from [spec.md](./spec.md))
- Every task names the file it changes

## Phases are ordered by commit, not by priority

Priorities in [spec.md](./spec.md) rank **value**: US1 is the `severity:critical` defect. The order
below is what can actually be built, from [research.md](./research.md) R7 — each later commit writes
rows into a table the earlier one repaired.

| Phase | Commit | Closes | Stories | Priority |
|---|---|---|---|---|
| 2 | `fix(contract): three sentences that are not true as written` | #64 | US3, US4, US5 | P3, P4, P5 |
| 3 | `fix(contract): a selection row constrains its value` | #60 | US2 | P2 |
| 4 | `fix(contract): "*" selects every named request, and says so` | #55, #56 | US1 | P1 |

**Foundational phase**: the template's Phase 2 is empty here. Nothing blocks every story — US3, US4
and US5 are documentation edits with no shared prerequisite. The one piece of shared machinery, the
probe harness in the reach gate, is introduced by the first commit that needs it (T009, Phase 3) and
reused by Phase 4. It is called out there rather than hoisted, so that every commit stays green on
its own, which `AGENTS.md` requires.

---

## Phase 1: Setup

**Purpose**: know what the numbers are before anything moves, so a change that shifts one is visible.

- [X] T001 Run `bash scripts/verify.sh` and confirm the counts recorded in `specs/007-reach-table-rules/quickstart.md` § 0 still hold (9 predicates; 24 embedded examples and 54 closures; 25 links out of `docs/`; 150 internal links). Correct that section if any has moved since 2026-08-24.

**Checkpoint**: baseline recorded. Phases 2 and 3–4 are independent of each other from here and may be worked in parallel by two people; they touch the same file in different sections, so stack the PRs and rebase rather than merge.

---

## Phase 2: Three sentences that are not true (US3, US4, US5) — commit 1, closes #64

**Goal**: every sentence in the published text is true as written, and every citation resolves.

**Independent test**: follow each constitution citation in the contract and confirm it names a clause the constitution contains; look up `p1`, `p10` and `p99.99` and confirm each matches exactly one row; ask of each quantity in `README.md`'s exclusion whether the stated reason is true of it.

- [X] T002 [P] [US3] Rewrite the percentile row at `specs/004-strip-to-schema/contracts/gatling-reach.md:41` to name any percentile the schema's pattern admits, quoting `^p\d{1,2}(\.\d+)?$` as the authority, and drop the `p50`…`p99.9` ellipsis. Add the one-line note that `p100` falls outside the pattern and needs no row, its quantity being `max` — research.md R3.
- [X] T003 [P] [US5] Replace the Principle III citation at `specs/004-strip-to-schema/contracts/gatling-reach.md:67-68` with the argument from what the rule costs: a `bad` narrower than "an error happened" has no `failedRequests` equivalent, so a renderer meeting one must pick a nearest available number, and the rule exists to stop that being done silently — research.md R5.
- [X] T004 [P] [US5] Replace the Principle III citation at `specs/004-strip-to-schema/contracts/gatling-reach.md:92-93` with the argument that rounding moves the bar the author wrote, so the document says one thing and the run checks another — research.md R5.
> **A defect this feature left alone, fixed elsewhere.** `specs/004-strip-to-schema/contracts/gatling-reach.md`
> held a row of the Units table orphaned below the paragraph T004 edits, with three cells where that
> table has four columns. It was out of scope here — `AGENTS.md` forbids opportunistic changes outside
> the issue, and it belonged to no milestone-v0.4.0 issue — and it landed on `main` on its own as
> `dd7a5ef`, *put the unreachable-units row back in the Units table*. This branch rebased onto it; the
> conflict is in the paragraph T004 rewrites, and resolving it means taking the Units table from `main`
> and the paragraph from T004. T004 still does not touch that row.

- [X] T005 [P] [US4] Remove apdex from the derived-quantities sentence at `README.md:390-391`, leaving throughput and error rate, of which the stated reason is true. Do not weaken the exclusion itself.
- [X] T006 [US4] Add an apdex entry to `docs/ideas.md` § *Fields argued for and left out*, opening with `**apdex**` at line start so the gate counts it, naming the two missing constructs — a banded classification against two thresholds (T, 4T) and a weighted aggregation over those bands — and closing with a `*Would need*` clause. Keep the existing `loadtest.apdex` (composite) mention in the `loadtest.*` registry list: that is about a name not entering a namespace — research.md R4.
- [X] T007 [US4] Run `bash scripts/verify.sh` and confirm § *docs/ is isolated* still reports every idea stating its condition; a new entry without its `*Would need*` clause fails that line, which is Principle VIII's gate rather than a convention. Fix `docs/ideas.md` if it does not balance.
- [X] T008 [US3] Confirm `specs/004-strip-to-schema/contracts/gatling-reach.md` contains zero occurrences of `Principle III` and that both rules edited by T003 and T004 still state why they hold.

**Checkpoint**: commit 1 is green and shippable on its own. No gate behaviour changed; the corpus is untouched.

---

## Phase 3: A selection row constrains its value (US2) — commit 2, closes #60

**Goal**: the rule that an assertion path part is a string lives in the contract, with the gate as its check — the reverse of how it stands today.

**Independent test**: hand the gate a document whose path value is a number and one whose value is a boolean; both are rejected, and the reason each names is a sentence findable in the contract.

- [X] T009 [US2] Add a probe harness to `scripts/verify.sh` § *Examples are assertable by Gatling*: a base document known to be assertable, a table of mutations each of which must be rejected, and a floor that FAILs the section if the table is empty. Mirror the shape already at `scripts/verify.sh:381-474` in the schema section. The section must keep reading `examples/` and never the schema — research.md R6.
- [X] T010 [US2] Add the value constraint to the Selection table in `specs/004-strip-to-schema/contracts/gatling-reach.md`: a value carried by `loadtest.group.name` or `loadtest.request.name` and rendered as a path part is a string, sourced to `AssertionPathParts(parts: List[String])`, with a **cannot** row for any path value that is not a string. State that `{loadtest.request.name: 200}` and `{loadtest.request.name: "200"}` are different documents and only the second is renderable — contracts/reach-selection.md.
- [X] T011 [US2] Keep the existing value check in `scripts/verify.sh` (`an assertion path part must be a string`) and move its authority: the message stays, and the contract is now where the rule is written. Confirm the rejection path still fires for a numeric and a boolean value.
- [X] T012 [P] [US2] Add a probe to `scripts/verify.sh` for a numeric path value (`{loadtest.request.name: 200}`), asserting it is rejected naming the string rule.
- [X] T013 [P] [US2] Add a probe to `scripts/verify.sh` for a boolean path value (`{loadtest.request.name: on}`, which YAML 1.1 reads as `true`), asserting the message does not name only numbers.
- [X] T014 [US2] Delete the string rule from `scripts/verify.sh` temporarily and confirm the section FAILs, then restore it. A probe that cannot fail is the defect `specs/005-fix-milestone-bugs` FR-002 exists to prevent.

**Checkpoint**: commit 2 is green and shippable. The corpus is unchanged — its three documents all carry literal string paths.

---

## Phase 4: `"*"` selects every named request (US1) — commit 3, closes #55 and #56

**Goal**: the blanket requirement is writable, and it means one statement per observed request rather than one number over all of them.

**Independent test**: a document selecting `{loadtest.request.name: "*"}` is accepted and the contract names exactly one scope for it; the two selections that carry `"*"` alongside a path are rejected; a literal path value still renders as a literal path part.

**Depends on**: Phase 3 — the gate must be value-aware before a value can be given a meaning, and T009's harness carries this phase's probes.

- [X] T015 [US1] Redefine `"*"` in `GLOSSARY.md` § *selector* (line 56): the attribute is present **and** each distinct value is a statement of its own. Record the rejected alternative — mapping it to `global`, which makes the value redundant with `{}` — and what the old definition got wrong: it settled presence and left the quantifier unstated, so the value's only honest reading was one already spoken for. Principle I requires all of this in the same change; the argument lives in #55 and #56 — research.md R1.
- [X] T016 [P] [US1] Restate the same meaning in `README.md`'s selector table (line 246), where `"*"` currently reads "presence, not a glob". Keep "not a glob" — it is still true and still load-bearing.
- [X] T017 [P] [US1] Amend the `description` of `$defs/selector` in `schema/opennfr.io/v1/requirementset.schema.json` so all three definitions of `"*"` agree. Change the description string only — every constraint the schema makes stays byte for byte, and no document changes verdict — research.md R8.
- [X] T018 [US1] Apply the delta in `specs/007-reach-table-rules/contracts/reach-selection.md` to the Selection table in `specs/004-strip-to-schema/contracts/gatling-reach.md`: add the `forAll()` **can** row and the two `"*"`-with-a-path **cannot** rows, amend the two existing `details(...)` rows to require a string other than `"*"`, and add the sentence that the value is part of the correspondence. Rows that file does not list are left exactly as they are.
- [X] T019 [US1] Reattach the absent-data note in `specs/004-strip-to-schema/contracts/gatling-reach.md` § *Two things Gatling cannot do at all* to the `forAll()` row it now explains, so the contract stops documenting the behaviour of a scope no document can select — #56's second half.
- [X] T020 [US1] Update the **Checked** header of `specs/004-strip-to-schema/contracts/gatling-reach.md` to 2026-08-24 and cite `AssertionSupport.scala` for the claim that `ForAll` carries no author strings — spec FR-016, research.md R2.
- [X] T021 [US1] Teach `scripts/verify.sh` § *Examples are assertable by Gatling* the value rules: accept `"*"` when the key set is exactly `{loadtest.request.name}`; reject it in the group position and reject it on the request name when a group is also present, naming that a quantified selection cannot carry a path.
- [X] T022 [P] [US1] Add a probe to `scripts/verify.sh` for `{loadtest.group.name: Checkout, loadtest.request.name: "*"}`, asserting rejection.
- [X] T023 [P] [US1] Add a probe to `scripts/verify.sh` for `{loadtest.group.name: "*", loadtest.request.name: POST /checkout}`, asserting rejection.
- [X] T024 [US1] Add `examples/every-request-is-fast.yaml` — the blanket requirement, selecting `{loadtest.request.name: "*"}`, opening with the human sentence it is the writing of, as the other three corpus documents do. This is the only document exercising the new **can** row, so without it the accept path is asserted rather than checked — spec FR-010.
- [X] T025 [US1] Confirm `git diff main -- schema/` shows exactly one changed pair of lines, the `$defs/selector` description, and that `bash scripts/verify.sh` still reports `24 embedded examples valid, 54 closures still reject`. Either count moving means a constraint moved with the description.

**Checkpoint**: commit 3 is green. The milestone's stated goal holds — the Selection table partitions on (key set, value), and `"the tables partition each axis"` is true on the selection axis.

---

## Phase 5: Polish and release bookkeeping

- [X] T026 Walk `specs/007-reach-table-rules/quickstart.md` end to end and confirm every expected output matches, correcting the quickstart where reality differs rather than the other way round.
- [X] T027 Confirm `docs/` is still droppable in one operation, which Principle VIII requires and T006 added an entry to: copy `docs/` aside, `rm -rf docs`, run `bash scripts/verify.sh` (must stay green), then restore from the copy. Do **not** reach for `git stash`/`git checkout -- docs` while T006's entry is uncommitted — restoring from the index discards it, which is exactly what happened on the first attempt here.
- [ ] T028 Open three stacked PRs, one per commit, each with a conventional title, each assigned to milestone v0.4.0 before merge, rebased onto `main` rather than merged — `AGENTS.md`.
- [ ] T029 Close #64, #60, #55 and #56 as their commits land on `main`. Commit 3 names both #55 and #56; neither has a green commit that does not contain the other — research.md R7.

---

## Dependencies

```text
T001  setup
  ├── Phase 2 (commit 1, #64)   T002…T008   — independent of Phases 3 and 4
  └── Phase 3 (commit 2, #60)   T009…T014
        └── Phase 4 (commit 3, #55 #56)  T015…T025
              └── Phase 5  T026…T029
```

- T009 (probe harness) blocks T012, T013, T022, T023.
- T010 blocks T011: the contract states the rule before the gate is described as its check.
- T015 blocks T018: the term is redefined before a row maps it, which is Principle I's ordering — a term appears in the glossary before it appears anywhere else.
- T021 blocks T024: the corpus document must be accepted by a gate that knows the rule, not by one that has not learned it yet.

## Parallel opportunities

- **Across phases**: Phase 2 shares no line with Phases 3–4. Two people can work them at once; both touch `specs/004-strip-to-schema/contracts/gatling-reach.md`, so stack the PRs and rebase.
- **Within Phase 2**: T002, T003, T004, T005 are four separate edits in two files — all `[P]`. T006 follows T005 only by topic, not by dependency.
- **Within Phase 3**: T012 and T013 are two probes, independent once T009 exists.
- **Within Phase 4**: T016 and T017 restate T015's decision in two other files and can go in parallel with each other. T022 and T023 are independent probes.
- **Outside this feature**: none. The orphaned Units row was to have been fixed concurrently; that session was deleted without landing anything, and the row is left as found — see the note in Phase 2.

## Implementation strategy

**MVP**: Phases 3 and 4 together — commits 2 and 3. That is the smallest slice delivering the
milestone's stated goal, because it is US1 (the `severity:critical` defect) plus the value-awareness
US1 stands on. Phase 2 is fully independent and ships whenever; the milestone puts it first because
v0.7.0's two issues lean on the Principle III rewrite, not because anything here waits on it.

**Increment order**: commit 1 changes no behaviour and can land immediately. Commit 2 adds a rule the
gate already enforces, so it changes no verdict either — it moves where the rule is written and adds
the machinery to prove it. Only commit 3 changes what a document means, and it is the one that needs
`GLOSSARY.md`, `README.md` and the schema description to move together.

**What must stay true throughout**: `bash scripts/verify.sh` green after every commit; every
constraint in the schema unaltered; `.specify/memory/constitution.md` untouched; the reach gate
reading `examples/` and never the schema.
