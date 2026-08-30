# Contract: the delta to Principle VI, and to the three files that follow it

**Feature**: `010-constitution-catches-up` | **Issue**: [#83](https://github.com/galax-io/opennfr/issues/83)

The reach tables live in `README.md` § *What any tool can actually run* and **do not change**. The
schema, the corpus and the gate do not change. This file holds only the delta: one bullet in the
constitution becomes three, one rationale paragraph is added, one sentence in *Compatibility
Constraints* stops being false, one parenthetical leaves `AGENTS.md`, and one gate question plus one
version pointer in the plan template follow.

## What does not change, and why that is the decision

**The one-home decision.** #68 argued it, v0.5.0 shipped it, and #83 says outright it is not
reopening it. `AGENTS.md`'s rule — *a second target is a second section there, not a second file* —
survives this milestone word for word. What ends is its status as a declared departure.

**The reach tables.** Not a row, not a reason, not a date. This milestone changes the rule that says
the tables may live where they live.

**`scripts/verify.sh`.** Its one citation of Principle VI (`:540`) claims that extending the reach
gate to read the schema would be the format narrowing to one tool. The amended bullet keeps *"MUST
NOT change the format, the schema"* verbatim, so the citation stays true and the file stays shut.

**`specs/`.** `specs/008-path-denotation/plan.md` keeps its unchecked Principle VI box and its
Complexity Tracking row. That row is the evidence the departure was disclosed; rewriting it to match
the new rule would erase the only record that the old one was ever departed from.

## Delta 1 — Principle VI, bullet 2 becomes three bullets

`.specify/memory/constitution.md:143-146`. **Before:**

```text
- A requirement document MUST NOT name a target: not in a field, a value, a metric name, or an
  example. It carries no per-target section, override or conditional.
- The correspondence between the document's vocabulary and a target's own MUST live in that
  target's description. Adding a target MUST NOT change the format, the schema, or any
  existing document.
```

**After:**

```text
- A requirement document MUST NOT name a target: not in a field, a value, a metric name, or an
  example. It carries no per-target section, override or conditional.
- A target's DESCRIPTION is what a renderer reads to turn a requirement document into that
  target's assertions. The correspondence between the document's vocabulary and a target's own
  MUST live there, and there MUST be exactly one description per target: a second copy is what
  drift is made of. A description MAY be a section of an existing document. A gate implementing
  a description is not a second description — it MAY name the reason a row gives, and MUST NOT
  carry a second copy of the rows.
- Adding a target MUST NOT change the format, the schema, or the published corpus, and MUST NOT
  change any existing document other than the one holding the target descriptions.
```

**What each clause is for**

| Clause | Satisfies | Why it is in the text |
|---|---|---|
| the definition of a description | FR-005 | the rule has to say what it constrains, or it reads as a prohibition on naming a target anywhere — false at four sites ([research.md](../research.md) R1) |
| *exactly one description per target* | FR-003 | this is the property #68 bought. Separateness was the mechanism; singularity was the point |
| *MAY be a section of an existing document* | FR-001 | the sentence that stops forbidding what the repository does |
| the gate carve-out | FR-005 | v0.6.0's FR-023 required `scripts/verify.sh` to keep the sentence giving a row's reason. A rule that forbade it would contradict a decision nine days old |
| *the published corpus* | FR-002 | replaces *any existing document* with the prohibition still true. `examples/` is named as a thing adding a target may not touch, which the old sentence covered only by accident |
| *other than the one holding the target descriptions* | FR-001, FR-004 | one exception, named by role and not by path, so a later move to `targets/` needs no second amendment |

**No path is named.** `README.md` does not appear in the amended bullet. `specs/008-path-denotation/plan.md`
§ *Complexity Tracking* records that `targets/gatling.md` is where descriptions go if a second target
arrives, and a rule naming today's filename would need amending on a move it does not govern.

## Delta 2 — Principle VI gains its record

Appended to Principle VI after the existing rationale, in the manner Principle III's 3.0.0 paragraph
already uses (FR-007, FR-008). It MUST state, in the principle itself:

1. **What the old bullet said and why it failed** — v0.5.0 put the Gatling correspondence in
   `README.md` because #68 found it in two places, drifted, with four issues closed a release earlier
   live again in the copy on the page most readers meet. One home was the fix. That made adding a
   second target a change to an existing document, which the bullet forbade in terms.
2. **That the departure was declared where contributors do not read rules** — inside a feature plan,
   under a directory `AGENTS.md` reads as history — so the repository shipped two contradicting
   normative documents for two releases (#83).
3. **What was actually wrong: the unit.** The separate file bought singularity, not separateness.
   The bullet now requires the property directly and defines what has to be singular first.
4. **That nothing checks it.** `scripts/verify.sh` does not read this file, which is why the
   contradiction stood through two releases, and *"does this sentence state a correspondence"* is not
   a question a script decides. The bullet is enforced in review or not at all, and the text says so
   rather than reading as though a gate were watching.

Point 4 is Principle IV applied to this principle: a rule that reads as gated when it is not is a
document reading as more settled than it is.

## Delta 3 — the Compatibility Constraints sentence stops being false

`.specify/memory/constitution.md:225`, last sentence of the 3.0.0 rationale paragraph. **Before:**

> The third surface, what a target's description may declare, is removed — nothing in this repository
> describes a target.

**After** it must carry three facts and no fourth: the surface was removed in 3.0.0 **when** nothing
described a target; one exists now, `README.md` § *What any tool can actually run*, added in v0.5.0;
and the surface is **not** restored, because a reach row would then need an argued issue and a
`GLOSSARY.md` entry recording a rejected alternative — and `GLOSSARY.md` is the vocabulary document,
where a rejected table row does not belong. Four reach rows changed in v0.6.0 through the ordinary
issue and milestone rules, and nothing about that went wrong (FR-009, FR-010).

**The list of compatibility-sensitive surfaces does not change.** Two items in, two items out. Under
the document's versioning policy, restoring the third would be a separate limb; it is recorded here
as the rejected alternative so a later reversal is a decision and not a rediscovery.

## Delta 4 — `AGENTS.md` loses the parenthetical

`AGENTS.md:35`. The sentence keeps its rule and loses its footing (FR-012).

**Before:** `… a second target is a second section there, not a second file (argued in
`specs/008-path-denotation/plan.md` § Complexity Tracking, against constitution Principle VI).`

**After:** `… a second target is a second section there, not a second file.`

Nothing replaces it. A citation of the constitution would be the third copy of a rule that already
has a home, and the `specs/` pointer is what `AGENTS.md` itself reads as history.

## Delta 5 — the plan template follows

`.specify/templates/plan-template.md` (FR-013). Two edits, one of them easy to miss:

| Line | Before | After |
|---|---|---|
| `:44` | ``See `.specify/memory/constitution.md` (v3.0.0).`` | ``… (v4.0.0).`` |
| `:61-63` | *"Does adding a target change the format, the schema, or an existing document?"* | asks about the format, the schema, the published corpus, and any existing document **other than the one holding the target descriptions**, and adds: is there still exactly one description per target? |

The version pointer is in scope because a gate that cites a superseded version is the same defect
this milestone is fixing, one file over.

## What a reviewer checks

1. Principle VI names no file path.
2. The amended bullet is true of the repository as it stands — `README.md:478` and
   `scripts/verify.sh:566` are permitted by it, and a second reach table anywhere is not.
3. `AGENTS.md` § *Architecture* and Principle VI can be read back to back with no third file.
4. The template's Principle VI question and the principle agree on what adding a target may change.
5. The compatibility list still has two items.
