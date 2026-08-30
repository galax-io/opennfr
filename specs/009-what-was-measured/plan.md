# Implementation Plan: What Was Actually Measured

**Branch**: `009-what-was-measured` | **Date**: 2026-08-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/009-what-was-measured/spec.md`

**Revised 2026-08-30** after adversarial review. Two decisions reversed, three corrected; the
schema's validation behaviour is no longer changed at all. The spec's § *What the review changed*
carries the findings and how each was verified.

## Summary

Milestone **v0.6.0**, five issues, and one sentence under all of them: *a predicate says what was
measured, and the artifacts disagree about what it is allowed to say.*

The work, after review, is smaller than the first draft proposed: **four deleted lines in the gate**,
a probe list for three reach axes that have never had one, two schema *descriptions* that gain rules
the repository has already agreed, four reach rows that stop deferring or start giving a reason, and
three *Rejected* lines in `GLOSSARY.md`.

**What the schema validates does not change.** No term is added. The corpus does not move: four
documents in, four documents out, unedited.

The plan's two load-bearing decisions:

- **Where the honest name for a measured quantity does not exist, the answer is a `cannot` whose row
  says so, not a minted name.** Applied to #62 and #52; its durable home is `GLOSSARY.md` § *metric*.
- **Where a shape is unrenderable but meaningful, the schema keeps it and the tables refuse it.**
  Applied to #57. This reverses the first draft, which would have made `{metric, count}` invalid, and
  it reverses it on a binding constraint: the format is not narrowed to match the corpus.

## Technical Context

**Language/Version**: none. One JSON Schema (Draft 2020-12), markdown, and one POSIX shell gate that
shells out to `python3`.

**Primary Dependencies**: `python3` with `pyyaml` and `jsonschema` — the gate's only requirements,
unchanged by this feature.

**Storage**: N/A — files in a git repository.

**Testing**: `bash scripts/verify.sh`. Eight sections; one is meaningfully touched (Gatling reach),
and the schema self-check is untouched because the schema's rules do not change.

**Target Platform**: any machine that can run `bash` and `python3`. The gate avoids GNU extensions
after one such extension silently disabled a whole section on macOS.

**Project Type**: a format specification — a schema, a validated corpus, and the documents that
describe them.

**Performance Goals**: N/A.

**Constraints**: the published corpus may be narrower than the format, and **the format must not be
narrowed to match it** — the constraint that decided #57. Any new rejection in the gate must add a
probe and raise the floor beside it in the same commit.

**Scale/Scope**: 5 files changed, 0 files added outside `specs/`, 0 examples edited, 0 schema rules
added. Five issues, five commits, each green on its own.

## Constitution Check

*GATE: passed before Phase 0 research; re-checked after Phase 1 design and again after adversarial
review, below.*

- [x] **I. Vocabulary Before Features** — no term is introduced and none is renamed. `GLOSSARY.md`
      gains three *Rejected* lines and no entry: § *aggregation* records the schema-rule outcome #57
      turned down, § *selector* records the literal-element reading #77 turned down, § *metric*
      records the name #62 declined to mint. Every naming question was argued in its issue before a
      file changed.
- [x] **II. Borrow Names, Never Invent Them** — nothing is minted. Where semantic conventions already
      name an operation, the published text says the general rule applies rather than claiming a gap
      that does not exist. No alias, no second spelling, no derived quantity becoming a metric.
- [x] **III. No Silent Green** — this is the principle #57 is filed under, and the fix now attacks the
      actual silence: the gate rendered a shape the tables reject and dropped a field without a
      message. It stops. And the milestone adds the probe list for the four axes that have never had
      one, which is the mechanism that let the defect live five releases. No check is deleted; no
      check is left able to scan nothing.
- [x] **IV. Honest Status** — **no new claim about an external tool is made.** #52's row reuses the
      claim already published and dated 2026-08-25; #62's row is argued entirely from the format's
      side; the protocol half of #62 is stated as an evidence gap rather than as a naming gap,
      because claiming no name exists over conventions that do would be false. Both decisions state
      what would reopen them.
- [x] **V. Structure Over Grammar** — the schema gains no rule, so nothing is added to decode. The
      two description edits state meanings the schema already enforces or already leaves open.
- [x] **VI. The Requirement Is Target-Blind** — no document names a target, and one target fact is
      *removed* from a field description (FR-013) and left where it belongs, in the reach row. The
      format is not narrowed to Gatling in either direction: `{metric, count}` stays valid,
      `{loadtest.group.name: ["*"], …}` stays valid, and a semantic-convention name for another
      protocol stays valid. The reach tables stay in `README.md` alone.
- [x] **VII** — *withdrawn in 3.0.0. No gate.*
- [x] **VIII. Ideas Are Parked, Not Merged** — no entry is added to `docs/ideas.md`; the existing
      `loadtest.*` registry entry gains one clause, and its *Would need* already covers it. That
      keeps the isolation gate's entry/`*Would need*` counts equal, which is what it checks. Nothing
      outside `docs/` links into it, and `git rm -r docs && bash scripts/verify.sh` stays green.
- [x] **Compatibility** — no borrowed OpenTelemetry name is touched, and no field name changes.
      **The published corpus does not narrow and the format does not narrow**, which is the
      constraint that reversed the first draft's schema rule. No construct is added, so the "at least
      one surveyed target can assert it exactly" floor has nothing to clear.

## Project Structure

### Documentation (this feature)

```text
specs/009-what-was-measured/
├── spec.md              # /speckit-specify output, revised after review
├── plan.md              # this file
├── research.md          # Phase 0, revised after review
├── data-model.md        # Phase 1, revised after review
├── quickstart.md        # Phase 1, revised after review
├── contracts/
│   ├── predicate-axes.md     # the delta to the reach tables' predicate axes and the gate (#57)
│   └── reach-cannot.md       # the delta to two cannot rows (#62, #52)
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks output — not created here
```

### Files this feature changes (repository root)

| File | What changes | Issue |
|---|---|---|
| `schema/…/requirementset.schema.json` | `$defs/selector.description` — `"*"` is not a name; the closing sentence about value types | #78 |
| | `$defs/selector.description` — a `"*"` element is presence | #77 |
| | **no rule, no `allOf` branch, no change to what validates** | — |
| `README.md` | § `selector` — the `loadtest.group.name` cell states one reading and loses a target fact | #77 |
| | § *Names* § *Metrics* — the boundary, in two halves stated differently | #62 |
| | § *What any tool can actually run* — Metrics `any other` row gains its reason; Selection group-only row is decided; *Over a metric* gains `count` and `rate` **cannot** rows | #62, #52, #57 |
| `GLOSSARY.md` | § *selector* — the element exception and its *Rejected* line | #77 |
| | § *metric* — the declined name as a *Rejected* line | #62 |
| | § *aggregation* — the schema-rule outcome as a *Rejected* line | #57 |
| `scripts/verify.sh` | the `SELECTIONS` comment loses its `(#52)` pointer | #52 |
| | `TABLE["metric"]` loses `count` and `rate`; a predicate probe list and its floor arrive | #57 |
| `docs/ideas.md` | the `loadtest.*` registry entry gains one clause | #62 |
| `examples/` | **nothing** | — |

**Structure Decision**: the repository has no source tree; the artifacts above are the product.
`README.md` stays the only place a field or a reach rule is described, the schema stays the artifact
that decides, and `GLOSSARY.md` stays where a term records what it displaced. This feature adds no
fourth home and no second copy of anything — and removes one duplication it found (FR-013).

## The commit sequence

Five issues, five commits. Each is green on `bash scripts/verify.sh` on its own and closes exactly
one issue.

| # | Commit | Why here |
|---|---|---|
| 0 | `docs(speckit): add 009-what-was-measured spec/plan/tasks` | spec-first, never folded into an implementation commit |
| 1 | `fix(schema): the schema says "*" is not a name (#78)` | the premise. Commit 2 is this rule read consistently, and stating the consequence first is how the two readings came apart |
| 2 | `fix(schema): a "*" in a hierarchy element is presence (#77)` | the consequence, in the three artifacts that state it |
| 3 | `fix(contract): the metric axis says what it does not name (#62)` | a decision written down; changes no schema and no document |
| 4 | `fix(contract): a group-only selection is a decided cannot (#52)` | the same, and the row whose reason was also under-inclusive |
| 5 | `fix(contract): the gate stops rendering what the tables reject (#57)` | **last, deliberately** |

**Why #57 is last.** It carries the milestone's only contestable argument — that the shape stays
valid in the format and is refused only by the tables and the gate. The other four are
documentation-only and uncontested. Landing #57 last means a reviewer who disagrees reverts one
commit and loses nothing else.

Commits 1 and 2 both edit `$defs/selector.description`, and commits 3, 4 and 5 all edit
`README.md` § *What any tool can actually run*. Each group is adjacent so no unrelated commit sits
between two edits to the same paragraph.

The order differs from the milestone description's narrative order (#62 first). The dependency it
states is preserved — #52 follows #62 — and the rest is ordered so the contestable commit is
revertable. This is recorded rather than silently applied.

## Constitution Re-Check (post-review)

The adversarial round changed the answer to two gates, which is the point of running one:

- **Compatibility, and Principle VI, reversed the schema rule.** The pre-check passed FR-001 by
  reasoning that narrowing for a format-internal reason is not narrowing to a target. The review
  showed the reason was not format-internal: `README.md` states at format level that `count` over a
  metric means something, the first draft deleted that claim to fit the Gatling table, and
  `{metric, sum}` and `op: neq` are valid today while both are `cannot` rows. The constraint is
  binding and the plan now obeys it.
- **Principle I and the standing instruction dropped the `cannot` taxonomy.** The first draft
  defined two kinds of `cannot` and marked rows with one of them. Its own contract file then
  misfiled `good` as a target limitation, while the published row says `successfulRequests` exists
  and no OpenNFR fraction corresponds to it. A taxonomy that misclassifies a row in the document
  defining it is a new entity that buys nothing; every row carries its reason inline instead.
- **Principle III gained the finding the first draft missed.** Four of five reach axes have no probe
  at all. That is a larger instance of "a rule nothing probes is a rule nothing checks" than the
  defect #57 reports, and it is now in scope as the thing that makes #57's fix checkable.
- **Principle IV cut two sentences.** One asserted that Gatling's `responseTime` is the same
  statistic whatever recorded the entry — an undated external claim, and unnecessary. One would have
  said no published name is true of a non-HTTP operation's duration — false, since conventions name
  those operations and such a document validates today.

No gate fails. Complexity Tracking is empty.

## Complexity Tracking

No constitution violation is claimed and none is justified. The section is retained empty
deliberately: an empty table is a statement, and a deleted section reads as a section nobody filled.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
