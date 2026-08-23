# Phase 0: Research

**Feature**: `005-fix-milestone-bugs` | **Date**: 2026-08-23

Five defects, five decisions. Each was reproduced against the current repository state before a
fix was chosen — the corpus, the schema and `README.md` have all moved since some of these issues
were filed, so the issue text is read as an argument, not as a literal diff to replay. Where a
proposed fix touches the schema, it was dry-run against the current three-file `examples/` corpus
and the schema's own embedded examples, not assumed to be regression-free.

Environment note, unrelated to any of the five: this sandbox's `python3` had neither `jsonschema`
nor `pyyaml` installed, which made three of `scripts/verify.sh`'s sections report `FAIL` for a
reason outside this feature's scope (`pip install jsonschema pyyaml` — this repository's own
`quickstart.md` precedent in `specs/004-strip-to-schema/` names the same prerequisite). Installed
locally for this research; not a repository change.

## R1 — Issue #37: the self-check probes pass for the wrong reason

**Decision**: Before the seven mutation probes run, assert their shared base document validates
with zero errors. Fail the section — not report `ok` — if either the base assertion or any probe
fails.

**Evidence**. The base document `scripts/verify.sh` builds for all seven probes, validated as-is
against the current schema:

```
spec/requirements/0: Additional properties are not allowed ('indicator' was unexpected)
spec/requirements/0: 'selector' is a required property
spec/requirements/0/criteria/0: 'metric' is a required property
spec/requirements/0/criteria/0: Unevaluated properties are not allowed ('aggregation', 'op', 'threshold', 'unit' were unexpected)
```

Four errors, before any probe's mutation is applied. Every probe's rejection is real — the base
document was already invalid — but attributes to the wrong cause. A closure that came loose (say,
`additionalProperties: false` dropped from a criterion) would still show a probe "passing"
(rejecting), for one of these four unrelated reasons, and the section would keep printing
`ok 8 embedded examples valid, 7 closures still reject` exactly as it does today. This matches the
issue's own diagnosis exactly, confirmed independently rather than taken on the issue's word.

**Rationale**: the fix has to repair the base document (add `selector`, drop the leftover
`indicator` key it never needed, add `metric` where `max` requires it — the four errors above,
resolved) *and* add the missing precondition assertion, or a future edit to the base document
could silently reintroduce the same vacuity in a new shape.

**Alternatives considered**: rewriting each of the seven probes as an independent, fully-valid
document (no shared base) — rejected as unnecessary duplication; the shared-base-plus-mutation
shape already in `scripts/verify.sh` is sound, it is only unchecked at its foundation.

**Implementation note, found while applying the fix, not anticipated here**: dropping the leftover
`indicator` key from `doc()` breaks the "displayName on a series" probe, whose mutation reached
into `indicator.distribution` — a construct that does not exist anywhere in the current schema
(dead since the assertion-first design it belonged to was reverted, the same root cause as issue
#38's dead conditional). That probe was repointed to test the same class of closure — an
`additionalProperties: false` object rejecting a `displayName` it never declared — at the document
root, the one place still uncovered. The probe count stays at seven; confirmed live that all seven
still reject correctly against the fixed base document.

## R2 — Issue #42: one defect, two error messages

**Decision**: give `$defs/predicate` `"additionalProperties": false` directly. Change
`criteria.items` and `guards.items` from `{"allOf": [{"$ref": "#/$defs/predicate"}], "unevaluatedProperties": false}`
to a plain `{"$ref": "#/$defs/predicate"}`.

**Evidence**. Dry-run against a copy of the current schema with this change applied:

| Case | Before | After |
|---|---|---|
| `unit: "mss"` (typo) | 2 errors: the real one, plus `Unevaluated properties are not allowed ('aggregation', 'metric', 'op', 'threshold', 'unit' were unexpected)` | **1 error**: `'mss' is not one of [...]` |
| Unknown key (`agregation`) | 2 errors: `'aggregation' is a required property`, plus the `unevaluatedProperties` message blaming five valid keys | **2 errors, both naming the typo**: `Additional properties are not allowed ('agregation' was unexpected)` and `'aggregation' is a required property` |
| Current valid requirement | 0 errors | **0 errors** |
| Full `examples/` corpus (3 files) | passes | **passes — 0 regressions** |

Note the second row honestly: the unknown-key case goes 2 errors → 2 errors, not 2 → 1. What
changes is *which* two. Before, one message named five perfectly valid keys as unexpected; after,
both messages name the offending key and nothing else. SC-002's "one defect, one message" holds
for a bad value, which is the common case; a misspelled key is inherently two facts — the key that
should not be there and the key that should — and saying so twice is the clearer diagnosis, not
noise. `README.md` states this where a document author will meet it.

**Rationale**: `unevaluatedProperties: false` evaluates against everything the sibling `allOf`
managed to evaluate; when the nested `$ref` fails validation for any reason, JSON Schema does not
credit it with evaluating anything, so every property the object actually has reads as
unevaluated. Closing `predicate` over its own properties removes the indirection: there is no
longer a sibling `unevaluatedProperties` keyword to misfire, because the object that owns
`additionalProperties: false` is the same object whose `required`/`properties` produced the real
error.

**Alternatives considered**: none — this is a mechanism fix, and JSON Schema Draft 2020-12 offers
exactly one way to avoid `unevaluatedProperties` blaming a failed `$ref`'s siblings: don't route
the object's own closure through `unevaluatedProperties` in the first place.

**Sequencing note**: this and R3 both edit `criteria.items`/`guards.items`. After R2 lands, both
are already a plain `$ref` with no `allOf` wrapper, so R3's remaining `guards.items` change (the
no-op `"properties": {}`) is a no-op if R2 already replaced the whole `items` value — confirm at
implementation time which of R2 or R3 lands first, and reconcile the other's diff against the
result rather than replaying it blindly.

## R3 — Issue #38: an `if` that can never match

**Decision**: delete the `allOf` block on `$defs/requirement` (the one whose `if` requires an
`indicator` property `requirement` neither declares nor allows). Delete the no-op
`"properties": {}` on `guards.items`.

**Evidence**: `requirement`'s `properties` are `name`, `guards`, `criteria`, `displayName`,
`selector` — no `indicator` — and `additionalProperties: false` forbids anything else. The `if`'s
`required: ["indicator"]` therefore cannot be satisfied by any document that validates; this is
provable by reading the schema and does not need a probe to confirm, though one was run anyway:
dry-run of the schema with both pieces removed against the current `examples/` corpus and the
schema's own embedded `selector`/`predicate`/`requirement` examples produced **zero regressions**
in either.

**Rationale**: matches the issue's own fix instruction exactly. The constraint the dead `if` was
trying to state (a ratio indicator's `bad`/`good` predicate limited to `rate`/`count`) already
lives, and is enforced, inside `$defs/predicate`'s own `allOf` (*"A fraction has no percentile"*) —
confirmed present in the schema read for this research, at `$defs/predicate/allOf[2]`.

**Alternatives considered**: none — the issue identifies the dead code precisely and the fix is
deletion; there is no design space here.

## R4 — Issue #43: the link checker reads a regex as a link

**Decision**: in `scripts/verify.sh`'s "Internal markdown links resolve" section, strip fenced
code blocks and inline code spans from each markdown file's text before applying the
`\]\([^)]+\)` extraction — moving the check from a raw `grep` into the Python this file already
reaches for whenever a check stops being one grep long (the "Docs are English" section's own
history, and the isolation section, are the precedent already in this file).

**Evidence, reproduced live against the current repository, not assumed from the issue**:

1. Pasting the schema's literal `name` pattern into a code span in a scratch copy of `README.md`
   (then reverted) made the link-resolution section fail with `FAIL ./README.md -> [a-z0-9-]*[a-z0-9]`.
2. This spec's own first draft of User Story 4 quoted the same literal pattern in a code span and
   tripped the identical failure against `specs/005-fix-milestone-bugs/spec.md` itself —
   independent confirmation, and the reason this spec's prose was rewritten to describe the
   pattern rather than quote it verbatim (see spec.md, User Story 4).
3. **Correction to the issue's premise, found during this research**: the workaround the issue
   describes — spaces inserted into the printed pattern, plus a sentence explaining why — is not
   present in the current `README.md`. The repository-wide restructuring in #47 (`schema/README.md`
   merged into root `README.md`) replaced it with a prose paraphrase (*"`^[a-z0-9]` then letters,
   digits and hyphens, no trailing hyphen"*), which avoids the false positive incidentally, without
   ever being written as a fix for it. A repo-wide grep for the workaround's telltale phrasing
   ("spaces are not real", "build tooling") found nothing outside this spec's own draft text. The
   spec (User Story 4, FR-009, SC-004) was corrected in place once this was confirmed, rather than
   left describing a workaround that no longer exists.

**Rationale**: matches the issue's own preferred option ("strip fenced blocks and code spans
before extracting"), rejected the issue's second option (skip non-path-shaped targets) for the
same reason the issue itself gives — cheaper, but leaves the next lookalike to be found the same
accidental way this one was.

**Follow-on, in scope per FR-009**: once the checker no longer misflags it, restate `README.md`'s
`name` field row as the literal regex in place of the current paraphrase — precise documentation
the checker bug was blocking, not a workaround to remove (there is none left to remove).

## R5 — Issue #46: the scaffolding record no longer matches the repository

**Decision**: bring `.copier-answers.yml` into agreement with the `AGENTS.md` it regenerates, and
verify that by re-rendering the template rather than by comparing text by hand.

> **Superseded during implementation, on both counts.** This section first named six answers and
> prescribed "re-answer, do not hand-edit". The six are seven: issue #46's table names
> `test_model`, which the transcription below dropped, while `project_tagline` comes from the
> issue's closing prose. And re-rendering found an eighth, `commands`, that no reading of the issue
> would have caught — a real `copier recopy` at the recorded `_commit` is the only thing that shows
> whether the record disagrees with what the template produces. See spec.md FR-010/FR-011 and
> tasks.md T025/T044.

**Evidence**: direct comparison, current `.copier-answers.yml` against current `AGENTS.md` /
`README.md`:

| Answer | Recorded value (excerpt) | Current reality |
|---|---|---|
| `architecture` | *"`docs/GLOSSARY.md` defines the terms... layering... in `docs/compatibility.md`"* | `GLOSSARY.md` is at the repository root; no `docs/compatibility.md` exists |
| `structure` | *"`docs/` -> the notes themselves; `docs/adr/`... `docs/examples/`... `docs/semconv/`... `docs/references.md`"* | `docs/` holds only `ideas.md`; none of the four named subpaths exist |
| `stack_detail` | *"No code... because there is no schema yet"* | a schema exists at `schema/opennfr.io/v1/requirementset.schema.json` and gates every commit |
| `dep_manifest` | *"`docs/GLOSSARY.md` is the vocabulary truth"* | `GLOSSARY.md` (root) is the vocabulary truth, per `AGENTS.md`'s own Boundaries section |
| `role` | *"This repo is a design notebook, not a product"* | `AGENTS.md`'s Role section now reads *"The format is minimally usable — a schema, a validated corpus and a gate"* |
| `project_tagline` | *"Design notes toward an open, tool-agnostic format... Nothing is stable yet"* | superseded framing per issue #46, citing #40 |

Six for six: every answer issue #46 names is confirmed still drifted from the file it is meant to
describe.

**Rationale**: `.copier-answers.yml`'s own header forbids hand-editing (*"Changes here will be
overwritten by `copier update` — NEVER EDIT MANUALLY"*) because Copier owns regenerating
`AGENTS.md` sections from these answers; a hand-edit that disagrees with what Copier would produce
from the same answers is the same class of drift in the opposite direction. Re-answering is the
only fix that stays correct through the *next* `copier update`, which a hand-edit would not.

**Alternatives considered**: hand-editing the YAML directly — rejected per the file's own header
and per the issue's explicit instruction ("re-answer, do not hand-edit"). If Copier is unavailable
in the environment that implements this fix, `spec.md`'s Assumptions section records the fallback:
a manually-authored update verified line-by-line against current `AGENTS.md`, treated as a
degraded substitute and named as such, not silently presented as the same thing.
