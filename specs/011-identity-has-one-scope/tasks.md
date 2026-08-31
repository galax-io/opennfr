---

description: "Tasks for 011-identity-has-one-scope"
---

# Tasks: Identity Has One Scope

**Input**: Design documents from `specs/011-identity-has-one-scope/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: no separate test tasks. Two of the three issues *add checks* — six identity probes and one
rendering probe — and those are deliverables, not tests of the feature. What validates the feature is
the mutation set in [quickstart.md](quickstart.md) § 3 and § 4c: every mutation must redden the gate,
and every one of them is green today. Those appear below as **T016** and **T022**, inside the commits
that make them fail.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel — different file, no dependency on an unfinished task
- **[Story]**: which user story the task serves (US1–US4)
- Every task names the file it touches, and most name the line

## Path Conventions

No source tree. Six files outside `specs/`, and line numbers below are as of `7cf314a`:

```text
README.md                                        # :357-367 the `name` paragraph; a new #### Identity
                                                 #   after § Units; :726 the partition claim
schema/opennfr.io/v1/requirementset.schema.json  # :130 $defs/predicate.name description
GLOSSARY.md                                      # :200-207 § criterionId
scripts/identity.py                              # NEW
scripts/verify.sh                                # :157-166 and :341-350 the two call sites;
                                                 #   :788-803 PREDICATE_RENDERS; :825-826 FLOORS
AGENTS.md                                        # § Structure, the scripts/ clause
```

**Line numbers move.** T005 rewrites `README.md:357-367` and T018 adds a subsection further down the
same file; T012–T014 and T020–T021 edit `scripts/verify.sh` in four places. Locate by the quoted text
in the contracts, never by the number alone.

---

## Phases are commits, and the first one carries two stories

Three repository rules shape this list:

- **1 issue = 1 commit**, each green on `bash scripts/verify.sh` on its own. Three issues, three issue
  commits, and a phase is a commit. US1 and US2 are both #58.
- **#58 first**, as the milestone orders it: a probe has to encode a scope (#72) and a reach row has
  to describe an identity that means one thing (#82).
- **Spec first.** `specs/011-*/` lands as its own commit before any `fix`/`docs`, never folded in.

The one asymmetry worth naming: **#58 changes no gate and #72 changes no document.** #58 corrects what
the repository *says*; #72 makes the gate notice when a document disobeys it. That is why #58's commit
can be green without a single new probe, and why #72's commit adds no prose.

---

## Phase 1: Setup (baselines)

**Purpose**: write down the before-state. Four of the quickstart's checks are comparisons, and the
most important one — that the identity rule can be deleted green — stops being reproducible the
moment Phase 4 lands. Record it while it is still true.

- [X] T001 Record the three sites that scope identity to the requirement: run `grep -rn "in one requirement\|of one requirement\|within one requirement" README.md GLOSSARY.md schema/opennfr.io/v1/requirementset.schema.json` and keep the output. Expect exactly three hits — `GLOSSARY.md:202`, `README.md:357`, `schema/…:130`. This is the baseline for [quickstart.md](quickstart.md) § 2b.
- [X] T002 Record that the identity rule is currently unenforced: replace `scripts/verify.sh:162`'s `if cid in seen:` with `if False:`, run `bash scripts/verify.sh`, confirm **PASS**; revert with `git checkout -- scripts/verify.sh`; repeat for `:346`'s `if cid in seen_ids:`. Keep both outputs. This is #72's central claim and the only baseline that cannot be reconstructed after T012–T014.
- [X] T003 Record the current probe counts and the coverage gap — **after T002 has reverted its mutation**, since this task reads the gate T002 temporarily breaks and would otherwise record a baseline taken against a broken one: run `bash scripts/verify.sh` and keep the § *Examples are assertable by Gatling* line (expect `14 still rendered`), then run [quickstart.md](quickstart.md) § 4a's axis script and keep its output (expect five axis subsections, no `#### Identity`, and both `name` and `displayName` `MISSING`).

**Checkpoint**: quickstart checks 0, 2b, 3 and 4a can now discriminate before and after.

---

## Phase 2: Foundational (blocking prerequisite)

**Purpose**: the spec-first rule. `AGENTS.md` requires the `specs/NNN-*/` artifacts to land as their
own commit before any implementation commit.

**⚠️ CRITICAL**: no issue commit may be made until T004 is done.

- [X] T004 Commit `specs/011-identity-has-one-scope/` — spec.md, plan.md, research.md, data-model.md, quickstart.md, tasks.md, contracts/ and checklists/ — as `docs(speckit): add 011-identity-has-one-scope spec/plan/tasks`. No file outside that directory is in the commit.

**Checkpoint**: the argument is reviewable before anything it argues for is written.

---

## Phase 3: #58 — identity is unique within one list (US1 P1 + US2 P2) 🎯 MVP

**Goal**: one reading of the scope, stated in one place, with the other two artifacts naming it
instead of repeating it. Contract: [contracts/identity-scope.md](contracts/identity-scope.md).

**Independent test**: quickstart checks 2a–2d. A renderer author reads the schema's `name`
description, `README.md` § *A predicate* and `GLOSSARY.md` § *criterionId* in any order and finds
one answer; `examples/the-run-held-up.yaml` is valid under all three for the first time.

**No gate change.** `scripts/verify.sh` already implements this reading — that is why the corpus
never failed. Making it fire is Phase 4.

- [X] T005 [US1] Rewrite `README.md:357-367` — the `**\`name\`.**` paragraph — per [contracts/identity-scope.md](contracts/identity-scope.md) § 1: the scope becomes the list and is stated here; the worked example's collision moves into `criteria`; the exemption sentence names `examples/the-run-held-up.yaml`.
- [X] T006 [P] [US2] Replace the `description` of `$defs/predicate.name` at `schema/opennfr.io/v1/requirementset.schema.json:130` per [contracts/identity-scope.md](contracts/identity-scope.md) § 2. It stops stating the scope and defers to `README.md`, in the shape `$defs/unit` already uses — and per **FR-006a** it also stops saying *"in a report"*, which is the last downstream claim in the schema.
- [X] T007 [P] [US2] Rewrite `GLOSSARY.md:200-207` § *criterionId* per [contracts/identity-scope.md](contracts/identity-scope.md) § 3: the definition keeps the derivation, the scope becomes a pointer, and a second `*Rejected*` line records the requirement scope and why it was refused.
- [X] T008 [US1] Verify the commit before making it: `git diff --stat -- examples/` is empty, `bash scripts/verify.sh` is **PASS**, and T001's grep now returns nothing.
- [X] T009 [US1] Commit as `fix(format): identity is unique within one list (#58)` with a `Closes #58` line. Three files: `README.md`, `GLOSSARY.md`, `schema/opennfr.io/v1/requirementset.schema.json`.

**Checkpoint**: #58 is closed — **SC-001**, **SC-002**, **SC-003**. The repository states one scope in one
place, the flagship example is correct under every document that mentions it, and the corpus has not
moved a byte.

---

## Phase 4: #72 — the identity rule is probed in both directions (US3 P3)

**Goal**: the rule `README.md` states is enforced by something that would notice its absence.
Contract: [contracts/identity-module.md](contracts/identity-module.md).

**Independent test**: [quickstart.md](quickstart.md) § 3 — seven mutations, each applied alone, each must redden the gate. That list is canonical; [contracts/identity-module.md](contracts/identity-module.md) § *The seven mutations this commit makes fail* names the same seven against what catches each. T002 recorded that all seven are green today.

**No document changes** beyond one clause of `AGENTS.md`, which rides here because this commit adds
the file that clause describes.

- [X] T010 [US3] Create `scripts/identity.py` with `SECTIONS`, `predicate_id(predicate)`, `collisions(requirement, scanned)` and `duplicates(requirement)`, per [contracts/identity-module.md](contracts/identity-module.md) § 1. The module docstring names `README.md` § *A predicate* as where the rule is stated and does **not** restate the scope.
- [X] T011 [US3] Add `PROBES` (six entries), `FLOOR = 6` and `selftest()` to `scripts/identity.py` per the same contract. Four probes must report a collision, two must report none; the floor message is the file's existing sentence, *"a rule nothing probes is a rule nothing checks"*.
- [X] T012 [US3] Wire the `SCHEMA` heredoc in `scripts/verify.sh` (lines 118–172): add `sys.path.insert(0, "scripts")`, `import identity`, the `selftest()` gate in the shape `LINKS` uses at `:901-911`, and `identity_lists = []`; then replace the inline rule at `:157-166` with `identity.collisions(r, identity_lists)`, and replace the comment at `:155-156` with a pointer to `scripts/identity.py` per **FR-008** — it is a second copy of the module's docstring once the rule moves, and its last clause, *"uniqueness is checked here"*, stops being true. Mind the boundary: the comment is 155–156, the rule is 157–166.
- [X] T013 [US3] Add `IDENTITY_LISTS = 5` and its floor before `sys.exit(rc)` in the same `SCHEMA` heredoc of `scripts/verify.sh`, plus the `ok    identity: N probes still hold, M lists read` line (**FR-020**). The section has no aggregate line today.
- [X] T014 [US3] Replace `scripts/verify.sh:340-350` in the `SELFCHECK` heredoc with the same import, the `identity.duplicates` call over the schema's root examples, a `root_identity_lists` counter and `ROOT_IDENTITY_LISTS = 1`. Keep the existing comment about the root examples answering to what the corpus answers to.
- [X] T015 [P] [US3] Update `AGENTS.md` § *Structure*: `what it shares (\`mdlinks.py\`)` becomes `what it shares (\`mdlinks.py\`, \`identity.py\`)`. A map correction, not a rule.
- [X] T016 [US3] Run all seven mutations from [quickstart.md](quickstart.md) § 3, one at a time, reverting between each with `git checkout -- scripts/identity.py scripts/verify.sh`. Every one must exit non-zero, and each must fail for its own reason. Compare against T002.
- [X] T017 [US3] Commit as `fix(gate): the identity rule is probed in both directions (#72)` with a `Closes #72` line. Three files: `scripts/identity.py` (new), `scripts/verify.sh`, `AGENTS.md`.

**Checkpoint**: #72 is closed — **SC-004**, **SC-005**, **SC-006**. `README.md` § *What the schema does not
check* — *"The gate checks it; the schema cannot"* — is true in the sense that matters: deleting the
check now fails.

---

## Phase 5: #82 — identity has no slot in a Gatling assertion (US4 P4)

**Goal**: all nine predicate keys have a reach row, on an axis whose verdict is neither **can** nor
**cannot**. Contract: [contracts/identity-reach.md](contracts/identity-reach.md).

**Independent test**: quickstart checks 4a–4c. Nine keys, nine rows; the axis rejects nothing, and a
probe says so.

**The row stops at the assertion.** A target description says what a renderer reads to produce
assertions. What Gatling does with an assertion afterwards is not described here, and no sentence in
this phase may drift into describing it.

- [X] T018 [US4] Add `#### Identity` to `README.md` § *Gatling*, between § *Units* and § *Two things Gatling cannot do at all*, per [contracts/identity-reach.md](contracts/identity-reach.md) § 1: two rows, the **not carried** verdict explained beneath, and a `Sourced`/`Checked` line naming `Assertion`, `gatling-shared-model` 0.0.11, **Gatling 3.13.5** and **2026-08-31** — and saying why that is not the header's 3.15.1.
- [X] T019 [US4] Add the nine-keys paragraph to `README.md` § *How these tables are applied*, after *"The tables partition each axis."* at `:726`, per the same contract § 2. Seven keys decide assertability, two do not, and the gate implements no rejection from the Identity axis.
- [X] T020 [P] [US4] Add `{**RENDERABLE, "name": "p95-latency"}` to `PREDICATE_RENDERS` in `scripts/verify.sh` (`:788-803`), with the comment explaining that this is the Identity axis's only probe and that it is a rendering one because the axis rejects nothing.
- [X] T021 [US4] Raise the `PREDICATE_RENDERS` floor from **14** to **15** in `FLOORS` at `scripts/verify.sh:825-826`. Same file as T020, so not parallel with it.
- [X] T022 [US4] Confirm the probe is load-bearing: add `if "name" in p: why.append("name has no equivalent")` to `predicate_why`, run `bash scripts/verify.sh`, confirm it exits non-zero, revert. T003 recorded that nothing catches this today.
- [X] T023 [US4] Commit as `docs(format): identity has no slot in a Gatling assertion (#82)` with a `Closes #82` line. Two files: `README.md`, `scripts/verify.sh`.

**Checkpoint**: all three issues closed — **SC-007**, **SC-008**, **SC-009**. Nine keys, nine rows, and a
partition claim that holds.

---

## Phase 6: Polish, and what this milestone found but does not fix

- [X] T024 Run [quickstart.md](quickstart.md) end to end against the finished branch — this is where **SC-010** (green at every commit, probe counts risen) is demonstrated — steps 0 through 4 and 6. Step 5 needs the Gatling jar and is expected to be unrunnable on a machine without it; that is the point of the step.
- [X] T025 Confirm the shape of the whole change: `git diff --name-only main | grep -v '^specs/011-'` returns exactly the six files in § *Path Conventions*, and `git diff --stat main -- examples/` is empty (**FR-034**, **FR-009**, **FR-021**).
- [X] T026 Confirm the three negative requirements the file list cannot reach: `git diff main -- .specify/memory/constitution.md` is empty and its footer still reads **4.0.0** (**FR-037**); `git diff main -- README.md` leaves the § *What the schema does not check* bullet *"That two predicates have distinct identities"* untouched (**FR-010**); and no borrowed OpenTelemetry name and no field name appearing in a published example is added, removed or renamed (**FR-036**) — which the empty `examples/` diff shows for the second half and a read of the schema diff shows for the first.
- [X] T027 Demonstrate **SC-011**: open the pull request carrying milestone **v0.8.0** with `Closes #58`, `Closes #72` and `Closes #82`, then run `scripts/check-linkage.sh --pr <N>`. Confirm all three issues sit in that milestone. The PR title must be conventional before merge — a squash freezes it into the commit.
- [X] T028 [P] Open the two issues this milestone found in passing — filed against **v0.8.0** and, on the maintainer's call, brought into scope rather than deferred (spec.md § *What review added*). They are **#91** and **#92**: **(a)** `criterionId` names the identity of a guard as well as a criterion and reads wrong of the first — a rename argued under Principle I; **(b)** `GLOSSARY.md` § *name* justifies its character restriction with *"a report line, a CI annotation, a URL fragment"*, two of which are downstream of anything this format describes, and it is the last place in the repository that argues from one.

---

## Phase 7: #91 — the term covers what it names

**Goal**: `criterionId` becomes `predicateId`. Contract: spec.md FR-038 … FR-041.

**Why it is here and not in v0.9.0**: #58 made the guard a first-class carrier of identity by scoping
uniqueness to the list, and #72 shipped a probe whose whole subject is a guard's identity. The release
that promoted the guard is the release that should stop calling its identity a criterion's.

**Independent test**: `grep -rn criterionId` outside `specs/` returns only `GLOSSARY.md`'s *Rejected*
line, which Principle I requires the entry to carry, and the gate's failure message on a colliding
guard names a term that is true of a guard.

- [X] T029 [US1] Rename the entry in `GLOSSARY.md`: `### criterionId` becomes `### predicateId`, and the body records what the old term got wrong — it named the identity of a predicate after one of the two lists that hold predicates. Both existing `*Rejected*` lines survive; they protect decisions this rename does not reopen (**FR-038**, **FR-039**).
- [X] T030 [US1] Move every remaining site together (**FR-040**): both failure messages and the comment in `scripts/verify.sh`, and the `duplicates()` docstring in `scripts/identity.py`. `README.md` does not use the term and must not gain it.
- [X] T031 [US1] Verify and commit as `refactor(vocabulary): the identity of a predicate is a predicateId (#91)` with `Closes #91`. `grep -rn criterionId` outside `specs/` returns only the *Rejected* line, `bash scripts/verify.sh` is **PASS**, and `git diff --stat main -- examples/ schema/` shows no new change.

**Checkpoint**: #91 closed — **SC-012**.

---

## Phase 8: #92 — the restriction is justified by something the format has

**Goal**: `GLOSSARY.md` § *name* stops arguing from consumers this format does not describe.
Contract: spec.md FR-042, FR-043.

**Independent test**: read the entry and name, for each reason it gives, the artifact in this
repository that makes it true. Today two of three name things outside the format, and #82 makes the
third false for the one target described.

- [X] T032 [US4] Replace the justification in `GLOSSARY.md` § *name* (**FR-042**, **FR-043**): the restriction holds because an identity is compared for **equality** by the gate — a closed character set is what makes two identities that look alike to a reader be alike to the check — and because `$defs/name` is one spelling rule shared by `metadata.name`, a requirement's `name` and a predicate's `name`.
- [X] T033 [US4] Replace the `*Rejected*` line *"free-form strings — nothing could point at one reliably"* on the same grounds, keeping the alternative it rejects. Principle I says the rejection outlives the term it protects, so the alternative stays and only its reason moves.
- [X] T034 [US4] Verify and commit as `docs(vocabulary): name is restricted for a reason the format can back (#92)` with `Closes #92`. No reason in the entry names a report, a CI annotation, or anything downstream of the assertions a renderer produces.

**Checkpoint**: #92 closed — **SC-013**. All five issues closed.

---

## Phase 9: the pull request catches up

- [X] T035 Update [galax-io/opennfr#90](https://github.com/galax-io/opennfr/pull/90): add `Closes #91` and `Closes #92` to the body, describe both, and re-run `scripts/check-linkage.sh --pr 90`. Push with `--force-with-lease`, as `AGENTS.md` requires of a pushed PR.

---

## Dependencies & Execution Order

```text
Phase 1 (T001-T003)  baselines — must precede Phase 4, which destroys T002's
      |
Phase 2 (T004)       spec commit — blocks every issue commit
      |
Phase 3 (T005-T009)  #58    ── MVP. No gate change.
      |
Phase 4 (T010-T017)  #72    ── probes encode Phase 3's answer
      |
Phase 5 (T018-T023)  #82    ── the row describes an identity that means one thing
      |
Phase 6 (T024-T028)  PR, linkage, the two issues review brought into scope
      |
Phase 7 (T029-T031)  #91   ── the term the milestone made wrong
      |
Phase 8 (T032-T034)  #92   ── the reason FR-006a left behind
      |
Phase 9 (T035)       the PR catches up
```

**Why Phase 4 waits on Phase 3**: a content dependency, not a convention. Probe 6 — a `rate` guard
beside a `rate` criterion reporting no collision — *is* #58's answer written as code. Written before
the answer was settled, it would encode a scope no document yet states.

**Why Phase 5 waits on Phase 4**: convention rather than content. The Identity row does not depend on
the probes. It is last because the milestone orders it last, and because #82's row describes an
identity whose meaning Phase 3 fixed.

**Parallel within Phase 3**: T006 (schema) and T007 (`GLOSSARY.md`) are different files from T005
(`README.md`) and from each other. All three can be written at once; T008 verifies the set.

**Parallel within Phase 4**: T015 (`AGENTS.md`) touches neither `identity.py` nor `verify.sh` and can
be done at any point in the phase. T010 → T011 are the same file in sequence; T012 → T013 are the same
heredoc in sequence; T014 is a different heredoc but the same file, so it follows T013.

**Parallel within Phase 5**: T018 and T019 are both `README.md` and are sequential; T020 is
`scripts/verify.sh` and is parallel with either; T021 follows T020 in the same file.

---

## Implementation Strategy

**The smallest shippable increment is Phase 3.** It closes #58, ends a contradiction between the two
most authoritative documents in the repository, and makes the flagship example valid under every
document that mentions it. It needs no new machinery and touches no gate.

**Phase 4 is the one that changes what the repository can prove.** Everything else in this milestone
is words; T010–T017 turn a claim into a check. If time runs out, this is the phase not to defer:
#72 is a rule that has been *stated* since guards arrived and enforced by nothing that would notice.

**The contestable part is Phase 5, not Phases 3 or 4.** The one decision a reviewer might reverse is
the third verdict — **not carried** beside **can** and **cannot** in a target's description. The
alternatives and why each was rejected are in plan.md § *Complexity Tracking* and research.md R6. If
the verdict is rejected in review, Phases 3 and 4 stand unchanged and #82 is re-argued alone.

**Each issue commit must survive being read alone.** T009, T017 and T023 each carry a `Closes` line
and each must be green on `bash scripts/verify.sh` at that commit, not only at the tip.

---

## Notes

- **`examples/` is never edited.** If any task appears to require a corpus change, the task is wrong.
  Every published document is already valid under the reading this milestone settles on, and FR-021
  keeps the corpus out of the coverage business — the `name` arm is exercised by probes.
- **One external claim.** The Identity row's reason rests on Gatling's `Assertion`, read at 3.13.5
  from `gatling-shared-model` 0.0.11 on 2026-08-31 (research.md R1). It cannot be checked from this
  repository, which is why T018 carries the version and the date into the page itself.
- **Adding a probe means raising the floor beside it.** `scripts/verify.sh:826` states that as a rule.
  T021 pays it for T020, and T011's `FLOOR = 6` is exact for the same reason.
- **No constitutional amendment.** `.specify/memory/constitution.md` stays at 4.0.0 and is not opened.
