# Implementation Plan: The Rules By Which The Reach Tables Are Read

**Branch**: `007-reach-table-rules` | **Date**: 2026-08-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-reach-table-rules/spec.md`

## Summary

Milestone v0.4.0 — four issues found by the first OpenNFR renderer, all of them places where the
published text does not decide something the gate already decides, or decides it wrongly. The
contract claims its tables partition each axis; on the selection axis they partition by *key set*
while what a renderer emits depends on the *value*. This feature makes the value part of the row
(#60), gives the one value the format hands authors — `"*"` — the meaning authors reach for and a
scope to render into (#55, #56), and repairs three sentences that are not true as written (#64).

Phase 0 changed the shape of the work. Mapping `{loadtest.request.name: "*"}` to `forAll()` is not
only a new row: under the term as defined today a selector picks one set and every predicate
reduces it to one number, so `"*"` carries no quantifier and its pooled reading collapses to
`global`. The per-request reading has to be **given** to `"*"` at the format level — which makes
this a change to a defined term, engaging Principle I, and requires `GLOSSARY.md` and `README.md`
to change alongside the contract. See research.md R1.

## Technical Context

**Language/Version**: None — this repository ships no code. One JSON Schema (draft 2020-12),
markdown, and a POSIX shell gate that embeds Python 3 for the checks a shell cannot do.

**Primary Dependencies**: `python3` with `pyyaml` and `jsonschema`, used by `scripts/verify.sh`
only. No dependency is added by this feature.

**Storage**: N/A

**Testing**: `bash scripts/verify.sh` is the whole test model. This feature adds a probe table to
its § *Examples are assertable by Gatling*, mirroring the one § *The schema holds up its own
examples, and still rejects* already has.

**Target Platform**: N/A — documents.

**Project Type**: Format specification plus its validation gate.

**Performance Goals**: N/A

**Constraints**: what validates must not change (`schema/opennfr.io/v1/requirementset.schema.json`
keeps every constraint it has, byte for byte; only its `$defs/selector` description moves);
`.specify/memory/constitution.md` does not change; the reach gate keeps reading `examples/` and
never the schema.

**Scale/Scope**: one contract document, two sections of `README.md`, one `GLOSSARY.md` entry, one
`docs/ideas.md` entry, one gate section, and the corpus from three documents to four. Three
commits, three PRs.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Vocabulary Before Features** — **engaged, and this is the feature's main cost.** No term
      is added, but one is redefined: `"*"` gains, on a selection attribute, the meaning *each
      matching series separately* (research.md R1). `GLOSSARY.md` § *selector* is updated in the
      same change, records the rejected alternative (mapping to `global`, which makes the value
      redundant with `{}`) and what the old definition got wrong (it defined presence and left the
      quantifier unstated, so the value's only honest reading was one already spoken for). The
      argument predates the files: #55 and #56 both make it.
- [x] **II. Borrow Names, Never Invent Them** — no metric or attribute name is added, renamed or
      aliased. The feature *improves* compliance with this principle's last bullet: apdex stops
      being listed among quantities computed by an aggregation that exists, because none does
      (research.md R4). The identical sentence in this principle's own text is knowingly left —
      spec FR-015.
- [x] **III. No Silent Green** — every check added can fail. The probe table (FR-008) exists so
      that each new **cannot** rule is demonstrated rather than trusted, and it carries a floor
      (FR-009) so an emptied table fails the section instead of reporting success over nothing.
      Nothing skips. The one place this principle could have been misapplied — obliging documents
      to carry a guard because `forAll()` exits green on an empty run — was rejected on
      2026-08-24: that is a fact about a target, and this repository records facts about targets
      rather than legislating around them.
- [x] **IV. Honest Status** — the claim the feature turns on, that `forAll` takes no path, is
      sourced to `AssertionSupport.scala @ v3.15.1` and dated, with a second read on 2026-08-24
      and its one inaccuracy recorded rather than smoothed over (research.md R2). The contract's
      **Checked** header moves to the date of that read.
- [x] **V. Structure Over Grammar** — no new field, no string DSL, no bespoke decoding. `"*"` is a
      single sentinel value, not an open grammar: there is exactly one such value, it is compared
      for equality, and nothing is parsed out of it.
- [x] **VI. The Requirement Is Target-Blind** — the quantifier meaning is stated at the format
      level, in the format's own words, without naming a target; the reach contract maps it onto
      `forAll()` the way every other row maps a construct. No requirement document names a target.
      Adding a second target would add a second description and change nothing here. What
      validates does not change, so the format stays as wide as it is.
- [ ] **VII** — *withdrawn in 3.0.0. No gate.*
- [x] **VIII. Ideas Are Parked, Not Merged** — `docs/ideas.md` gains one entry (apdex) with its
      `*Would need*` clause, keeping the gate's ideas-to-conditions count equal. Nothing outside
      `docs/` links into it: `README.md` and the contract name `docs/ideas.md` in prose inside a
      code span, never as link syntax. `git rm -r docs && bash scripts/verify.sh` still passes,
      because nothing this feature adds outside `docs/` depends on anything inside it.
- [x] **Compatibility** — no borrowed OTel name changes. Two field names in published examples
      are touched in meaning, not spelling: `loadtest.group.name` and `loadtest.request.name` gain
      a stated value constraint. Both changes are argued in issues (#60, #55, #56) and
      `GLOSSARY.md` records what was rejected. Every construct kept has at least one surveyed
      target that asserts it exactly — `forAll()` for the quantifier, `details(parts)` for the
      literal path. The corpus narrows nowhere; the format does not narrow at all, and the rows
      that say **cannot** say why.

**Result**: pass, with Principle I engaged rather than clear. Nothing to justify in Complexity
Tracking — the work Principle I requires is scoped into commit 3 (research.md R7) rather than
waived.

**Re-checked after Phase 1.** The design artifacts changed no answer above. They did make one
answer's cost concrete: Principle I's obligation is three documents changing together —
`GLOSSARY.md`, `README.md`, and the schema's `$defs/selector` description (research.md R8) — not
one. Phase 1 added no construct, no field and no term beyond the redefinition already declared,
and `contracts/reach-selection.md` is a design record rather than a second home for the rule.

## Project Structure

### Documentation (this feature)

```text
specs/007-reach-table-rules/
├── plan.md              # This file
├── research.md          # Phase 0 output — R1..R7 and one open question
├── data-model.md        # Phase 1 output — what a Selection row is, before and after
├── quickstart.md        # Phase 1 output — how each success criterion is checked
├── contracts/
│   └── reach-selection.md   # Phase 1 output — the rows to be written, verbatim
├── checklists/
│   └── requirements.md  # written by /speckit-specify, 16/16
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Repository (what this feature touches)

```text
specs/004-strip-to-schema/contracts/
└── gatling-reach.md     # the source. Selection table, Aggregations percentile row,
                         #  two Principle III citations, the closing absent-data note

scripts/
└── verify.sh            # the check. § "Examples are assertable by Gatling" gains value
                         #  awareness and a probe table with a floor

README.md                # the selector table (the quantifier meaning); the Names section
                         #  (apdex leaves the derived-quantities sentence)
GLOSSARY.md              # § selector — the redefinition Principle I requires
docs/ideas.md            # apdex gains an entry with its condition

examples/
└── every-request-is-fast.yaml   # new: the blanket requirement, exercising forAll()

schema/opennfr.io/v1/requirementset.schema.json
                         # $defs/selector description only — research.md R8. Every
                         #  constraint unchanged
.specify/memory/constitution.md
                         # not touched — spec FR-015
```

**Structure Decision**: no new directory and no new kind of artifact. The reach contract stays
where it is, in `specs/004-strip-to-schema/contracts/`, because it is the published source and
`scripts/verify.sh:516` points at it; this feature edits it in place rather than copying it
forward. `specs/007-reach-table-rules/contracts/reach-selection.md` holds only the *delta* — the four rows
added, the two amended, and the note that moves — so that reviewing it is arguing a change rather
than diffing two copies of one table. It is not a second home for the rule.

## Complexity Tracking

> No Constitution Check gate failed. Nothing to justify.
