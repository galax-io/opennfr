# Implementation Plan: Identity Has One Scope

**Branch**: `011-identity-has-one-scope` | **Date**: 2026-08-31 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/011-identity-has-one-scope/spec.md`

## Summary

Milestone **v0.8.0**, three issues, one question under all of them: *what tells two statements in one document apart?*

The milestone stays inside what a renderer does — turning a requirement document into a target's assertions. Nothing here describes a report, a verdict, or anything a consumer builds after the run.

- **#58**: identity is scoped to the requirement by the schema and to the list by `README.md`, the gate and the corpus. [research.md](research.md) R2 found seven sites, and two documents that each state both readings. The list wins, the schema's sentence is the one that changes, and the rule ends up in one place with the others naming it. The same sentence also stops saying the key identifies the predicate *"in a report"* (**FR-006a**) — a report is downstream of the assertions a renderer produces, this format describes neither, and it is the last downstream claim the schema carries.
- **#72**: both uniqueness branches can be replaced with `if False:` and the gate still prints **PASS**. No document anywhere carries a colliding identity, and no predicate anywhere carries a `name`, so the `name` arm of the fallback has never been observed by anything. It gets what its two struck neighbours got in v0.6.0: probes that fire, in both directions, and a floor.
- **#82**: the reach tables claim to partition every axis; two of the nine predicate keys have no row. Gatling's `Assertion` is `(path, target, condition)` and has no field that holds a label, so the key does not travel into what the predicate renders to. A new axis says so, and says nothing about what Gatling does afterwards.

**The work is six files.** `README.md` (a rewritten `name` paragraph, a new `#### Identity` subsection, one sentence in § *How these tables are applied*), `schema/…/requirementset.schema.json` (one description), `GLOSSARY.md` (one entry), `scripts/verify.sh` (two call sites, two counted floors, one probe table, one rendering probe), a new `scripts/identity.py`, and one clause of `AGENTS.md` § *Structure*.

**`examples/` does not change**, and that is the point rather than a convenience: every published document is already valid under the reading this milestone settles on, and the corpus is not where coverage gets installed.

The plan's three load-bearing decisions:

- **The rule gets one home.** `README.md` § *A predicate* states the scope. The schema's `name` description and `GLOSSARY.md` § *criterionId* say what identity *is* and name where its uniqueness is decided, in the shape `$defs/unit`'s description already uses for the unit enumeration. Four corrected copies was the alternative and is the state #58 describes.
- **Nothing here describes what happens after an assertion.** A renderer turns a requirement into a target's assertions; reports, verdicts and what a consumer builds from a failure are outside the surface. This is why FR-006a strips *"in a report"* from the schema, why the Identity row's reason stops at `Assertion`'s three fields, and why `AssertionResult` and `AssertionMessage` were read (R1) and deliberately left out of `README.md`.
- **One implementation, in a module, because two processes need it.** The identity checks are in separate `python3` heredocs (R3). `scripts/mdlinks.py` is the same problem already solved in this file, with a `selftest()` and its own fixture floor, and its comment gives this milestone's motive verbatim. `scripts/identity.py` follows it.
- **The Identity row is dated at 3.13.5, which is what was read.** R1 could not open 3.15.1 here and a download was declined. `Assertion` was read with `javap` from the jar Gatling 3.13.5 pins, and is byte-identical to the one 3.11.5 pins. The row says so and does not borrow the header's version number.

## Technical Context

**Language/Version**: none for the format. The gate is POSIX `bash` driving `python3` heredocs; `scripts/mdlinks.py` and the new `scripts/identity.py` are plain Python 3 modules with no dependencies beyond the standard library. The gate's own dependencies are `jsonschema` and `pyyaml`, both already required.

**Primary Dependencies**: unchanged. Nothing is added to the gate's imports.

**Storage**: N/A.

**Testing**: `bash scripts/verify.sh` is the only gate, and this feature adds to two of its sections. There is no test runner and nothing to compile.

**Target Platform**: N/A — the artifacts are a JSON Schema, three markdown documents and a shell gate.

**Project Type**: format specification with a validating gate.

**Performance Goals**: N/A. The gate reads four YAML documents and one schema.

**Constraints**: `examples/` is byte-identical before and after. No compatibility-sensitive surface is touched: no borrowed OpenTelemetry name changes, and no field name appearing in a published example is added, removed or renamed. `git rm -r docs && bash scripts/verify.sh` stays green.

**Scale/Scope**: six files. One new module of roughly the size of `mdlinks.py`'s core, one new README subsection with two rows, one rewritten paragraph, two edited descriptions, six new probes, three new floors and one raised floor.

**External claim**: one, and it is the milestone's stated risk. Gatling's `Assertion` field list, read at 3.13.5 on 2026-08-31 — R1.

## Constitution Check

*GATE: evaluated before Phase 0 research and re-evaluated after Phase 1 design. Both passes recorded.*

See `.specify/memory/constitution.md` (v4.0.0).

- [x] **I. Vocabulary Before Features** — no term is introduced and none is renamed. `criterionId`, `name` and `displayName` all exist and keep their spellings. `GLOSSARY.md` § *criterionId* is edited because its **scope** changes, which Development Workflow requires in the same PR, and the edit adds a second *Rejected* line recording the requirement scope and why it was refused. The naming disagreement that is **not** settled here — whether `criterionId` should be `predicateId`, since it names the identity of a guard too — is in spec § *Out of Scope* with the reason: Principle I requires it be argued in an issue before files change, and no issue argues it.
- [x] **II. Borrow Names, Never Invent Them** — no metric or attribute name is touched. `not carried` is a table verdict in a target's description, not a name a document may contain, and it classifies a target's behaviour rather than a quantity. No alias, no derived or composite quantity.
- [x] **III. No Silent Green** — this principle is the whole of #72, and the feature is written from it. Every check added fails rather than skips: `scripts/identity.py` carries a `selftest()` called before either site trusts it, with a floor on its own fixtures (R3); both call sites count the lists they scanned and floor the count, so a deleted call site fails instead of scanning nothing (R5); the probe table carries an exact floor. The one claim `README.md:546` makes about the gate becomes true rather than merely stated.
- [x] **IV. Honest Status** — the one external claim carries its source, its artifact and its date, and names the version it was **actually** read at rather than the one the section header carries. The difference is stated on the page (R1), not left for a reader to reconcile. Nothing is described as checked that is not. FR-006a belongs to this principle too: a field description claiming the key identifies a predicate *"in a report"* describes machinery this repository does not have and does not build, which is a document reading as more settled than it is.
- [x] **V. Structure Over Grammar** — no field is added and no value set changes. `name` keeps its pattern and its optionality. The uniqueness rule remains what it has always been: something JSON Schema cannot express, checked by the gate and said so in both places.
- [x] **VI. The Requirement Is Target-Blind** — no requirement document names a target; `examples/` does not change at all. The new `#### Identity` subsection is part of `README.md` § *What any tool can actually run*, which is the **one** description Gatling has, and no second copy is created. The gate implements the section and carries no copy of its rows: FR-029's probe exercises `predicate_why`, the same function the corpus is judged by, and asserts only that the axis rejects nothing. Adding this axis changes no format, no schema and no published corpus.
- [x] **VII** — *withdrawn in 3.0.0. No gate.*
- [x] **VIII. Ideas Are Parked, Not Merged** — nothing under `docs/` is touched, no construct is proposed or parked, and no document outside `docs/` gains a link into it. `git rm -r docs && bash scripts/verify.sh` is unaffected.
- [x] **Compatibility** — no borrowed OpenTelemetry name is touched. No field name in a published example is added, removed or renamed: `name` is an existing optional predicate key whose *description* changes and whose published usage stays exactly as it is. No construct enters the format, so the "at least one surveyed target can assert it exactly" bar has nothing to clear. The published corpus does not narrow.

**Post-Phase-1 re-check**: unchanged, with three things later passes made explicit and none a violation.

1. `scripts/identity.py` is a new file under `scripts/`. `AGENTS.md` § *Structure* describes that directory as the gate "and what it shares (`mdlinks.py`)"; with a second shared module the parenthetical names half of what it names, so it gains one clause. That is a map correction to a non-normative sentence, not a rule change, and it is disclosed here because a new file in a five-file repository is not a detail.
2. The Identity row is dated 3.13.5 while § *Gatling*'s header is dated 3.15.1. Principle IV is satisfied by saying so on the page, and the row's source file — `AssertionModel.scala` — is one the header already lists, so the section gains a differently dated reading rather than a new source.
3. `/speckit-analyze` found FR-008 resting on a premise the module extraction removes: it required the gate's inline comment to survive, and after #72 that comment is both a second copy of `scripts/identity.py`'s docstring and a false sentence — *"uniqueness is checked here"*. The reason now travels with the implementation. Keeping the comment would have reproduced #58 inside the commit that closes #72, which is Principle I's cost argument pointed at a code comment.

## Project Structure

### Documentation (this feature)

```text
specs/011-identity-has-one-scope/
├── spec.md
├── plan.md                     # this file
├── research.md                 # Phase 0 — eight questions, two changed a requirement
├── data-model.md               # Phase 1 — identity, the list, the axis, the probe
├── quickstart.md               # Phase 1 — how to check the milestone landed
├── contracts/
│   ├── identity-scope.md       # the exact text of the one home and the two pointers  (#58)
│   ├── identity-module.md      # the shared module's surface and the probe table      (#72)
│   └── identity-reach.md       # the exact #### Identity subsection                   (#82)
└── checklists/
    └── requirements.md
```

### Repository (what this feature edits)

```text
README.md                                      # § A predicate — the one home; new #### Identity;
                                               #   one sentence in § How these tables are applied
GLOSSARY.md                                    # § criterionId — definition + a second Rejected line
schema/opennfr.io/v1/requirementset.schema.json # $defs/predicate.name — one description
scripts/verify.sh                              # two call sites, two counted floors, IDENTITY_PROBES
                                               #   and its floor, one PREDICATE_RENDERS entry, 14 -> 15
scripts/identity.py                            # NEW — predicate_id, collisions, duplicates, selftest, floor
AGENTS.md                                      # § Structure — one clause names the second shared module

# untouched, and checked to be untouched (quickstart step 1)
examples/                                      # byte-identical; every document keeps its verdict
docs/                                          # no idea added, moved or edited
.specify/memory/constitution.md                # stays at 4.0.0; no amendment is needed
specs/                                         # except this feature's own directory
```

**Structure Decision**: the repository has no source tree. The format is `schema/`, explained by `README.md`, its terms in `GLOSSARY.md`, its corpus in `examples/`, and its gate in `scripts/`. This feature edits four of those five and adds one module beside the gate; `examples/` is deliberately untouched.

## Implementation Order

Three commits, one per issue, in the milestone's own order, preceded by the spec commit. Each is green on its own.

1. **`docs(speckit): add 011-identity-has-one-scope spec/plan/tasks`** — this directory.
2. **`fix(format): identity is unique within one list (#58)`** — `README.md` § *A predicate*, `schema/…:130`, `GLOSSARY.md` § *criterionId*. No gate change: the gate already implements this reading. The contract is [contracts/identity-scope.md](contracts/identity-scope.md).
3. **`fix(gate): the identity rule is probed in both directions (#72)`** — `scripts/identity.py`, both call sites, the counted floors, `IDENTITY_PROBES` and its floor, `AGENTS.md` § *Structure*. The contract is [contracts/identity-module.md](contracts/identity-module.md).
4. **`docs(format): identity has no slot in a Gatling assertion (#82)`** — `README.md` § *Identity* and § *How these tables are applied*, one `PREDICATE_RENDERS` entry and its floor. The contract is [contracts/identity-reach.md](contracts/identity-reach.md).

#58 is first because #72's probes encode its answer and #82's row describes an identity that has to mean one thing. `AGENTS.md` rides with #72 because it is that commit that adds the file the sentence describes.

## Complexity Tracking

> Two costs are paid deliberately. Neither is a Constitution Check violation; both are recorded because a reviewer should meet them here rather than find them in a diff.

| Cost | Why needed | Simpler alternative rejected because |
|---|---|---|
| A new file, `scripts/identity.py` | The two identity checks are in separate `python3` heredocs, so one implementation reachable from both must be a module on disk (R3). Spec FR-019 forbids a second implementation for probes to call. | **Duplicating the function into both heredocs** is #58 reproduced one directory over — two copies of one rule, free to drift, which is the defect this milestone exists to remove. **Moving the schema's root-example check into the `SCHEMA` heredoc** needs no new file and was rejected too: it takes a check out of the section named for checking the schema's own examples, so both sections' summary lines stop describing what they ran. `scripts/mdlinks.py` is the same problem solved the same way, and its comment states this milestone's motive. |
| A third verdict in a target's description | **can** and **cannot** answer "is this assertable". The identity axis answers "what becomes of this key when the predicate is rendered", and the predicate is assertable either way. A **cannot** row would tell a renderer to reject a predicate carrying a `name`, which is wrong and would narrow the format to what a target happens to carry. | **A third bullet under § *Two things Gatling cannot do at all*** misfiles it: nothing there is about a key surviving, and both entries there change a verdict. **Narrowing the partition claim** to "axes that decide assertability" fixes the false sentence by promising less, and leaves the fact a renderer needs stated in passing rather than as a row with a reason — which is how `good`, `sum`, `neq` and `bad: {}` are handled and is the standard the section already sets. |
