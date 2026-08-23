---
description: "Task list for 005-fix-milestone-bugs"
---

# Tasks: Fix Milestone v0.3.0 Bugs

**Input**: Design documents from `/specs/005-fix-milestone-bugs/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: No test-code tasks — there is no application code. `bash scripts/verify.sh` is what
stands in for tests, and every story's own verification tasks run it (and probe it) rather than
add a separate test suite.

**Organization**: By user story, one per milestone issue, so each ships as its own commit per
`AGENTS.md`'s "1 issue = 1 commit". All five are independently testable; only US3 has a real
dependency (on US2 — see Dependencies below).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel — different files, or read-only, with no dependency on an
  incomplete task
- **[Story]**: US1–US5, mapping to issues #37, #42, #38, #43, #46; absent on Setup and Polish

---

## Phase 1: Setup

- [X] T001 Confirm the gate is green before any change: if `bash scripts/verify.sh` reports
      `jsonschema` or `pyyaml` missing, run
      `python3 -m pip install --user --break-system-packages pyyaml jsonschema`
      (quickstart.md, Prerequisites); then run `bash scripts/verify.sh` from the repository root
      and confirm it reports `PASS`. This is the baseline every story's own gate run is checked
      against — none of the five defects currently turns the gate red (they are silent or
      unreachable today, per research.md), so `PASS` here is expected, not a surprise

**Checkpoint**: baseline confirmed green. Every later `FAIL`/`PASS` in this file is a delta against
this run.

---

## Phase 2: Foundational

None. The five fixes touch disjoint concerns except the one pairwise dependency recorded under
Dependencies below (US3 on US2) — there is no shared infrastructure to build first.

---

## Phase 3: User Story 1 — The verification gate must actually verify (#37, Priority: P1) 🎯 MVP

**Goal**: the seven "closures still reject" probes in `scripts/verify.sh` fail for the right
reason, not the wrong one.

**Independent Test**: temporarily drop a closure the probes are meant to guard, confirm the
section now `FAIL`s naming it, then restore.

- [X] T002 [US1] In the `SELFCHECK` Python block of `scripts/verify.sh`, fix the `doc()` factory
      function that builds the seven probes' shared base document: add `"selector": {}` to the
      requirement and `"metric": "m"` to the criterion, clearing the four pre-existing errors
      recorded in research.md R1 (FR-001). **Discovered during implementation**: clearing those
      four errors also requires dropping the bogus `indicator` key `doc()` carried (`requirement`
      has no such property — the same dead `indicator` concept issue #38 targets in the schema
      itself); doing so breaks the "displayName on a series" probe, which mutated
      `indicator.distribution` — a construct that no longer exists anywhere in the schema. That
      probe was repointed to test the same closure class (an object with
      `additionalProperties: false` rejecting an undeclared `displayName`) at the one place still
      uncovered: the document root. Probe count stays at seven; see the comment left in
      `scripts/verify.sh` and research.md R1 addendum
- [X] T003 [US1] In the same `SELFCHECK` block, immediately after `doc()` is defined, assert the
      unmutated base document validates with zero errors; if it does not, print `FAIL` naming
      every error and `sys.exit(1)` — this file's own idiom inside a Python heredoc block, the
      equivalent of the outer `bad()`/`fail=1` pattern — instead of letting the section fall
      through to `ok` (FR-001, FR-002)
- [X] T004 [US1] Run `bash scripts/verify.sh` and confirm the "schema holds up its own examples,
      and still rejects" section still reports `ok    8 embedded examples valid, 7 closures still
      reject` — the probes themselves are unchanged, only their foundation is fixed. **Confirmed
      live**: exact output matched
- [X] T005 [US1] Probe rather than trust (contracts/verify-sections.md § Acceptance): temporarily
      remove `"additionalProperties": false` from `$defs/requirement` in
      `schema/opennfr.io/v1/requirementset.schema.json`, run `bash scripts/verify.sh`, and confirm
      the section now **FAILS** on the "unknown field on a requirement" probe, naming the loss
      instead of printing `ok`; then revert the temporary edit and confirm `ok` returns (chosen
      because `$defs/requirement`'s own closure is untouched by US2/US3, so this probe is valid
      regardless of story order). **Confirmed live**: `FAIL  the schema accepts what it must
      reject: unknown field on a requirement`; reverted, `ok` returned, schema byte-identical to
      before (`git diff` empty). **Extended after review (T043)**: SC-003 asks for each of the
      seven, not one — the full sweep now runs all seven and each flips exactly its own probe
- [X] T006 [US1] Run `bash scripts/verify.sh` in full and confirm `PASS`. **Confirmed live: PASS**

**Checkpoint**: the gate's own self-check can now fail. Every later story's "zero regressions"
claim is backed by a check that has just been proven capable of catching a regression.

---

## Phase 4: User Story 2 — One mistake, one error message (#42, Priority: P2)

**Goal**: a single invalid predicate field produces exactly one validation error, not two.

**Independent Test**: validate a requirement with `unit: "mss"` and count the errors.

- [X] T007 [US2] Add `"additionalProperties": false` to `$defs/predicate` in
      `schema/opennfr.io/v1/requirementset.schema.json` (FR-003; research.md R2)
- [X] T008 [US2] Change `$defs/requirement.properties.criteria.items` from
      `{"allOf": [{"$ref": "#/$defs/predicate"}], "unevaluatedProperties": false}` to a plain
      `{"$ref": "#/$defs/predicate"}` (FR-003, FR-006)
- [X] T009 [US2] Change `$defs/requirement.properties.guards.items` the same way — a plain
      `{"$ref": "#/$defs/predicate"}` — which also removes its no-op `"properties": {}` as a side
      effect of replacing the whole `items` value (FR-003, FR-006; data-model.md notes this
      overlaps US3's #38 fix — T015 below reconciles against whichever of T009/T015 lands second)
- [X] T010 [P] [US2] Validate `examples/fast-and-reliable.yaml`, `examples/one-request-is-fast.yaml`
      and `examples/the-run-held-up.yaml` against the changed schema and confirm all three still
      validate — zero regressions (FR-012; research.md R2 dry-run). **Confirmed live: 0
      regressions**
- [X] T011 [P] [US2] Validate a requirement whose only defect is `unit: "mss"` (quickstart.md § 2)
      and confirm exactly **one** error is reported, naming `unit` (SC-002). **Confirmed live: 1
      error**, `'mss' is not one of [...]`
- [X] T012 [P] [US2] Validate a requirement with an unknown predicate key (e.g. a misspelled
      `agregation`) and confirm the reported errors all name the unknown key (research.md R2
      evidence table). **Corrected after review**: this task originally claimed, and was ticked on,
      "exactly one error". That is false and was never run — the case yields **2 errors**,
      `Additional properties are not allowed ('agregation' was unexpected)` and `'aggregation' is a
      required property`. Both name the typo, which is the actual improvement (before, one of the
      two blamed five valid keys); the count did not drop. Re-run live and recorded as 2
- [X] T013 [US2] Run `bash scripts/verify.sh` in full and confirm `PASS`. **Confirmed live: PASS**,
      including the "still rejects" section fixed in US1 — all 7 closures, including the one this
      story moved, still reject correctly

**Checkpoint**: a predicate mistake now produces messages that all name the mistake. A bad *value*
produces exactly one; a misspelled *key* produces two, both pointing at that key. Independently
shippable.

---

## Phase 5: User Story 3 — A schema rule that can never fire is removed (#38, Priority: P3)

**Depends on US2** (T007–T009): both touch `$defs/requirement.properties.{criteria,guards}.items`.
Implement in this order — US3's diff becomes purely subtractive once US2 has already collapsed
both `items` to a plain `$ref` (data-model.md, "Ordering constraint").

**Goal**: `$defs/requirement` carries no conditional that can never match.

**Independent Test**: remove the dead `allOf`, confirm the full corpus and the schema's own
embedded examples still validate unchanged.

- [X] T014 [US3] Delete the entire `allOf` block marked
      `"description": "UNREACHABLE. \`indicator\` was removed from \`requirement\`..."` from
      `$defs/requirement` in `schema/opennfr.io/v1/requirementset.schema.json` (FR-004, FR-005)
- [X] T015 [US3] Confirm `$defs/requirement.properties.guards.items` carries no `"properties": {}`
      distinct from `criteria.items` — already true if T009 landed first (it replaced the whole
      `items` value); if US3 is being implemented before US2 in a differently-sequenced run,
      delete the key explicitly here instead (FR-006). **Confirmed live**: both are byte-identical
      `{"$ref": "#/$defs/predicate"}`, already resolved by T009
- [X] T016 [P] [US3] Validate the full `examples/` corpus (3 files) and the schema's own embedded
      `selector`, `predicate` and `requirement` examples against the changed schema; confirm zero
      regressions in either (FR-012; research.md R3 dry-run). **Confirmed live: 0 regressions**
- [X] T017 [P] [US3] Confirm the constraint the deleted conditional encoded is still enforced:
      validate a `bad`/`good` predicate using an aggregation other than `rate`/`count` (e.g.
      `p99`) and confirm it is still rejected — by `$defs/predicate`'s own "A fraction has no
      percentile" rule, not by the deleted block (Acceptance Scenario 3, User Story 3).
      **Confirmed live**: rejected, `'p99' is not one of ['rate', 'count']`
- [X] T018 [US3] Run `bash scripts/verify.sh` in full and confirm `PASS`. **Confirmed live: PASS**

**Checkpoint**: no rule in `$defs/requirement` cites an authority it cannot enforce. Independently
shippable once US2 has landed.

---

## Phase 6: User Story 4 — The link checker stops flagging a regex as a link (#43, Priority: P4)

**Goal**: a code span or fenced code block containing `](` no longer fails the link-resolution
gate; a genuine broken link outside one still does.

**Independent Test**: write the schema's literal `name` pattern into a code span in `README.md`
and confirm the gate passes.

- [X] T019 [US4] Rewrite the link-target extraction in the "Internal markdown links resolve"
      section of `scripts/verify.sh` to strip fenced code blocks and inline code spans from each
      markdown file's text before matching `\]\([^)]+\)` — moving the check from the current raw
      `grep` into Python, per research.md R4's chosen option (FR-007). Population (which files are
      scanned) and the `found`-counter semantics were kept identical to the old pipeline —
      confirmed live, 148 checked before and after the rewrite on the unmutated repo
- [X] T020 [US4] Confirm the section's existing anti-silent-green guard (`found -eq 0` → `FAIL`)
      and its `https?|mailto` exclusion still behave unchanged after the rewrite. **Confirmed
      live**: `ok    no dangling internal links (148 checked)`
- [X] T021 [P] [US4] Probe rather than trust: add a markdown link with a non-existent target
      outside any code span to a scratch file, run `bash scripts/verify.sh`, confirm the section
      **FAILS** naming it, then remove the scratch file and confirm `ok` returns (FR-008;
      contracts/verify-sections.md § Acceptance). **Confirmed live**: `FAIL
      ./specs/005-fix-milestone-bugs/scratch-probe.md -> this-path-does-not-exist.md`; removed,
      `ok` returned
- [X] T022 [US4] Replace `README.md`'s `name` field row prose paraphrase with the literal,
      unmodified pattern from `$defs/name/pattern` — do this only after T019 lands, so the literal
      regex does not transiently fail the unfixed checker (FR-009; research.md R4 "Follow-on")
- [X] T023 [US4] Run `bash scripts/verify.sh` and confirm the "Internal markdown links resolve"
      section reports `ok`, not `FAIL`, with the literal pattern now live in `README.md` (SC-004).
      **Confirmed live: ok, 148 checked**
- [X] T024 [US4] Run `bash scripts/verify.sh` in full and confirm `PASS`. **Confirmed live: PASS**

**Checkpoint**: the schema's `name` pattern can be quoted verbatim anywhere in the repository
without failing the build. Independently shippable.

---

## Phase 7: User Story 5 — The scaffolding record matches the repository it describes (#46, Priority: P5)

**Goal**: `.copier-answers.yml`'s six drifted answers agree with current `AGENTS.md`/`README.md`.

**Independent Test**: compare each of the six answers against current `AGENTS.md`/`README.md`
content.

- [X] T025 [US5] Bring `.copier-answers.yml` into agreement with the `AGENTS.md` it regenerates
      (FR-010, FR-011; research.md R5 table). **Corrected after review.** As first shipped this
      task claimed six answers and was ticked against FR-011's "must be produced by re-answering"
      on a fallback whose stated precondition — Copier unavailable — was false: Copier 9.16.0 was
      installed and GitHub reachable. Both problems are now closed, and not by re-typing the values
      into a prompt:
      (a) **Seven, not six.** Issue #46's table names `test_model`, which the spec had dropped;
      `project_tagline` comes from the issue's closing prose, not its table. All seven are
      corrected, and `test_model` regained the final sentence it had lost (`examples/` is the
      validated corpus and the only place documents are published).
      (b) **An eighth, found by testing rather than reading.** `commands` still globbed
      `docs/**/*.yaml`; the round-trip below proved a real `copier recopy` reverts that line —
      issue #46's stated failure, still happening. Corrected, along with its `grep-based` wording
      that R4 falsified.
      (c) **Verified by rendering, not by comparing.** `copier recopy --defaults --trust
      --overwrite --vcs-ref d8b7cd1` on a throwaway copy now produces an `AGENTS.md`
      **byte-identical** to the one on disk. That is a stronger check than the original FR-011
      asked for: it tests the property the "never hand-edit" header protects, rather than the
      provenance of the keystrokes. FR-011 and US5 Acceptance Scenario 3 were rewritten to require
      this test
- [X] T026 [US5] Compare each corrected value against the `AGENTS.md` section it feeds and confirm
      agreement (SC-005). **Confirmed live**: `role`, `stack_detail`, `architecture` and
      `test_model` each report EXACT MATCH after whitespace normalisation; the byte-identical
      re-render in T025(c) covers all eight at once
- [X] T027 [P] [US5] Confirm no unintended answer changed. **Corrected after review**: this task
      originally asserted the diff "touches only the six", which was false — it touched seven, and
      now eight. Verified as shipped: `_commit`, `_src_path`, `org_repo`, `project_name`, `do_git`,
      `run_speckit`, `stack`, `build_test_cmd`, `publish_mechanism` and `release_notes_tool` are
      untouched

**Checkpoint**: the next `copier update` will regenerate `AGENTS.md` sections that already match
what is on disk. Independently shippable, and does not touch `scripts/verify.sh` or the schema.

---

## Phase 8: Review response (Codex + cloud review + adversarial verification)

Three reviews ran against the working tree: Codex (4 findings), a cloud review (2), and a
9-agent adversarial workflow that verified all 6 and hunted for what they missed (13 more).
**All 6 were CONFIRMED — none was a false positive** — and the workflow's own top finding
(T030) was one no review had caught. Every fix below is probed, not asserted.

The pattern worth recording: R4 (#43) traded a *loud* false positive for four *silent* false
negatives. The old `grep` over-reported; the replacement under-reported, and under this
repository's own Principle III that is the worse direction. The fixes below restore what the
grep caught while keeping what #43 set out to fix.

- [X] T030 Resolve a link target beginning with `/` against the repository root, as GitHub
      renders it, instead of `os.path.join`-ing it onto the file's directory — which discards the
      base and escapes to the machine's filesystem root. Both directions were live-reproduced: a
      dangling link to a machine-absolute path reported `ok` (silent green), and a valid root-relative link to
      the schema hard-FAILed. The `grep` this replaced got the second case right (FR-008)
- [X] T031 Stop an escaped backtick from opening a code span. `\`` is literal text in CommonMark,
      but `CODE_SPAN` paired it with the next real backtick and, being `re.DOTALL`, masked
      everything between — one stray escape in prose hid three dangling links on two lines. Blanked
      before pairing, so it can neither open nor close. The obvious one-token fix `(?<!\\)` is
      wrong and was rejected: inside a span a backslash is already literal, so there `\`` really
      does close (FR-007, FR-008)
- [X] T032 Allow CommonMark's 1–3 spaces of fence indentation on **both** fence regexes, not just
      the tilde one. The backtick anchor was equally wrong and merely masked by `CODE_SPAN`
      matching the delimiters as a span (FR-007)
- [X] T033 Stop a link destination matching across a newline: whole-file `[^)]+` paired `](` with
      a `)` paragraphs away and failed the build on the blob between. The line-based `grep` could
      not do this. A destination split across lines is not scanned — a recorded gap, stated in
      `scripts/mdlinks.py`, matching prior behaviour (FR-007)
- [X] T034 Fail a file that cannot be read as UTF-8 instead of aborting the section on a traceback
      that printed neither `ok` nor `FAIL` and left every later file unscanned. The sibling "Docs
      are English" section already had this guard; the new code was the only reader in the file
      without it — a section that cannot run must report FAIL, per the file's own header
- [X] T035 Give both link scanners one definition of a link (`scripts/mdlinks.py`), used by
      resolution and by `docs/` isolation. Held apart they disagreed: a code span naming a path
      under `docs/` was text to one gate and a violation to the other, which made the isolation
      rule impossible to state in the documents it governs. The isolation count moved 26 → 25,
      the miscount going away (FR-008a)
- [X] T036 Hold the extractor to fixtures on every run — nine cases, each a direction this
      scanner has actually been wrong in. #43 survived because nothing checked the checker; a fix
      with no fixture reverts the next time someone tunes the regex
- [X] T037 Fail the self-check if no closure probe remains. The examples half already guarded
      `checked == 0`; the probes half would have printed `ok ... 0 closures still reject` and
      passed. Probed by emptying the dict after all assignments: `FAIL`, exit 1 (FR-002a)
- [X] T038 Delete the README "wart" paragraph, which told readers to expect and dismiss
      `Unevaluated properties are not allowed` — a message #42 made unreachable. Replaced with what
      is true: a bad *value* gives one message, a misspelled *key* gives two that both name it.
      All ten rows of the error table above it were re-validated against the current schema and
      reproduce verbatim (FR-009)
- [X] T039 Correct the false "1 error" claims for the misspelled-key case in T012 and research.md
      R2 — the count is 2 and always was. What #42 improved is *which* two: neither now blames a
      valid key
- [X] T040 Correct the quickstart's dead probe recipe. "Re-add `unevaluatedProperties: false`" is a
      *tightening*: the section stays `ok`, and worse, it silently reinstates #42's double-error
      behaviour, which no gate section detects. Replaced with two recipes verified to FAIL
- [X] T041 Correct the spec's transcription of issue #46 from six answers to seven (its table names
      `test_model`; `project_tagline` comes from its closing prose), restore the sentence
      `test_model` had lost, and fix `plan.md`'s "fourteen answers" — the file has 16
- [X] T042 Correct `criteria.items` / `unevaluatedProperties` references in US1's Independent Test,
      Acceptance Scenario 2 and FR-002: US2 removes those closures, so the instructions named
      something that no longer exists to remove
- [X] T043 Restore SC-003's "each of the seven" in `contracts/verify-sections.md`, which had
      quietly become "one of the seven", and run the sweep: **all seven probes flip exactly their
      own closure**. The repointed root probe covers a closure nothing else does, so the T002
      repoint was sound
- [X] T044 Bring `commands` into agreement and prove #46 mechanically. A real `copier recopy` at
      the recorded `_commit` showed one line still reverting — the `docs/**/*.yaml` glob — which is
      #46's stated failure still occurring. Fixed, along with the `grep-based` wording R4
      falsified in both `AGENTS.md` and the answer. Re-render now yields a **byte-identical**
      `AGENTS.md`, and FR-011 was rewritten to require that test instead of the unfalsifiable
      "was it typed into a prompt"

- [X] T045 Rewrite `scripts/mdlinks.py` as a line scanner after a second review round found the
      regex version wrong in the *silent* direction on three counts: one stray backtick hid every
      link to the next backtick (`re.DOTALL`, unbounded); an escaped backtick inside a well-formed
      span broke the span, hiding what followed; and a four-backtick fence closed on the next
      three-backtick line, swallowing a real link. Code spans are now paired per line, so a stray
      backtick costs one line; fences are a proper state machine (3+ delimiters, longer closes,
      indentation, blockquote prefixes, info strings); an escaped backtick cannot open a span but
      can still close one, which is what CommonMark does and what the previous fix got backwards.
      Validated against the `marked` renderer over 14 shapes: **13 exact matches, 1 deliberate
      over-report, 0 silent misses**
- [X] T046 Take a CommonMark link title off the destination — a link written with a quoted title
      after the path addresses only the path, and taking
      the target whole failed the build on a link that renders correctly
- [X] T047 Give `resolve()` its own fixtures. FR-008a said the definition is checked on every run,
      but the fixtures covered only `targets()`; T030 — the round's own headline fix — had no
      guard, so reverting it left the gate green. Probed: reverting it now fails the selftest
- [X] T048 Give the fixture list a floor, for the same reason the probes have one: an emptied
      SELFTEST returns no failures and reads exactly like a sound extractor
- [X] T049 Cover the schema. A sweep of every single-constraint loosening found **39 of 41 left the
      gate green** — the entire closed vocabulary among them, including the `mss` typo
      `$defs/unit`'s own description promises is a parse error, plus every `required`, every
      `type`, both `const`s, and all four of `$defs/predicate`'s cross-field rules. `guards.items`
      could be detached from the predicate definition entirely while the identical edit to
      `criteria.items` was caught. Probes went 7 → 54, one per constraint; the sweep now reports
      **40 of 41 caught**. The exception, `$defs/predicate.type`, changes no verdict when removed,
      so no document can probe it — recorded in the section rather than left looking like coverage
- [X] T050 Pin the message, not just the verdict, for `A fraction has no percentile`. It is
      redundant for validity — a fraction has no metric, and every aggregation but `rate` and
      `count` needs one — so no rejection probe can reach it, and a review round called it dead
      code on that basis. It is not: it is what produces `'p95' is not one of ['rate', 'count']`,
      the message `README.md` quotes for that mistake. Delete it and the document is still refused,
      now blaming a missing `metric` the author never meant to write. Checked by message
- [X] T051 Correct what the correction round itself broke or left stale: `contracts/` still called
      the isolation section unchanged (three sections changed, not two); `plan.md` still said "no
      file is added" four lines under a table listing a new one; `data-model.md` omitted
      `.gitignore` and the second `README.md` edit and said three cross-field rules where there are
      four; `tasks.md`'s parallel example still carried the "exactly one error" claim T039 had just
      corrected, and cited T034 for the sweep that is T043; `research.md` R5 still prescribed the
      method FR-011 replaced; `quickstart.md` §5 still hand-compared six of eight answers and
      claimed no automated oracle exists, when the oracle is now the criterion — its command block
      is the real round-trip, and it runs verbatim
- [X] T052 Add `scripts/` to `AGENTS.md`'s Structure line — the gate and the module it now imports
      lived in the one directory the index did not mention — and mirror it into the answer record.
      Round-trip re-run after the edit: still byte-identical

**Checkpoint**: every confirmed finding is fixed and probed. Three are deliberately *not* fixed —
see Deferred below.

---

## Deferred — real, verified, and out of this change's scope

Each was confirmed against the repository. None is caused by these five fixes, and folding them in
would violate `AGENTS.md`'s "1 concern per PR". Each wants its own issue in v0.3.0.

- **`$defs/aggregation.description`** still explains `rate` in terms of `indicator`, `distribution`
  and `ratio` — constructs the schema rejects — and says the overload resolves "by the metric's
  type", which it cannot: `metric` is a bare string. `README.md` and `GLOSSARY.md` both say it
  resolves by the presence of `bad`/`good`. The schema is the thing that decides, so this is a
  second and disagreeing source for one rule, visible on hover in any schema-aware editor.
- **`$defs/selector.description`** says the selector "Selects time series"; `README.md` and
  `GLOSSARY.md` say it selects *requests*. `series` belongs to the retired `indicator` model.
- **Nothing gates the `copier` round-trip.** T044's check is run by hand. The drift #46 exists to
  fix went unobserved for as long as nothing rendered the template, and that is still true of the
  next drift.

---

## Phase 9: User Story 6 — The schema documents itself (#31, Priority: P6)

The one `feat` here, added after the five fixes when #31 turned out to have a stale premise of
its own — it claims the schema carries no examples anywhere, and three definitions have carried
them since `7f33bdf`. Its own commit, so the bug fixes stay separable.

- [X] T053 [US6] Add `examples` to the schema root — one complete, minimal valid document, the
      shape an editor offers first and the one the gate previously never read (FR-013). The
      example is `examples/one-request-is-fast.yaml` **minus its optional `displayName`** — the
      smallest thing the schema accepts, which that file is not quite, since it carries one
- [X] T054 [US6] Add `examples` to `name`, `unit`, `op`, `aggregation`, `annotations` and
      `displayName`, the six definitions carrying none (FR-013). Embedded examples go 8 → 23
- [X] T055 [US6] Derive the "must carry examples" set from `schema["$defs"]` instead of the
      hand-kept `WANT` list, and validate the root example, which the section did not read
      (FR-014)
- [X] T056 [P] [US6] Probe rather than trust: strip `examples` from one definition and from the
      root in turn, confirm the gate FAILS naming each, then restore. **Confirmed live across 13
      mutations** — the root, all nine definitions, an example the schema rejects, a root example
      that is not a valid document, and a newly added definition carrying no examples, which is
      the drift the derived list exists to catch. All 13 caught
- [X] T057 [P] [US6] Confirm every embedded example validates against the definition it
      illustrates, and that the root example validates as a whole document (SC-007). **Confirmed
      live: 23 embedded examples valid**
- [X] T058 [US6] Run `bash scripts/verify.sh` in full and confirm `PASS`. **Confirmed live: PASS**

- [X] T059 [US6] Apply a second review of US6. It found the derived set was keyed on `$defs`, so a
      shape could escape the requirement by moving: inlining every `$ref`, or relocating all nine
      definitions to `#/definitions/`, left the check iterating nothing and reporting `ok`. The set
      is now derived from where shapes are **used** — every `$ref` target, every object defined
      inline at any depth, and the root — with floors on both the shape count and the example
      count. Also: `sub()` keeps `$id` (an absolute `$ref` was resolving to the published schema
      instead of the file under review), a dangling `$ref` reports instead of tracebacking, a shape
      that asserts nothing fails rather than accepting any example, and the root example is held to
      the criterionId uniqueness rule the corpus answers to. Probed: 10 mutations, all caught
- [X] T060 [US6] Fix what the examples themselves taught. `$defs/unit` offered `%` and
      `{request}/s`, neither valid as an unquoted YAML scalar, for a feature whose purpose is YAML
      completion. `name` and `displayName` are `$ref`'d from three sites each and the annotation is
      collected at every one, so `metadata.name` was offering a predicate identifier; the shared
      examples are now site-neutral and the specific ones sit on the `$ref` siblings

**Checkpoint**: the schema answers "what does this look like?" for every definition it has.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [X] T028 [P] Run the full [quickstart.md](quickstart.md) validation sequence (§ 1–6) end to end
      and confirm every expected output matches, now that all five stories have landed.
      **Confirmed live**: all six steps match their documented expected output exactly
- [X] T029 Run `bash scripts/verify.sh` once more from a clean `git status` and confirm `PASS`,
      all eight sections `ok`, none reporting a scan of zero files (SC-001). **Confirmed live:
      PASS**, all 8 sections `ok`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies — start immediately
- **Foundational (Phase 2)**: none — nothing blocks all five stories together
- **User Stories (Phase 3–7)**: all can start once Setup (T001) is done, except US3, which waits
  on US2
- **Review response (Phase 8)**: after the five stories have landed and been reviewed
- **User Story 6 (Phase 9)**: after the review response; independent of every other story
- **Polish (Phase 10)**: after User Story 6

### User Story Dependencies

- **US1 (#37, P1)**: independent — no dependency on any other story
- **US2 (#42, P2)**: independent of US1, US4, US5 — but **must land before US3**
- **US3 (#38, P3)**: **depends on US2** (both edit `criteria.items`/`guards.items` — see T015)
- **US4 (#43, P4)**: independent of all other stories
- **US5 (#46, P5)**: independent of all other stories; touches neither `scripts/verify.sh` nor the
  schema

### Within Each User Story

- Schema/script edits before verification tasks
- Verification tasks that read-but-don't-write can run in parallel with each other once the edit
  they check is done
- Each story's own full `bash scripts/verify.sh` run is the last task and is never parallel

### Parallel Opportunities

- US1, US2, US4 and US5 can all start immediately after Setup and be worked on by different people
  at the same time
- US3 can start as soon as US2's T007–T009 land (not necessarily all of US2's later tasks)
- Within US2, US3 and US5, the read-only confirmation tasks marked `[P]` can run together
- US1 and US4 both edit `scripts/verify.sh`, but in different sections (`SELFCHECK` vs. the link
  check) — parallelizable by different people, reconciled at merge like any two-PR overlap on one
  file

---

## Parallel Example: User Story 2

```bash
# After T007–T009 land, run these together:
Task: "Validate the three examples/ files against the changed schema — zero regressions"
Task: "Validate a requirement with unit: mss — expect exactly one error"
Task: "Validate a requirement with an unknown predicate key — expect two errors, both naming it"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 3: User Story 1 (#37)
3. **STOP and VALIDATE**: the gate's own self-check can now fail on command (T005)
4. Ship — fixing #37 first is what makes every later story's "zero regressions, probed not
   assumed" claim trustworthy, since it is the check most of that probing leans on

### Incremental Delivery

1. Setup → US1 (#37) → validate → ship (MVP)
2. Add US2 (#42) → validate → ship
3. Add US3 (#38) → validate → ship (only after US2)
4. Add US4 (#43) → validate → ship
5. Add US5 (#46) → validate → ship
6. Polish: full quickstart sweep, final gate run

Five commits, five PRs, per `AGENTS.md`'s "1 issue = 1 commit" / "1 concern per PR" — this is not
an optional sequencing suggestion for this feature, it is the delivery shape spec.md's Assumptions
already commits to.

### Parallel Team Strategy

With multiple contributors: one person takes US1, another US2 (with a third queued for US3 once
US2's schema edit lands), a fourth takes US4, a fifth takes US5. All five converge on Polish.

---

## Notes

- `[P]` tasks touch different files, or are read-only checks with no dependency on another
  incomplete task
- `[Story]` label maps every task to the milestone issue it closes
- Every story's last task is a full `bash scripts/verify.sh` run — no story is "done" on a
  partial gate
- "Probe rather than trust" (T005, T021) is this repository's own idiom (see
  `specs/004-strip-to-schema/tasks.md` T032): a fix to a check is not confirmed by reading the
  diff, it is confirmed by making the check fail on purpose, once, and watching it do so
- Commit after each story, not after each task — `AGENTS.md`'s "1 issue = 1 commit"
- Every PR MUST be assigned to milestone **v0.3.0** (`github.com/galax-io/opennfr/milestone/3`)
  before merging, and each issue it closes MUST be closed when it lands on `main` — the six issues
  this spec covers moved there when v0.2.0 released (spec.md, Clarifications, Session 2026-08-23);
  do not assign to v0.2.0, which is already shipped
