---

description: "Tasks for 013-numbers-a-predicate-carries"
---

# Tasks: Which Numbers a Predicate May Carry

**Input**: Design documents from `specs/013-numbers-a-predicate-carries/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: no separate test tasks. All three issues *add checks* — fifteen probes and four raised
floors — and those are the deliverables, not tests of them. What validates the feature is the
revert set in [quickstart.md](quickstart.md) § 9: six edits, each of which must redden the gate,
and **one of which is green today**. Those appear below as **T013**, **T025** and **T033**, inside
the commits that make them fail.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel — different file, no dependency on an unfinished task
- **[Story]**: which user story the task serves (US1–US3)
- Every task names the file it touches, and most name the line

**`[P]` is rare here, and that is not an oversight.** The milestone edits three files, and the two
prose regions US2 and US3 touch are the same table. Marking work parallel that shares a table is
how a rebase conflict gets planned in.

## Path Conventions

No source tree. Three files outside `specs/`, and line numbers below are as of `906f8d2`:

```text
scripts/verify.sh          # :573  the Gatling heredoc's imports
                           # :630  TIME
                           # :634  def percentile
                           # :744  value = Fraction(str(...)) * factor
                           # :865  RENDERABLE
                           # :866-904  PREDICATE_PROBES
                           # :920-937  PREDICATE_RENDERS
                           # :971  FLOORS
README.md                  # :697  § Aggregations, the percentile row      -- READ, not written
                           # :713  the reasoning under it                  -- READ, not written
                           # :752-773 § Units: the table, the derived-row
                           #       sentence, the whole-number rule
GLOSSARY.md                # § threshold and unit -- one sentence joins the existing
                           #       *Rejected* line (T021). No line number: the entry moves,
                           #       the heading does not
schema/…/requirementset.schema.json  # $defs/aggregation.pattern           -- READ, not written
```

**Line numbers move.** T017–T020 rewrite `README.md:752-773` and T027–T029 edit the same table
again; T008–T009, T022–T023 and T030–T032 edit `scripts/verify.sh` in five places. Locate by the
quoted text in the contracts, never by the number alone.

---

## Phases are commits

Three repository rules shape this list:

- **1 issue = 1 commit**, each green on `bash scripts/verify.sh` on its own. Three issues, three
  issue commits, and a phase is a commit.
- **The milestone's order**: #73, then #59, then #74. #74 adds four conversions that #59's sentence
  governs, so adding them first would multiply the ambiguity by four.
- **Spec first.** `specs/013-*/` lands as its own commit before any `fix`, never folded in.

The asymmetry worth naming: **#73 changes no prose and #74 changes no rule.** #73 makes the gate
agree with a row that is already correct; #74 corrects a row while the rule that governs it stays
exactly as #59 left it. Only #59 changes both, which is why it sits in the middle.

---

## Phase 1: Setup (baselines)

**Purpose**: write down the before-state. Three of the quickstart's checks are comparisons, and one
of them — that either count row's integral flag can be flipped green — stops being reproducible the
moment Phase 4 lands. Record it while it is still true.

- [X] T001 [P] Record the helper/row divergence: run [quickstart.md](quickstart.md) § 4's script against **the current helper** by pasting `def percentile(a): return a.startswith("p") and a[1:].replace(".", "", 1).isdigit()` in place of the `re.fullmatch` line, and keep the output. Expect `p100`, `p999`, `p1234`, `p.5`, `p1.` **and** `p95\n` reported as renders. This is #73's central claim and the baseline for [quickstart.md](quickstart.md) § 4.
- [X] T002 [P] Record that the count rows' integral flag is unenforced: in `scripts/verify.sh:655` change `("allRequests.count", COUNT, True)` to `... False)`, run `bash scripts/verify.sh`, confirm **PASS**; revert with `git checkout -- scripts/verify.sh`; repeat for `failedRequests.count` at `:652`. Keep both outputs. **This is the one baseline that cannot be reconstructed after T023**, and it is FR-017f's whole justification.
- [X] T003 [P] Record what the four duration units do today: run the corrected-gate simulation from [research.md](research.md) R4 against the **current** `TIME` at `scripts/verify.sh:630` (`{"ms": 1, "s": 1000}`) for `1500000 us`, `2 min`, `1 h`, `2000000 ns`. Expect four refusals reading `unit … is not a unit of responseTime.percentile`. After T030 the same four render; the message change is the visible half of #74.
- [X] T004 [P] Record the current probe counts — **after T002 has reverted its mutation**, since this reads the gate T002 temporarily breaks: run `bash scripts/verify.sh` and keep the § *Examples are assertable by Gatling* line. Expect `13 predicate probes still rejected, 16 still rendered`.
- [X] T005 [P] Record the corpus baseline for FR-026 and SC-011: `git rev-parse HEAD:examples` and keep the tree hash. [quickstart.md](quickstart.md) § 1 compares against it, and a hash is what makes "byte-identical" a check rather than an impression.

**Checkpoint**: five baselines recorded, working tree clean (`git status --short` empty).

---

## Phase 2: Foundational (blocking prerequisite)

**Purpose**: the spec-first rule. `AGENTS.md` requires the `specs/NNN-*/` artifacts to land as
their own commit before any `fix`, so no issue commit may be made until T006 is done.

- [X] T006 Commit this directory as `docs(speckit): add 013-numbers-a-predicate-carries spec/plan/tasks` — `spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/` and `checklists/`. No `README.md` or `scripts/` change rides along.

**Checkpoint**: the argument is reviewable before anything it argues for is written.

---

## Phase 3: #73 — the percentile test is the row it implements (US1 P1) 🎯 MVP

**Goal**: one rule decides what a percentile is. The gate stops calling five shapes assertable that
the row and the schema both reject.

**Independent test**: [quickstart.md](quickstart.md) § 3 and § 4. Three artifacts hold one string;
ten aggregations get the same verdict from the row and from the gate.

**Contract**: [contracts/percentile-pattern.md](contracts/percentile-pattern.md).

**No prose change.** `README.md` § *Aggregations* is already correct and is the **source** of this
rule — the gate is what moves. That is why this commit touches one file.

- [X] T007 [US1] Add `re` to the Gatling heredoc's imports in `scripts/verify.sh:573`, which today reads `import glob, sys`.
- [X] T008 [US1] Replace the helper at `scripts/verify.sh:634` with the named constant and `re.fullmatch`, per [contracts/percentile-pattern.md](contracts/percentile-pattern.md). The pattern is `^p\d{1,2}(\.\d+)?$` carried **character-for-character including its anchors** — they are redundant under `fullmatch` and kept so the constant, the row and `$defs/aggregation` are comparable by eye (FR-004).
- [X] T009 [US1] Add the comment above the constant naming the row it implements **and** why `fullmatch` and not `match`: Python's `$` also matches before a trailing newline where ECMA-262's does not, so `match` would admit `"p95\n"` — the row's own defect one input smaller ([research.md](research.md) R1).
- [X] T010 [US1] Add three rejection probes to `PREDICATE_PROBES` (`scripts/verify.sh:866-904`): `p999`, `p.5` and `"p95\n"`, each expecting `aggregation <a> over a metric has no equivalent`. Each is the sole catcher of one regression — a widened integer part, an optional integer part, and `fullmatch` swapped for `match`.
- [X] T011 [US1] Raise the predicate rejection floor `13` → `16` in `FLOORS` (`scripts/verify.sh:971`). Leave the other five floors alone.
- [X] T012 [US1] Run `bash scripts/verify.sh`. Expect **PASS** and `16 predicate probes still rejected, 16 still rendered`. Then run [quickstart.md](quickstart.md) § 3 and expect `all three identical: True` — before this phase it printed `gate: NOT FOUND`.
- [X] T013 [US1] Apply each of [contracts/percentile-pattern.md](contracts/percentile-pattern.md) § *Acceptance*'s five reverts **on its own**, confirm the gate goes **red** and that the named probe is what fails, then revert. `re.fullmatch` → `re.match` must fail on `p95\n`; if it passes, T008 did not land.
- [X] T014 [US1] Commit `scripts/verify.sh` as `fix(gate): the percentile test is the row it implements (#73)` with `Closes #73`. One file; `README.md` must not be in the diff.

**Checkpoint**: #73 closed — **SC-001**, **SC-002**. One run of the gate no longer reports one
predicate as both assertable and invalid.

---

## Phase 4: #59 — the conversion is exact decimal arithmetic (US2 P2)

**Goal**: the whole-number rule gains the arithmetic it was always assuming, the `Target` column
says whose type it is, and one wrong cell in that column is corrected — which cannot be done
without rewording the rule.

**Independent test**: [quickstart.md](quickstart.md) § 5, § 6 and § 8. Two implementations built
from the corrected text alone accept and refuse the same five documents; every cell of the `Target`
column matches `AssertionBuilders.scala`.

**Contract**: [contracts/threshold-arithmetic.md](contracts/threshold-arithmetic.md).

**Read `GLOSSARY.md` § *threshold and unit* before writing it.** Two different obligations land on
one entry and only one of them was known when this phase was drafted:

- **Read** (T015): confirm the arithmetic sentence does not contradict the entry's rejection of
  `threshold: "500ms"`. It does not — the rule is about the value a number denotes, not about
  admitting a decimal string. If that ever stops being true, the arithmetic sentence is wrong, not
  the entry.
- **Write** (T021): the entry's *Rejected* line gains one sentence recording why a precision bound
  on `threshold` was refused (FR-012). An earlier draft of the contract put that in `README.md`
  § *Units*; `/speckit-analyze` found that this places a statement about the format's own schema
  inside a **target description**, which Principle VI defines as what a renderer reads to turn a
  document into assertions. [spec.md](spec.md) FR-027 had provided for the right home all along.

**No entry is added, renamed or redefined**, so Development Workflow's same-PR rule for a term
change is not engaged — there is no term change.

- [X] T015 [US2] Read `GLOSSARY.md` § *threshold and unit* and confirm the arithmetic sentence contradicts nothing in it, per the paragraph above. Record the finding in the PR body; change no file **in this task** — the entry is written in T021.
- [X] T016 [P] [US2] Add the arithmetic paragraph to `README.md` § *Units* immediately **before** the whole-number rule at `:770`, per [contracts/threshold-arithmetic.md](contracts/threshold-arithmetic.md). It must state exact decimal arithmetic on the value the threshold denotes, give the double-recovery route and its fifteen-significant-digit bound, and say that keeping source text is **not** required (FR-007 … FR-010).
- [X] T017 [US2] Rewrite the whole-number rule at `README.md:770-773` to be conditioned on the target being **integral** rather than on the word `Int`, and add `aggregation: count, threshold: 20.5` as its third worked example (FR-017e). Do not touch the no-rounding sentence.
- [X] T018 [US2] Correct the `Target` column in the § *Units* table (`README.md:759-763`): `allRequests.count`, `failedRequests.count` becomes **`Long`** (FR-017d). Check the other four cells against [data-model.md](data-model.md) § 7 and leave them as they are.
- [X] T019 [US2] In `README.md` § *Units* (`:757-763`) retitle the column's meaning and add the sourcing line beneath the table: the types are the **DSL entry points'**, not the target's, sourced to `AssertionBuilders.scala` at `gatling-core` 3.13.5, `gatling-core-java` 3.13.5 and `gatling-shared-model_2.13` 0.0.11, **checked 2026-09-01** — its own versions and date, not § *Gatling*'s 3.15.1 header (FR-017, FR-017a).
- [X] T020 [US2] Add the recorded non-relaxation to `README.md` § *Units* (FR-017b, FR-017c): a renderer constructing the assertion model itself does not pass through those entry points, and the rule is **not** relaxed for it, because reach is a property of the target and not of how a renderer is built. This is a target fact and belongs here; the rejected schema bound is **not**, and moves to T021.
- [X] T021 [P] [US2] Add one sentence to `GLOSSARY.md` § *threshold and unit*'s existing *Rejected* line, naming both grounds on which a precision bound on `threshold` was refused (FR-012), per [contracts/threshold-arithmetic.md](contracts/threshold-arithmetic.md). **No entry is added, renamed or redefined** — FR-027's second sentence is what permits this, and the spec provided for it from the start. It goes here rather than in `README.md` § *Units* because that section is a target description, and a renderer reads nothing from a rejected schema change.
- [X] T022 [P] [US2] Add the comment above `scripts/verify.sh:744`'s `Fraction(str(...))` naming the rule it implements, so replacing it with a float multiplication reads as a change to the rule (FR-013).
- [X] T023 [US2] In `scripts/verify.sh`, add one rendering probe to `PREDICATE_RENDERS` (`:920-937`) — `{**RENDERABLE, "threshold": 1.001, "unit": "s"}` (FR-014), two keys and no more, because `scripts/verify.sh:863` requires a probe to differ from a passing one *"in exactly the thing it tests"* and an aggregation override would test nothing — and **two** rejection probes to `PREDICATE_PROBES` (`:866-904`) — `aggregation: count, threshold: 20.5, unit: {request}`, and the same carrying `bad: BAD` (FR-017f). One per count row, because they sit in **different shapes**: `allRequests.count` under `requests`, `failedRequests.count` under `fraction`, so one probe reaches one row and leaves the other as unguarded as T002 found it. Raise the floors in `FLOORS` (`:971`): rejection `16` → `20`, rendering `16` → `18`.
- [X] T024 [US2] Confirm FR-015 by diff, not by the gate: `git diff main -- scripts/verify.sh` shows the `0.1 ms` rejection probe **and its message string** untouched. T017 rewords the whole-number rule and the tempting companion edit is to reword this message to match — it must not be made, and the floors cannot catch it, because deleting this probe and adding two still clears them.
- [X] T025 [US2] Run `bash scripts/verify.sh` (expect `20 … rejected, 18 … rendered`), then apply [contracts/threshold-arithmetic.md](contracts/threshold-arithmetic.md) § *Acceptance*'s three reverts on their own. The count-flag revert **is the one that passes green today** — T002's baseline — and must now fail.
- [X] T026 [US2] Commit `README.md`, `GLOSSARY.md` and `scripts/verify.sh` as `fix(format): the conversion is exact decimal arithmetic (#59)` with `Closes #59`. Three files; `schema/` and `examples/` must not be in the diff.

**Checkpoint**: #59 closed — **SC-003**, **SC-004**, **SC-008**, **SC-009**, **SC-010**. No message
string changed and no document changed renderability.

---

## Phase 5: #74 — responseTime reaches ns, us, min and h (US3 P3)

**Goal**: the Units table stops giving one reason for two different facts. Four units move from
**cannot** to **can**, governed by the rule #59 just reworded.

**Independent test**: [quickstart.md](quickstart.md) § 7. Seventeen units, ten reached, seven
unreachable, none in both and none in neither.

**Contract**: [contracts/duration-units.md](contracts/duration-units.md).

**The only commit that changes which documents may be published.**

- [X] T027 [P] [US3] Extend both duration rows' `Accepts` cells in `README.md:759-760` from `ms`, `s` to `ns`, `us`, `ms`, `s`, `min`, `h`. Both rows, because they share one factor table and one `Stats` type, which § *Metrics* already sources and dates. Incidentally: `:760` carries a trailing space — drop it while the row is being edited.
- [X] T028 [US3] Shrink the last row at `README.md:764` to the seven units no statistic reaches — `By`, `KiBy`, `MiBy`, `GiBy`, `{iteration}`, `{iteration}/s`, `{vu}` — keeping its existing reason, which is now true of all seven (FR-020).
- [X] T029 [US3] Re-check, and do **not** reword, the derived-row sentence at `README.md:766` (FR-021): the enumeration is 17, the statistics reach 10 distinct units, 17 − 10 = 7. Then name the whole-number rule as what still governs the four new units — they are not an exception to it, they are newly subject to it.
- [X] T030 [P] [US3] Add four factors to `TIME` (`scripts/verify.sh:630`): `ns` → `Fraction(1, 1000000)`, `us` → `Fraction(1, 1000)`, `min` → `Fraction(60000)`, `h` → `Fraction(3600000)`. All exact; no conversion rounds (FR-019).
- [X] T031 [US3] Add four rendering probes to `PREDICATE_RENDERS` in `scripts/verify.sh` (`:920-937`), one per new unit — `2000000 ns`, `1500000 us`, `2 min`, `1 h` — so deleting any single factor fails the gate (FR-023).
- [X] T032 [US3] Add one rejection probe to `PREDICATE_PROBES` in `scripts/verify.sh` (`:866-904`) — `{**RENDERABLE, "threshold": 1500, "unit": "ns"}` expecting `threshold 1500 ns is 3/2000 for responseTime.percentile, whose target is an integer` (FR-024). Confirm the reason comes from the whole-number branch and **not** from `unit … is not a unit of …`; that ordering is the whole of #74. Raise the floors in `FLOORS` (`:971`): rejection `20` → `22`, rendering `18` → `22`.
- [X] T033 [US3] Run `bash scripts/verify.sh` (expect `22 … rejected, 22 … rendered`), then apply [contracts/duration-units.md](contracts/duration-units.md) § *Acceptance*'s three reverts on their own. Deleting any one of the four factors must name that unit's own probe — if one deletion reddens on a different probe, T031 is short a case.
- [X] T034 [US3] Commit `README.md` and `scripts/verify.sh` as `fix(format): responseTime reaches ns, us, min and h (#74)` with `Closes #74`. Two files; `examples/` must not be in the diff.

**Checkpoint**: all three issues closed — **SC-005**, **SC-006**, **SC-007**.

---

## Phase 6: Polish — the pull request catches up

**Purpose**: the milestone lands as one pull request, and the rules that are checked outside the
gate get checked.

- [X] T035 Confirm `examples/` is byte-identical: `git rev-parse HEAD:examples` matches T005's hash, and `git diff --stat main -- examples/` is empty (FR-026, SC-011).
- [X] T036 Confirm the two read-only surfaces stayed read-only and the one written surface stayed small: `git diff --stat main -- schema/` is **empty** (FR-011), and `git diff main -- GLOSSARY.md` shows **one added sentence inside an existing *Rejected* line** — no heading added, none removed, no entry's definition touched (FR-027). If the schema moved, or if `GLOSSARY.md` gained or lost a heading, the Constitution Check in [plan.md](plan.md) needs re-answering before merge.
- [X] T037 Run [quickstart.md](quickstart.md) end to end — all nine steps, in order, on the merged branch. Steps 8 and 9 need `javap` and the Gatling jars; if they are absent, **say so** rather than reporting a pass (Principle III).
- [X] T038 Open the pull request against `main` with a conventional title, assign it to milestone **v0.9.0**, and carry `Closes #73`, `Closes #59`, `Closes #74`. Opened as [galax-io/opennfr#117](https://github.com/galax-io/opennfr/pull/117). `scripts/check-linkage.sh` reads every closing link the PR carries; one PR for the milestone is what `AGENTS.md` asks for.
- [X] T039 Confirm against `AGENTS.md` § *Commits & PRs* that the PR title is conventional **before** the squash freezes it into the commit message, and that the three issue commits are rebased onto `main` with no merge commit. Update a pushed PR with `--force-with-lease`.

---

## Dependencies & Execution Order

```text
Phase 1 (T001-T005)  baselines — T002 must run before T023 or its evidence is gone
        |
Phase 2 (T006)       spec commit — blocks every issue commit
        |
Phase 3 (T007-T014)  #73  scripts/verify.sh only
        |
Phase 4 (T015-T026)  #59  README.md § Units + GLOSSARY.md + scripts/verify.sh
        |
Phase 5 (T027-T034)  #74  README.md § Units + scripts/verify.sh
        |
Phase 6 (T035-T039)  the PR
```

**Why the phases are strictly sequential**, even though #73 touches a different region than the
other two:

- **T002 before T023** is a content dependency, not a convention: T023 makes T002's mutation fail,
  so the baseline has to be taken first or the claim "this was unenforced" becomes unverifiable.
- **#59 before #74** is the milestone's own reason: #74 adds four conversions and #59 states the
  arithmetic that governs them. Reversed, the four new units would ship for one release under a
  rule with no arithmetic model.
- **US2 and US3 both edit `README.md:752-773`** — the same six-row table, twice. Sequential is not
  a preference here; it is the absence of a conflict.
- Within a phase, the parallel work is one triple and one pair: **T016 ‖ T021 ‖ T022** — three
  different files, `README.md`, `GLOSSARY.md` and `scripts/verify.sh` — and **T027 ‖ T030**, a
  `README.md` edit beside a `scripts/verify.sh` edit. Everything else shares a file.

**Parallel opportunities**: T001–T005 are five independent reads and can all run at once. After
that the milestone is a chain, which three files and one shared table make unavoidable.

---

## Implementation Strategy

**MVP is Phase 3 alone.** #73 is one line of rule, one file, three probes and a floor, and it
delivers the milestone's headline on its own: one run of the gate stops reporting one predicate as
both assertable and invalid. It depends on nothing in Phases 4 and 5 and can ship as a release by
itself.

**Incremental delivery**: each of the three issue commits is green on `bash scripts/verify.sh` on
its own, so the branch can be reviewed and merged one commit at a time even though it lands as one
PR. If Phase 5 turns out to want more argument, Phases 3 and 4 are complete work and #74 returns to
the milestone board.

**The order is not negotiable in one place**: #59 before #74. Everywhere else the sequencing is
about file contention and can be re-cut.

**What "done" means**: `bash scripts/verify.sh` reports **PASS** with `22 predicate probes still
rejected, 22 still rendered`; the six reverts in [quickstart.md](quickstart.md) § 9 each redden the
gate; `examples/` is byte-identical to T005's hash; and § *Units* answers "how is the conversion
computed?" without a reader opening `scripts/verify.sh`.
