# Implementation Plan: The Constitution Catches Up

**Branch**: `010-constitution-catches-up` | **Date**: 2026-08-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/010-constitution-catches-up/spec.md`

**This plan is for an amendment PR.** Under the constitution's own governance it must say so where a
reviewer meets it, and must show what breaks without it. Nothing breaks in the running sense —
nothing here runs. What breaks is that the repository keeps shipping two normative documents that
contradict each other, and keeps a MUST in the governing file whose stated reason is false.

## Summary

Milestone **v0.7.0**, two issues, one sentence under both: *a correction reached the document readers
meet and not the document that wins.*

- **#83**: v0.5.0 made `README.md` the sole home of the Gatling correspondence and wrote that rule
  into `AGENTS.md`. Principle VI says adding a target must not change any existing document. The
  reconciliation is in `specs/008-path-denotation/plan.md`, under a directory `AGENTS.md` reads as
  history. Two normative documents, contradicting, for two releases.
- **#75**: #64 removed apdex from `README.md`'s derived-quantities sentence because the stated reason
  is false of apdex. Principle II still carries all three names under that reason, and the deferral
  that recorded this — `specs/007-reach-table-rules` FR-015 — closed with its milestone.

**The work is four files.** `.specify/memory/constitution.md` (one bullet becomes three, one becomes
two, one rationale paragraph, one false sentence, one version), `AGENTS.md` (a parenthetical leaves),
`.specify/templates/plan-template.md` (two gate questions and a version pointer), `docs/ideas.md`
(one word joins an enumeration, and a clause makes the sentence survive it).

**Nothing the format owns moves.** The schema, `examples/`, `scripts/`, `GLOSSARY.md` and `README.md`
are untouched, and so is every file under `specs/` except this feature's own.

The plan's two load-bearing decisions:

- **The amendment replaces a structural containment with a counted one, and defines what is counted.**
  A target's description is what a renderer reads; there is exactly one per target; a gate
  implementing one is not a second one. This is narrower than the spec's first draft, which Phase 0
  found false of the repository at four sites.
- **Principle II moves apdex rather than dropping it.** A composite clause with a reason true of the
  class, and the argument stays in `docs/ideas.md` where the repository keeps arguments.

## Technical Context

**Language/Version**: none. This feature touches no schema, no code and no gate. Four markdown files
and one template.

**Primary Dependencies**: none added. `bash scripts/verify.sh` still needs `python3` with `pyyaml` and
`jsonschema`, unchanged.

**Storage**: N/A — files in a git repository.

**Testing**: `bash scripts/verify.sh` proves only that nothing broke; no section of it reads any file
this milestone edits except `docs/ideas.md`, and there only for the entry/condition count and the
isolation scan. The real validation is reading, and [quickstart.md](quickstart.md) is the procedure
for it — eight checks, each repeatable by a second person who does not know what the author intended.

**Target Platform**: N/A.

**Project Type**: a format specification. This particular feature is governance: the documents that
say what may be done to the format.

**Performance Goals**: N/A.

**Constraints**: the amendment must be **true of the repository as it stands**. A MUST that the
repository already violates is #83 recreated by the commit that fixes #83, and Phase 0 caught exactly
that in the spec's first FR-005 ([research.md](research.md) R1). Every clause the amendment adds was
checked against every site that could violate it before it was written.

**Scale/Scope**: 4 files changed outside `specs/`, 0 added, 0 examples edited, 0 schema rules touched,
0 terms added. Two issues, one pull request, three commits — the spec, then #83, then #75.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against **v3.0.0**, the version in force. This feature is the amendment that produces
v4.0.0; it is checked against the rules it is changing, which is the only order that can catch an
amendment doing more than it says.

- [x] **I. Vocabulary Before Features** — no term is added or renamed, so `GLOSSARY.md` does not
      change. The one word that looks like a candidate is *composite*: it classifies a quantity the
      format does not carry — not a field, a value, or a name a document may hold — and Principle I's
      trigger is a term reaching an example, a schema or an implementation, none of which the
      constitution is. `docs/ideas.md:86` already uses it of apdex, in the sentence this milestone
      corrects. Recorded as FR-026 rather than left for a reviewer to wonder about. Both changes were
      argued in issues before files moved: #83 and #75.
- [x] **II. Borrow Names, Never Invent Them** — **engaged: this feature amends it.** No metric or
      attribute name is added, renamed or aliased, and no name becomes permissible that was not.
      apdex moves between two clauses of the same principle; what changes is the reason given, from
      one that is false of it to one that is true. The bar for minting a name stays in `GLOSSARY.md`
      § *metric* where v0.6.0 put it, and FR-020 forbids the new clause being written as though it
      had replaced it.
- [x] **III. No Silent Green** — this feature adds no check, deletes no check, and deletes no check's
      input. It adds a **rule** that no gate enforces, which is the risk this principle governs from
      the other side: FR-005 requires the amended bullet to say so in its own text, so the principle
      cannot read as though something were watching. *Recorded, not fixed*: the constitution is itself
      an artifact nothing validates and does not say so, which is this principle's third clause
      unmet — by the repository, before this milestone and after it. It is why both defects survived
      two releases. It is not one of this milestone's two issues, so it is owed an issue rather than
      folded in; see *Out of Scope* in the spec and the row below.
- [x] **IV. Honest Status** — **opened as failing, closed by Phase 0.** The spec's first FR-005 stated
      a MUST that four sites in this repository violate, two of them deliberately, including one
      v0.6.0 explicitly required. [research.md](research.md) R1 enumerated every target mention
      outside the reach section and the requirement was rewritten. R1 also found that `README.md:478`
      violates the **unamended** Principle VI, and says so rather than quietly relying on the new
      definition to absorb it. No claim about an external tool is added anywhere in this milestone, so
      nothing here needs a source date beyond the commit everything was read at, `1e394f1`.
- [x] **V. Structure Over Grammar** — no field, no value set, no schema change, no string parsed.
- [x] **VI. The Requirement Is Target-Blind** — **satisfied, and this is the point.** No requirement
      document names a target; `examples/` is untouched. No target is added, so the clause being
      amended is not engaged by the change itself. This is the gate `specs/008-path-denotation/plan.md`
      could not tick — it left VI as its only unchecked box and declared a departure — and this
      feature can tick it because it takes the route the constitution offers instead of the one 008
      had to improvise. The departure ends here rather than being renewed.
- [x] **VII** — *withdrawn in 3.0.0. No gate.*
- [x] **VIII. Ideas Are Parked, Not Merged** — `docs/ideas.md` is edited, and the isolation gate is
      checked rather than assumed. The edit is inside the existing `**apdex**` entry at `:75`, adds
      no line-initial bold and no second `*Would need*`, so the entry and condition counts stay equal
      at 16 (FR-024). Nothing outside `docs/` gains a link into it: the constitution names the path in
      a code span, which Principle VIII permits in terms, and `specs/` is the gate's only exemption
      anyway. `git rm -r docs && bash scripts/verify.sh` stays green.
- [x] **Compatibility** — no borrowed OpenTelemetry name is touched, and no field name appearing in a
      published example. No construct is added, so the surveyed-target floor is not engaged. The list
      of compatibility-sensitive surfaces is unchanged at two items (FR-010); restoring the third,
      *what a target's description may declare*, was considered and is recorded as the rejected
      alternative rather than left undiscussed.

**Post-Phase-1 re-check**: unchanged. Phase 1 produced two contracts, a data model and a quickstart,
and added no obligation the gates above did not already cover. The one gate that moved during the
feature is IV, and it moved from failing to passing in Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/010-constitution-catches-up/
├── spec.md               # what and why, with the two answered decisions
├── plan.md               # this file
├── research.md           # Phase 0 — seven questions; R1 rewrote a requirement
├── data-model.md         # Phase 1 — the seven statements, their homes and their copy counts
├── quickstart.md         # Phase 1 — eight checks, all of them reading
├── contracts/
│   ├── principle-vi.md   # the delta for #83: five edits across three files
│   └── principle-ii.md   # the delta for #75: two edits across two files
├── checklists/
│   └── requirements.md   # spec quality, 16/16
└── tasks.md              # Phase 2 — /speckit-tasks, not created here
```

### Repository (what this feature edits)

```text
.specify/memory/constitution.md      # Principle II :83, Principle VI :143, Compatibility :225, version
.specify/templates/plan-template.md  # :44 version pointer, :49 II gate, :61 VI gate
AGENTS.md                            # :35 — the parenthetical leaves
docs/ideas.md                        # :81 — sum joins the enumeration

# untouched, and checked to be untouched (quickstart step 1)
schema/  examples/  scripts/  GLOSSARY.md  README.md  specs/008-path-denotation/
```

**Structure Decision**: none to make. There is no source tree; the artifacts this feature changes are
the four files above, and the contracts name every line.

## Complexity Tracking

> No Constitution Check gate fails. The rows below are the two costs this amendment takes on
> knowingly, recorded here because the alternative to recording them is #83 again.

| Trade | Why accepted | Alternative rejected because |
|---|---|---|
| **Structural containment becomes counted containment, and nothing enforces the count.** Before v0.5.0 a target description could not leak into the format's description, because it was a different file. After the amendment the guarantee is "exactly one description per target", checked by a reviewer | The separateness was the mechanism; **singularity** was the property, and it is the one #68's drift actually broke — two copies of the tables disagreeing, with four issues live again in one of them. The amendment requires the property directly instead of the mechanism that used to imply it | Restoring a separate `targets/gatling.md` would honour the old wording and reverse a decision argued in #68 and shipped in v0.5.0, which #83 says outright it is not asking for. Writing a gate for it would need a script that decides *"is this sentence a target description"*, which nothing can; a gate that cannot decide its question is the silent green Principle III forbids. So the rule says it is unenforced, which is Principle IV rather than a workaround |
| **This milestone edits an artifact nothing validates, and does not fix that.** Principle III's third clause — *any artifact nothing validates MUST say so in its own text* — is unmet by `.specify/memory/constitution.md` itself, and that is why both defects here survived two releases | It is not one of the milestone's two issues, and `AGENTS.md` is explicit that work outside them does not ride along. It also needs its own argument: what a check on this file could decide is a real question, and answering it inside an amendment PR would be the smuggling the governance clause exists to stop | Adding one sentence now would be cheap and would close the clause, and was rejected because the honest version of the fix is not a sentence — it is deciding whether a gate is possible. FR-005 does the narrow version where it belongs: the one rule this milestone adds says in its own text that nothing checks it |
