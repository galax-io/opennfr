---

description: "Tasks for 010-constitution-catches-up"
---

# Tasks: The Constitution Catches Up

**Input**: Design documents from `specs/010-constitution-catches-up/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: none. This milestone adds no check and changes no behaviour; nothing here is testable by a
script, and pretending otherwise would be the silent green Principle III forbids. Validation is the
eight reading checks in [quickstart.md](quickstart.md), and every checkpoint below names the ones it
satisfies.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel — different file, no dependency on an unfinished task
- **[Story]**: which user story the task serves (US1–US4)
- Every task names the file it touches, and most name the line

## Path Conventions

No source tree. Four files outside `specs/`:

```text
.specify/memory/constitution.md      # Principle II :83, Principle VI :143, Compatibility :225, version footer
.specify/templates/plan-template.md  # :44 version pointer, :49 II gate, :61 VI gate
AGENTS.md                            # :35
docs/ideas.md                        # :81
```

---

## Phases are commits, and two of them carry two stories each

Three repository rules shape this list:

- **1 issue = 1 commit**, each green on `bash scripts/verify.sh` on its own. There are two issues, so
  there are two issue commits, and a phase is a commit. US1 and US4 are both #83; US2 and US3 are
  both #75.
- **#83 first**, as the milestone's own description orders it — *"It comes first because every
  milestone after it writes another target fact into the document Principle VI forbids."*
- **Spec-first**: `specs/010-constitution-catches-up/` lands in its own `docs(speckit)` commit before
  either fix.

### Where the version bump and the Sync Impact Report go

Both issues edit `.specify/memory/constitution.md`, and the version and its report describe the
amendment as a whole. Split as follows, so the document is **internally coherent at every commit**:

| Commit | Version | Sync Impact Report |
|---|---|---|
| #83 | `3.0.0 → 4.0.0` | written, covering the Principle VI limb (MAJOR) |
| #75 | stays `4.0.0` | **extended** with the Principle II limb (MINOR) |

This is the versioning policy read literally: *"Where one amendment carries material at more than one
limb, the highest limb governs and the document takes one version number."* One amendment, one
number, landing in two commits. The alternative — holding the bump until #75 — leaves the #83 commit
with an amended Principle VI under a version footer saying 3.0.0, which is a document reading as
other than it is.

---

## Phase 1: Setup (baselines)

**Purpose**: write down the before-state. Three of the quickstart's checks are comparisons, and a
comparison without a "before" cannot fail.

- [X] T001 [P] Record the branch-point gate output as the baseline in the PR description: `24 embedded examples valid, 58 closures still reject`; `10 predicates assertable by Gatling, 10 selection probes still rejected, 5 still rendered, 10 predicate probes still rejected, 14 still rendered`. Both MUST be byte-identical at every later checkpoint — this milestone touches neither the schema nor the corpus
- [X] T002 [P] Record `docs/ideas.md`'s entry and condition counts — **16 and 16** — with `python3 -c "import re,io; t=io.open('docs/ideas.md',encoding='utf-8').read(); print(len(re.findall(r'^\*\*(.+?)\*\*',t,re.M)), t.count('*Would need*'))"`. The `26` the gate prints on the isolation line is its link count and is not this number
- [X] T003 [P] Confirm #83 and #75 are both assigned to milestone **v0.7.0**: `gh issue list --repo galax-io/opennfr --milestone v0.7.0 --state open`
- [X] T004 [P] Confirm the two permitted-and-must-stay-permitted sites still read as [research.md](research.md) R1 recorded them — `sed -n '477,479p' README.md` and `sed -n '564,567p' scripts/verify.sh`. If either has moved, the amended bullet must be re-checked against it before it is written

**Checkpoint**: quickstart checks 1, 3 and 5 can now discriminate.

---

## Phase 2: Foundational (blocking prerequisite)

**Purpose**: the spec-first rule. `AGENTS.md` requires the `specs/NNN-*/` artifacts to land in their
own commit **before** any `fix`, never folded into one.

**⚠️ CRITICAL**: no issue commit may be made until T005 is done.

- [X] T005 Commit `specs/010-constitution-catches-up/` as `docs(speckit): add 010-constitution-catches-up spec/plan/tasks` — spec, plan, research, data-model, quickstart, both contracts, the checklist and this file, with no repository-root file in the same commit

**Checkpoint**: the argument is reviewable before anything it argues for is written.

---

## Phase 3: #83 — the constitution permits the one home it already has (US1 P1 + US4 P4) 🎯 MVP

**Goal**: Principle VI stops forbidding what the repository does, defines what it constrains, and the
two files that quote it follow. After this phase `AGENTS.md` § *Architecture* and Principle VI can be
read back to back with no third file.

**Independent test**: quickstart checks 2, 3, 6 and 7. A reader who has never seen this milestone
should find no statement in either document that the other prohibits, and should be able to answer
"may adding a second target change an existing document?" from the principle alone.

**Contract**: [contracts/principle-vi.md](contracts/principle-vi.md) carries the before/after text for
every edit below.

- [X] T006 [US1] Replace Principle VI's second bullet at `.specify/memory/constitution.md:143-146` with the three bullets in [contracts/principle-vi.md](contracts/principle-vi.md) § *Delta 1*: the definition of a target description, *exactly one per target*, *MAY be a section of an existing document*, the gate carve-out, and the prohibitions that survive — the format, the schema, the published corpus, and every existing document other than the one holding the target descriptions (FR-001, FR-002, FR-003, FR-005)
- [X] T007 [US1] Verify the new bullet names **no file path** and that Principle VI's first bullet is untouched, so a reader can still tell a requirement document from the document that describes the format (FR-004, FR-006). `grep -n "README.md\|targets/" ` over the principle must return nothing
- [X] T008 [US1] Check the new bullet against the four sites [research.md](research.md) R1 enumerated. `README.md:478` and `scripts/verify.sh:566` MUST be permitted by it; a second table of what Gatling can assert MUST NOT be. If either fails, the wording is wrong — not the repository (FR-005)
- [X] T009 [US1] Append Principle VI's amendment record to `.specify/memory/constitution.md`, after the principle's existing rationale, per [contracts/principle-vi.md](contracts/principle-vi.md) § *Delta 2*: what the old bullet said and why it failed, that the departure was declared where contributors do not read rules, that the unit was wrong rather than the rule, and that **nothing checks this** (FR-007)
- [X] T010 [US1] Rewrite the last sentence of the Compatibility Constraints rationale at `.specify/memory/constitution.md:225`. It MUST say the third surface was removed in 3.0.0 *when* nothing described a target, that one exists now — `README.md` § *What any tool can actually run* — and that the surface is not restored, with the reason (FR-009)
- [X] T011 [US1] Confirm the bulleted list under `.specify/memory/constitution.md` § *Compatibility Constraints* still has exactly two items. Restoring the third is the recorded rejected alternative, not a silent addition (FR-010)
- [X] T012 [US1] Set `**Version**: 4.0.0` and `**Last Amended**` to today's date in `.specify/memory/constitution.md`'s footer, and rewrite the Sync Impact Report in the HTML comment at the head of that file for the **Principle VI limb only** — MAJOR, *redefined in a way that permits what it previously forbade*, why the previous wording failed, and the templates reviewed. VII stays the only withdrawn number (FR-008, FR-011)
- [X] T013 [P] [US1] Delete the parenthetical from `AGENTS.md:35`. The sentence keeps its rule; nothing replaces the citation (FR-012)
- [X] T014 [P] [US4] Rewrite the Principle VI gate at `.specify/templates/plan-template.md:61-63` to ask about the format, the schema, the published corpus, and any existing document **other than the one holding the target descriptions**, and to ask whether there is still exactly one description per target (FR-013)
- [X] T015 [P] [US4] Update the version pointer at `.specify/templates/plan-template.md:44` from `(v3.0.0)` to `(v4.0.0)` (FR-014)
- [X] T016 [US1] Run `bash scripts/verify.sh`. The two baselines from T001 MUST be byte-identical, and the link check MUST stay green — the amendment names paths in code spans, never as markdown links
- [X] T017 [US1] Commit as `fix(governance): the rule permits the one home it already has (#83)` with a `Closes #83` line. The commit MUST NOT touch `docs/ideas.md`, `README.md`, `GLOSSARY.md`, `schema/`, `examples/`, `scripts/`, or anything under `specs/`

**Checkpoint**: #83 is closed, the document is a coherent 4.0.0 describing one amended principle, and
`specs/008-path-denotation/plan.md`'s declared departure is now a historical record of a rule that has
been changed rather than a live exception.

---

## Phase 4: #75 — Principle II stops carrying the false reason (US2 P2 + US3 P3)

**Goal**: every quantity Principle II's derived clause names has an aggregation a reader can point to,
apdex is named one clause down under a reason true of it, and the parked argument in `docs/ideas.md`
passes its own check.

**Independent test**: quickstart checks 4 and 5. Name the aggregation for each quantity in the derived
clause; compare the enumeration in `docs/ideas.md` against the schema's `$defs/aggregation`.

**Contract**: [contracts/principle-ii.md](contracts/principle-ii.md).

- [X] T018 [US2] Split `.specify/memory/constitution.md:83-84` into two bullets per [contracts/principle-ii.md](contracts/principle-ii.md) § *Delta 1*: derived quantities keep throughput and error rate under the reason true of them, and a second bullet carries composite quantities — *they reduce to no construct the format has* — naming apdex (FR-017, FR-018)
- [X] T019 [US2] Verify the composite bullet states the **rule** and not the argument. Why apdex needs a banded classification and a weighting aggregation stays in `docs/ideas.md`; the bullet points there in a **code span**, never as a markdown link (FR-019)
- [X] T020 [US2] Verify the bullet is not written as the only thing refusing `loadtest.apdex`. `GLOSSARY.md` § *metric*, the reach tables' `any other` Metrics row and the parking in `docs/ideas.md` already do, and none of them stopped mattering (FR-020)
- [X] T021 [US2] Confirm `README.md` is unchanged and that the two documents now agree on every name they both mention. `README.md` gains no counterpart to the composite bullet — § *Names* tells an author what they may write (FR-021)
- [X] T022 [US2] Extend `.specify/memory/constitution.md`'s Sync Impact Report with the Principle II limb — MINOR, *existing guidance is materially expanded* — beside the MAJOR limb T012 wrote. The version stays **4.0.0**: one amendment, two limbs, highest governs (FR-011)
- [X] T023 [P] [US2] Add composite quantities to the Principle II gate at `.specify/templates/plan-template.md:49-52`, so the gate and the amended principle name the same two classes (FR-015)
- [X] T024 [P] [US3] Add `sum` to the aggregation enumeration at `docs/ideas.md:81`, and extend the sentence so it stays true with the seventh name present: `sum` adds up the values a metric carries, and nothing in the format classifies a request into a band or gives a band a weight (FR-022, FR-023)
- [X] T025 [US3] Confirm the enumeration now equals `$defs/aggregation`'s enum exactly — `avg`, `min`, `max`, `count`, `rate`, `sum`, `stddev` — plus `p*` for the pattern: `python3 -c "import json; print(json.load(open('schema/opennfr.io/v1/requirementset.schema.json'))['\$defs']['aggregation']['anyOf'][0]['enum'])"`
- [X] T026 [US3] Re-run T002's counter over `docs/ideas.md`. Entries and conditions MUST both still be **16**: the edit is inside the existing `**apdex**` entry and adds no line-initial bold and no second `*Would need*` (FR-024)
- [X] T027 [US2] Run `bash scripts/verify.sh`, then `git rm -r --cached -q docs && bash scripts/verify.sh; git reset -q` to confirm Principle VIII's droppability still holds
- [X] T028 [US2] Commit as `fix(governance): the reason names the class it is true of (#75)` with a `Closes #75` line. The commit MUST NOT touch `README.md`, `GLOSSARY.md`, `schema/`, `examples/`, `scripts/`, `AGENTS.md`, or anything under `specs/`

**Checkpoint**: both issues closed; the constitution ships 4.0.0 with two amended principles and a
report naming both limbs.

---

## Phase 5: Polish, and what this milestone found but does not fix

- [X] T029 Run every check in [quickstart.md](quickstart.md), in order. Step 1's two `git diff --stat` commands are the scope proof: `schema/`, `examples/`, `scripts/`, `GLOSSARY.md`, `README.md` and `specs/008-path-denotation/` all empty, and exactly four files changed outside this feature's own directory (SC-007, SC-008)
- [X] T030 [P] Verify each of the three commits is green **on its own** by checking it out in a scratch worktree — `git worktree add /tmp/onfr-green <sha> && (cd /tmp/onfr-green && bash scripts/verify.sh)`. Do not use `git stash`: this repository shares its stash stack across worktrees (FR-028)
- [ ] T031 Open the pull request against `main` with milestone **v0.7.0**, both `Closes` lines, and a **first paragraph** stating that it amends the constitution and what breaks without it — the governance disclosure rule, honoured even though this amendment travels with no other work (FR-029, FR-030)
- [ ] T032 [P] File an issue for the third defect of the same family, found by [plan.md](plan.md) § *Complexity Tracking*: nothing validates `.specify/memory/constitution.md`, and Principle III's third clause — *any artifact nothing validates MUST say so in its own text* — is unmet by the constitution itself. It is why both defects here survived two releases. The issue owes an argument about what such a check could decide, not a sentence
- [ ] T033 [P] File an issue for `.copier-answers.yml:6`, a fourth copy of the `AGENTS.md` architecture sentence two revisions behind — it never gained *"or states what a target can assert"* and never gained the second-target rule ([research.md](research.md) R7). Not fixed here: it is not one of this milestone's issues, and work outside them does not ride along

---

## Dependencies & Execution Order

```text
Phase 1 (T001–T004, all [P])
    ↓
Phase 2 (T005)  ← blocks everything; spec-first
    ↓
Phase 3 (#83)   T006 → T007, T008 → T009 → T010 → T011 → T012 → T016 → T017
                T013, T014, T015 in parallel with T009–T012
    ↓
Phase 4 (#75)   T018 → T019, T020, T021 → T022 → T027 → T028
                T023, T024 in parallel; T025, T026 verify T024
    ↓
Phase 5 (T029–T033)
```

**Why Phase 4 waits on Phase 3**: not a content dependency — Principle II and Principle VI do not
touch each other's text. It is the version footer and the Sync Impact Report, which T012 writes and
T022 extends. Running #75 first would mean writing the report twice or bumping the version under the
wrong limb.

**Parallel within Phase 3**: T013 (`AGENTS.md`), T014 and T015 (`plan-template.md`) touch neither the
constitution nor each other, and can be done while T009–T012 are in progress.

**Parallel within Phase 4**: T023 (`plan-template.md`) and T024 (`docs/ideas.md`) are different files
from the constitution and from each other.

---

## Implementation Strategy

**The smallest shippable increment is Phase 3.** It closes #83, ends a contradiction that has stood
for two releases, and leaves the repository consistent. #75 is a correction to a sentence nobody is
currently blocked by; it rides this amendment because it needs one and would otherwise wait for its
own version bump.

**The contestable part is Phase 4, not Phase 3.** The one decision a reviewer might reverse is
Principle II gaining a composite clause rather than mirroring `README.md`'s deletion — recorded in
[spec.md](spec.md) § *Decisions*. It lands second, so disagreement costs one revert and no rebase.

**Both issue commits must survive being read alone.** T017 and T028 each carry a `Closes` line, and
T030 checks each is green in isolation. A commit that only makes sense beside its neighbour is a
milestone that cannot be bisected.

---

## Notes

- **Nothing here is verified by a script.** `bash scripts/verify.sh` reads none of the three files
  this milestone edits except `docs/ideas.md`, and there only for the isolation counts. Every claim
  the amendment makes is checked by reading, and the amendment says so in its own text (FR-005).
- **The one number worth double-checking** is `docs/ideas.md`'s entry count. It is 16, not the 26 the
  gate prints beside it — that 26 is how many links the isolation scan followed. T002 exists because
  the first draft of this feature's research got that wrong.
- **No task edits `specs/`** other than this feature's own directory. `specs/008-path-denotation/plan.md`
  keeps its unchecked Principle VI box: it is the evidence the departure was disclosed, and rewriting
  it to match the new rule would erase the only record that the old one was ever departed from.
