# Implementation Plan: Fix Milestone v0.3.0 Bugs

**Branch**: `005-fix-milestone-bugs` | **Date**: 2026-08-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-fix-milestone-bugs/spec.md`

## Summary

Five independent defects plus one enhancement (#31, added later), confirmed against the current
repository rather than assumed from their
source issues (three of the five had drifted since filing — see research.md): a gate self-check
that passes for the wrong reason (#37); a JSON Schema composition that turns one predicate mistake
into two error messages, one of them wrong (#42); an unreachable conditional in `$defs/requirement`
plus a matching no-op (#38); a link checker that reads a regex in a code span as a broken markdown
link (#43); and a Copier scaffolding record that has drifted from the `AGENTS.md` it regenerates
(#46). None adds a construct, renames a field, or changes which documents in `examples/` validate
— confirmed by dry-run for the two fixes that touch the schema. Issue #31 (add schema examples) was
held out of scope as an enhancement and then picked up on 2026-08-24, once its premise proved
stale too; it is User Story 6, the one `feat` here (spec.md, Clarifications).

The approach is one fix per issue, one commit per fix, per `AGENTS.md`'s "1 issue = 1 commit" — not
one combined change. Two of the five (#42, #38) touch the same schema keys and must be sequenced
(data-model.md, "Ordering constraint").

## Technical Context

**Language/Version**: None. Bash and Python 3 (the gate's own implementation language), one JSON
Schema (Draft 2020-12), Markdown, YAML.

**Primary Dependencies**: `python3` with `pyyaml` and `jsonschema`, used only by the gate —
unchanged by this feature.

**Storage**: N/A — files in git.

**Testing**: `bash scripts/verify.sh`, plus the per-fix probes in [quickstart.md](quickstart.md),
each of which was already run once during planning (research.md) to confirm the fix works before
committing to it in this plan.

**Target Platform**: A git repository read by humans and, eventually, by tool adapters living
elsewhere — unaffected by this feature.

**Project Type**: Format specification and its validation gate. No application code.

**Performance Goals**: N/A.

**Constraints**: `bash scripts/verify.sh` MUST pass on every commit (`AGENTS.md`; constitution,
Development Workflow) — including each of the five individually, not only the end state. No fix
may change which document in `examples/` validates (FR-012); confirmed by dry-run for #42 and #38,
the two that touch the schema. #37, #43 and #46 do not touch the schema at all.

**Scale/Scope**: 5 fixes, 4 files (`scripts/verify.sh`, two sections;
`schema/opennfr.io/v1/requirementset.schema.json`, two `$defs`; `README.md`, one field row;
`.copier-answers.yml`, eight of its sixteen answers). Plus one new file, `scripts/mdlinks.py`, and
one line of `AGENTS.md`.

## Constitution Check

*Evaluated against `.specify/memory/constitution.md` v3.0.0. Re-checked after Phase 1 design below
— unchanged, since Phase 1 added no new artifact this gate reasons about.*

- [x] **I. Vocabulary Before Features** — no term is introduced or renamed. `guards`, `criteria`,
      `predicate`, `requirement`, `indicator` all already exist in `GLOSSARY.md`; none is
      redefined, only the schema construct enforcing an existing rule (R2, R3) or a diagnostic
      (R1) changes shape. All five fixes were argued in their respective GitHub issues before this
      plan; #38's fix text cites the same glossary rule it is deleting a dead duplicate of.
- [x] **II. Borrow Names, Never Invent Them** — no metric or attribute name is added, renamed or
      aliased. R2/R3 touch schema *structure* (`allOf`/`unevaluatedProperties` vs. plain `$ref`,
      `additionalProperties` placement), never a name.
- [x] **III. No Silent Green** — the principle this feature is mostly *about*. R1 fixes a gate
      section that has been silently green since the probes were written (#37) — the sharpest
      instance of this principle's own failure mode, inside the file that exists to catch it. R4
      fixes a check that fails loudly but for the wrong reason (a false positive is the mirror
      image: not silence, but noise that teaches a workaround instead of a fix). Neither fix
      introduces a new skip-on-can't-run path; both make an existing check fail for the right
      reason instead of the wrong one.
- [x] **IV. Honest Status** — research.md states plainly which of the five issues' premises no
      longer matched the current repository (#43's workaround text, #42's example filenames) and
      corrects the spec rather than silently implementing against a stale description. Every
      schema-touching decision (R2, R3) is backed by a dry-run against the current corpus, dated
      2026-08-23, not by trusting the issue's own (two-year-old) test claims.
- [x] **V. Structure Over Grammar** — no new field, no bespoke parser, no open grammar. R2's fix
      is a closed-form JSON Schema restructuring (`additionalProperties` moved to the object that
      owns the properties); nothing here could not already be expressed in Draft 2020-12.
- [x] **VI. The Requirement Is Target-Blind** — no requirement document gains a target name, in a
      field, a value or an example. Gatling is not mentioned by any of the five fixes.
- [ ] **VII** — *withdrawn in 3.0.0. No gate.*
- [x] **VIII. Ideas Are Parked, Not Merged** — untouched. None of the five fixes reads or writes
      `docs/`.
- [x] **Compatibility** — `$defs/requirement` and `$defs/predicate` are compatibility-sensitive
      surfaces (they define field names appearing in published examples), and R2/R3 change their
      *internal* schema construction, but rename no field, and were each argued in their own
      GitHub issue before this plan (#42, #38) — satisfying "argued in an issue before files
      change" per Principle I, which the Compatibility Constraints section points back to. No
      construct is added, so the "at least one surveyed target can assert it" admission floor
      does not apply — nothing here is new to the format.

**Gate result: passes, no violations.** Complexity Tracking below is empty.

## Project Structure

### Documentation (this feature)

```text
specs/005-fix-milestone-bugs/
├── spec.md                        the requirement
├── plan.md                        this file
├── research.md                    Phase 0 — five decisions, each dry-run tested
├── data-model.md                  Phase 1 — every artifact touched, before/after
├── quickstart.md                  Phase 1 — how to check each fix, command by command
├── contracts/
│   └── verify-sections.md         which gate sections change, which stay as they are
└── checklists/requirements.md
```

### Repository (files this feature touches)

```text
scripts/verify.sh                                  two sections change (R1, R4)
schema/opennfr.io/v1/requirementset.schema.json     $defs/predicate, $defs/requirement (R2, R3)
README.md                                           one field row (R4)
.copier-answers.yml                                 eight of sixteen answers (R5)
scripts/mdlinks.py                                  new — one definition of a link (R4)
AGENTS.md                                           one line of the Commands block (R4)
```

One file is added — `scripts/mdlinks.py`, which both link scanners import. Nothing is deleted, and no directory changes shape.

**Structure Decision**: Not applicable in the usual sense — this feature has no source tree to
lay out. It is five independent fixes landing as five commits per `AGENTS.md`, plus one new module
(`scripts/mdlinks.py`) extracted when review showed the gate's two link scanners had been
disagreeing about what a link is. `data-model.md`'s "Ordering constraint" governs the only
sequencing dependency (#42 before #38, both touching the same schema keys).

## Complexity Tracking

*Empty — the Constitution Check above records no violation to justify.*
