# Feature Specification: Fix Milestone v0.3.0 Bugs

**Feature Branch**: `005-fix-milestone-bugs`

**Created**: 2026-08-23

**Status**: Draft

**Input**: User description (translated from Russian; this repository's `bash scripts/verify.sh` requires English-only documentation, `specs/` included): "Fix all the bugs in milestone https://github.com/galax-io/opennfr/milestone/2" — the milestone this pointed to has since been renumbered; see Scope note and Clarifications.

**Scope note**: The six issues this spec covers (#31, #37, #38, #42, #43, #46) were originally filed against milestone v0.2.0 (`github.com/galax-io/opennfr/milestone/2`). That milestone has since **shipped** (`v0.2.0` released 2026-08-23, tag and GitHub Release both live) with all its other work closed, and these six — the only ones still open at release time — were moved to the new **milestone v0.3.0** (`github.com/galax-io/opennfr/milestone/3`), which is now the active milestone for this spec's PRs per `AGENTS.md`. Five describe defects — something that is broken, misleading, or silently wrong today: #37, #42, #38, #43, #46. The sixth, #31, asks to *add* a capability the schema does not fully have. It is an enhancement rather than a bug and was first held out of this spec on that ground; it was picked up on 2026-08-24 once its premise turned out to be stale too. It is User Story 6, and the only `feat` here. See Clarifications and Assumptions.

## Clarifications

### Session 2026-08-23

- Q: Should issue #31 ("the schema carries no examples") stay out of this bug-fix spec, or be included? → A: Keep it out — #31 is an enhancement (add examples), not a bug; this spec stays scoped to the 5 defects (#37, #42, #38, #43, #46).
- Q (2026-08-24, reversing the above): should #31 be picked up after all? → A: yes, together with a correction to the issue itself. The classification stands — #31 is an enhancement, not a bug — but the issue's premise had gone stale in exactly the way three of the five defects had, and that was missed when it was set aside. It claims the schema carries no examples anywhere; #33/#34 (`7f33bdf`, 22 August) added them to `selector`, `predicate` and `requirement` the day after it was filed, and two definitions it asks for (`series`, `indicator`) no longer exist. The issue was rewritten against the current file, and the remaining work is User Story 6 below. It ships as its own commit, and is the one story in this spec that is a `feat` rather than a `fix`.
- Correction (user-reported, not a formal clarification question): milestone v0.2.0 released and its remaining open issues — the same six this spec already covers — were renumbered to milestone v0.3.0 (`github.com/galax-io/opennfr/milestone/3`), confirmed via `gh api repos/galax-io/opennfr/milestones` (v0.2.0: 0 open issues, released; v0.3.0: 6 open issues, matching this spec exactly). No issue, priority, requirement or fix in this spec changes — only the milestone every resulting PR must be assigned to (`AGENTS.md`, "Milestones (ALWAYS)").

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The verification gate must actually verify (Priority: P1)

A maintainer changes `criteria.items` in the schema — say, drops `additionalProperties: false` — expecting `bash scripts/verify.sh` to catch it, because the gate has a dedicated self-check section for exactly this class of regression ("closures still reject"). Today every one of those seven probes is built on a base document that is already invalid *before* the intended mutation is applied, so each probe is rejected for a reason unrelated to what it claims to test. The section prints `ok` regardless of whether the schema actually still closes over its properties.

**Why this priority**: This is the safety net for every other change in the schema, including the other four fixes in this spec. If it cannot fail, nothing that depends on it (including the fixes below) can be trusted as verified. It must be fixed first, or verified independently of the others.

**Independent Test**: Run `bash scripts/verify.sh` after asserting the seven probes' shared base document validates cleanly *before* mutation; deliberately drop a closure (e.g. remove `additionalProperties: false` from `$defs/requirement`) and confirm the corresponding probe now fails instead of reporting `ok`. Name a closure that exists *after* US2 lands: US2 removes the `unevaluatedProperties: false` wrappers, so `criteria.items` has no closure of its own to drop.

**Acceptance Scenarios**:

1. **Given** the shared base document used by the seven closure probes, **When** it is validated unmutated, **Then** it is accepted (zero errors) — establishing that any later rejection is caused by the mutation, not by pre-existing drift.
2. **Given** a schema where a closure (e.g. `additionalProperties: false` on `$defs/requirement`, or `$defs/displayName`'s `maxLength`) has been accidentally removed or loosened, **When** `bash scripts/verify.sh` runs, **Then** the corresponding probe fails and the run reports the loss instead of printing `ok`.
3. **Given** the current, correct schema, **When** `bash scripts/verify.sh` runs, **Then** all seven probes still pass for the right reason (each rejected only by the closure it targets).

---

### User Story 2 - One mistake, one error message (Priority: P2)

A contributor writes a requirement with `unit: mss` (a typo for `ms`). Validation reports the correct error — `'mss' is not one of [...]` — immediately followed by a second error blaming `aggregation`, `metric`, `op`, `threshold`, and `unit` as a group of "unevaluated properties," even though every one of those keys is exactly what a predicate is supposed to have. The second message is noise that obscures the first, real diagnosis, on every single predicate mistake (bad unit, missing metric, bad percentile — all of them).

**Why this priority**: The format's stated argument for strict schemas is that they catch typos with a clear diagnostic. A confusing double-error on the single most common mistake (a predicate typo) undermines that argument for every person who ever writes a document by hand.

**Independent Test**: Validate a requirement with a single deliberate predicate defect (e.g. `unit: mss`) against the schema and confirm exactly one error is reported, naming only the actually-invalid field.

**Acceptance Scenarios**:

1. **Given** a requirement whose only defect is an invalid `unit` value, **When** it is validated, **Then** exactly one error is reported and it identifies `unit` as invalid — no second error lists the requirement's valid fields as unevaluated.
2. **Given** a requirement missing the required `metric` field, **When** it is validated, **Then** the reported error(s) identify `metric` as missing, without a companion "unevaluated properties" error naming the fields that are present and valid.
3. **Given** the existing validated corpus in `examples/`, **When** each document is re-validated, **Then** every one still validates (no change in what is accepted).

---

### User Story 3 - A schema rule that can never fire is removed (Priority: P3)

`$defs/requirement` carries an `allOf` block whose `if` checks for an `indicator` property that the same object's `additionalProperties: false` already forbids at that level — no document that validates can ever satisfy the `if`, so the `then` (restricting `criteria[].aggregation` to `rate`/`count` for a ratio indicator) never applies. The rule it was meant to enforce already lives, and works, inside the predicate definition since #33. Separately, `guards.items` carries a no-op `"properties": {}` that its sibling `criteria.items` does not have.

**Why this priority**: This sits in the compatibility-sensitive schema surface, cites the glossary as its authority, and enforces nothing — the next person who reworks `requirement` could "fix" the unreachable condition and accidentally reinstate a constraint nobody actually argued for. It is a latent risk, not an active malfunction, so it ranks below the two fixes above.

**Independent Test**: Remove the unreachable `allOf` and the no-op `properties: {}`, then confirm `bash scripts/verify.sh` stays green and no document in `examples/` changes meaning (all still validate, and no previously-rejected document becomes accepted).

**Acceptance Scenarios**:

1. **Given** the current `$defs/requirement`, **When** any document is validated, **Then** the unreachable `allOf`'s `then` branch has no observable effect (already true today — confirmed as a precondition, not introduced).
2. **Given** the schema with the unreachable `allOf` and the no-op `properties: {}` removed, **When** the full `examples/` corpus is validated, **Then** every document validates exactly as it did before the change.
3. **Given** the cleaned-up schema, **When** a ratio-indicator requirement uses an aggregation other than `rate`/`count` in a `bad`/`good` predicate, **Then** it is still rejected — by the predicate-level rule from #33, which was already carrying this constraint.

---

### User Story 4 - The link checker stops flagging a regex as a link (Priority: P4)

The schema's `name` field is validated by a regular expression whose bracket-group-then-parenthesized-group shape closes a `]` immediately followed by a `(` — the same two characters, adjacent, that mark the start of a markdown link target. The gate's link-resolution check is a raw grep for that adjacency with no awareness of code fences or code spans, so writing the pattern's real characters into a code span anywhere under version control fails the build. (Confirmed reproducible today — verified during planning, not assumed from the source issue: pasting the schema's literal `name` pattern into a code span, in this spec's own draft and in a scratch edit to `README.md`, both tripped the same false positive; see `research.md` for the reproduction.) The source issue describes an earlier workaround — spacing the pattern's characters apart and adding a sentence explaining why — that a later, unrelated restructuring of this repository's documentation has since superseded: `README.md` today states the pattern in paraphrased prose instead of as a literal regex, which happens to avoid the trigger too, but leaves the reference less precise than the schema it describes, and leaves the underlying checker bug unfixed and ready to resurface the moment anyone writes the pattern out literally again — as this very spec did.

**Why this priority**: It blocks accurate documentation — today's paraphrase is a workaround by another name — and stands ready to fail the build again the moment anyone writes the schema's actual pattern into a code span, as happened while drafting this spec. It doesn't threaten the schema's own correctness, so it ranks below the diagnostic and gate fixes above.

**Independent Test**: Write the exact `name` pattern regex into a code span in `README.md`, run `bash scripts/verify.sh`, and confirm the link check passes.

**Acceptance Scenarios**:

1. **Given** a markdown code span or fenced code block containing a closing bracket immediately followed by an opening parenthesis (the two characters that also open a markdown link target), **When** the link-resolution check runs, **Then** it does not treat that text as a link to resolve.
2. **Given** the `name` pattern written verbatim (with real, unmodified regex characters) in `README.md`, **When** `bash scripts/verify.sh` runs, **Then** the link check passes.
3. **Given** a genuine broken markdown link outside any code span or fence, **When** the link-resolution check runs, **Then** it still fails the gate as before (no loss of detection).
4. **Given** the fix has landed, **When** `README.md`'s `name` field row is restated as the literal, unmodified pattern in place of today's prose paraphrase, **Then** `bash scripts/verify.sh` passes — proving the fix, not just describing it.

---

### User Story 5 - The scaffolding record matches the repository it describes (Priority: P5)

`.copier-answers.yml` is the record Copier uses to regenerate scaffolded files, including sections of `AGENTS.md`, on `copier update` — its own header says never to hand-edit it. Seven of its recorded answers describe a state of the repository that AGENTS.md has since corrected (paths that moved, a schema that now exists, framing the README stopped using): the six issue #46 tabulates — `architecture`, `structure`, `stack_detail`, `dep_manifest`, `role`, `test_model` — plus `project_tagline`, which the issue names in its closing prose rather than its table. An eighth, `commands`, is found drifted by the round-trip test in Acceptance Scenario 2 and is corrected here for that reason rather than because the issue names it. Nothing is broken today, but the next `copier update` will regenerate `AGENTS.md` from these stale answers and silently revert every one of those corrections.

**Why this priority**: The defect is real but dormant — it only manifests on the next template update, which is not guaranteed to happen during this milestone. It is included because it is a confirmed, described bug (not a hypothetical), but it is the least urgent of the five.

**Independent Test**: Render the template at the recorded `_commit` from the corrected answers and diff the `AGENTS.md` it produces against the one on disk. Identical output is the whole claim; anything else means the record still reverts a correction.

**Acceptance Scenarios**:

1. **Given** the current `.copier-answers.yml`, **When** each answer is compared against the `AGENTS.md` section it feeds, **Then** every one matches what `AGENTS.md` actually says today.
2. **Given** the corrected answers, **When** the template is actually re-rendered at the recorded `_commit`, **Then** the `AGENTS.md` it produces is **byte-identical** to the file on disk.
3. **Given** the fix, **When** the record is inspected, **Then** no answer disagrees with what the template would produce from it — which is what the "never hand-edit" header exists to protect, and what Scenario 2 tests directly.

---

### User Story 6 - The schema documents itself (#31, Priority: P6)

Someone opens an editor with schema support and starts a requirement document. The editor can
suggest a shape for a selector, a predicate and a requirement, because those three definitions
carry `examples`. For everything else — the document itself, a name, a unit, an operator, an
aggregation, an annotation, a display name — it has nothing to offer, and the author goes to the
prose instead. The root is the sharpest gap: it is the first completion an editor would give, and
the one shape a person writing their first document actually needs.

**Why this priority**: last, and the only story here that is not a defect. Nothing is broken, no
check is silent, no document is wrong; the format is simply harder to write than it needs to be.
It ships as `feat` after all five fixes so the bug-fix commits stay separable from it.

**Independent Test**: read the schema's own `examples` for each definition and confirm every one
validates against the definition it illustrates, and that the root example validates as a whole
document.

**Acceptance Scenarios**:

1. **Given** the schema, **When** its definitions are enumerated, **Then** every one carries at
   least one `examples` entry, and so does the root.
2. **Given** each embedded example, **When** it is validated against the definition it illustrates,
   **Then** it is accepted — an example the schema rejects teaches a shape that does not exist.
3. **Given** a definition added later with no `examples`, **When** `bash scripts/verify.sh` runs,
   **Then** it FAILS — the requirement is derived from the schema, not from a hand-kept list that a
   new definition silently escapes.
4. **Given** the root example, **When** it is validated against the whole schema, **Then** it is
   accepted, and the gate is what checked it: the root was previously not read at all.

---

### Edge Cases

- What happens when a document has more than one predicate defect at once (e.g. a bad unit on one criterion and a missing metric on another)? Each real defect must still be reported on its own, without either being obscured by an "unevaluated properties" message naming valid fields.
- What happens to a document that (accidentally) depended on the unreachable `allOf` or the no-op `properties: {}` having some effect? None should exist, since both were provably inert — but every document in `examples/` must be re-validated to confirm no meaning changed.
- What happens when the link check encounters a code span that legitimately contains link-shaped text pointing at a real, resolvable path? It must still be skipped as non-link content (code spans are never treated as links, regardless of their contents) — this is a deliberate scope boundary, not a partial fix.
- What happens if `.copier-answers.yml` drifts again after this fix (a future AGENTS.md correction not mirrored back into the answers)? Nothing catches it: the round-trip test in FR-011 is run by hand here, not by `scripts/verify.sh`. Gating it is out of scope for this spec and worth its own issue — the drift this fix corrects went unobserved for exactly as long as nothing rendered the template.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The verification gate's schema self-check MUST confirm that the shared base document used by its "closures still reject" probes validates successfully *before* any probe-specific mutation is applied, so a probe's rejection can only be attributed to the mutation it targets.
- **FR-002**: The verification gate MUST fail (not report `ok`) when a probe's targeted closure (e.g. `additionalProperties: false`, a required field, a `maxLength` or `minLength` bound) is missing or loosened.
- **FR-002a**: The verification gate MUST fail rather than report `ok` if no closure probe remains — a probe that was deleted cannot fail, and a section reporting success over zero probes is the same defect FR-001 exists to remove.
- **FR-003**: Validating a requirement whose only defect is a single invalid predicate field MUST produce an error set that identifies only the actually-invalid field(s) — it MUST NOT also report the requirement's other, valid fields as "unevaluated."
- **FR-004**: The `$defs/requirement` schema definition MUST NOT contain a conditional (`if`/`then`) that can never match given that same object's own property constraints.
- **FR-005**: The constraint the unreachable conditional was meant to enforce (a ratio indicator's `bad`/`good` predicate restricted to `rate`/`count` aggregation) MUST remain enforced through the existing predicate-level rule, with no change in which documents validate.
- **FR-006**: `guards.items` and `criteria.items` MUST use the same schema construction for referencing the shared predicate definition, without either carrying a no-op addition the other lacks.
- **FR-007**: The verification gate's link-resolution check MUST NOT treat text inside a markdown code span or fenced code block as a link to be resolved, including a fence indented by up to three spaces and a code span whose delimiters are backslash-escaped (which are literal text, not delimiters).
- **FR-008**: The verification gate's link-resolution check MUST continue to detect and fail on a genuinely broken markdown link located outside code spans and fenced code blocks. It MUST resolve a target beginning with `/` against the repository root, as GitHub renders it, and MUST fail — never skip — a file it cannot read.
- **FR-008a**: Both link scanners in the gate — resolution and `docs/` isolation — MUST share one definition of what a markdown link is. That definition MUST be checked on every run against fixtures covering **both** halves, extraction and path resolution, and the fixture list MUST itself have a floor: an emptied list reports no failures and reads exactly like a sound extractor. Two scanners disagreeing made the isolation rule impossible to state in the documents it governs.
- **FR-002b**: Every constraint the schema makes MUST have a probe that fails when it is loosened, and the probe set MUST have a floor. Where a constraint cannot change a verdict — it is redundant for validity but produces a message the documentation quotes — the probe MUST check the message instead.
- **FR-009**: `README.md` MUST state the schema's `name` validation pattern as the literal, unmodified regular expression, in place of today's prose paraphrase, with no inserted spacing and no explanatory text about the verification gate's implementation.
- **FR-010**: `.copier-answers.yml`'s `architecture`, `structure`, `stack_detail`, `dep_manifest`, `role` and `test_model` answers (issue #46's table), plus `project_tagline` (its closing prose) and `commands` (found drifted by FR-011's test), MUST reflect the current content of `AGENTS.md` rather than the pre-correction state they describe.
- **FR-011**: Rendering the template at the recorded `_commit` from the corrected record MUST produce an `AGENTS.md` byte-identical to the one on disk. This is the requirement; *how* the values reached the file is not. The "never hand-edit" header exists to stop a record that disagrees with what the template would produce, and only re-rendering can show whether it does — a value typed into a prompt is no safer than one typed into the file if nobody renders it.
- **FR-012**: After all fixes, `bash scripts/verify.sh` MUST exit successfully (green) and every document currently in `examples/` MUST continue to validate.
- **FR-013**: The schema MUST carry `examples` at its root and on every definition, and every embedded example MUST validate against the definition it illustrates.
- **FR-014**: The gate MUST derive the set of definitions required to carry `examples` from the schema itself rather than from a hand-maintained list, and MUST validate the root example. A definition added later without examples MUST fail the gate.

### Key Entities

- **Verification gate probe**: A base document plus a targeted mutation, used by `scripts/verify.sh` to prove a specific schema closure is still enforced; must itself be provably valid before mutation.
- **Predicate validation error**: The set of error messages the schema produces for one invalid document; must map one real defect to one clear message, not one defect to two (one real, one spurious).
- **Requirement schema definition**: The compatibility-sensitive `$defs/requirement` object in `schema/opennfr.io/v1/requirementset.schema.json`; the surface where the unreachable conditional and the `guards`/`criteria` asymmetry live.
- **Scaffolding answer record**: `.copier-answers.yml`, the Copier-owned source of truth that regenerates parts of `AGENTS.md`; must stay synchronized with the file it generates.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `bash scripts/verify.sh` passes end to end after all five fixes land, with the full `examples/` corpus still validating (zero regressions).
- **SC-002**: Every message a predicate defect produces names that defect. An invalid *value* produces exactly one message, down from two. A misspelled *key* produces two — the key that is not expected and the key that is missing — where before, one of the two blamed five fields that were all correct.
- **SC-003**: All seven "closures still reject" probes in the verification gate fail when their targeted closure is deliberately removed from the schema (tested by temporarily reintroducing each of the seven prior gaps and confirming detection), instead of unconditionally reporting `ok`.
- **SC-004**: `README.md` states the `name` pattern as the exact regular expression from the schema — not today's prose paraphrase — with zero inserted characters and zero sentences explaining internal tooling, and the gate still passes.
- **SC-005**: `.copier-answers.yml`'s drifted answers are brought to zero, proved mechanically: re-rendering the template at the recorded `_commit` produces an `AGENTS.md` byte-identical to the one on disk.
- **SC-006**: The unreachable conditional and the `guards.items`/`criteria.items` construction asymmetry are both removed from the schema with no change in which documents validate.
- **SC-007**: Every definition in the schema, and the root, carries at least one example — from three of nine and no root — and each is validated by the gate rather than by inspection.

## Assumptions

- **Bug vs. enhancement boundary**: issue #31 requests a capability the schema does not fully have — an absence, not a malfunction. That classification did not change; the decision to act on it did (Clarifications, 2026-08-24). It ships as `feat`, in its own commit, after the five fixes, so the bug-fix commits stay separable from it.
- **Milestone (confirmed)**: this spec's six issues now live in milestone v0.3.0, not v0.2.0 — v0.2.0 shipped and these were the only issues still open at release time, moved forward rather than blocking the release. See Clarifications, Session 2026-08-23.
- **One fix, one change unit**: Consistent with this project's "1 issue = 1 commit" / "1 concern per PR" convention, the five user stories above are expected to ship as five independent changes, each verifiable on its own via `bash scripts/verify.sh` — not as a single combined change.
- **No behavior change beyond the defect**: Every fix (FR-003 through FR-006, FR-007 through FR-009) is a correction to diagnostics, dead logic, or documentation; none is expected to change which documents the schema accepts, except where a fix's entire purpose is to correct an incorrect accept/reject outcome (none of the five do — all five are diagnostics, dead-code, or drift corrections, not acceptance-behavior changes).
- **Copier is available, and is what verifies the record**: FR-011's byte-identity test needs the template rendered at the recorded `_commit`, which needs Copier and network access to the template repository. Both were present. The test is run against a throwaway copy of the repository, never in place: `copier recopy --overwrite` rewrites template-managed files, and this repository has deliberately diverged from several of them.
