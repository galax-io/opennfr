# Contract: the delta to the Selection table

**Feature**: `007-reach-table-rules`

The Selection table lives in `specs/004-strip-to-schema/contracts/gatling-reach.md` and stays there.
This file holds only what this feature **changes** about it — four rows added, two rows amended, one
note moved — so a reviewer argues the delta instead of diffing two copies of the same table. Rows
this feature does not touch (`{}` → `global`, and the four **cannot** rows for `http.*` and
"any other attribute") are not restated here.

## Rows added

| OpenNFR selector | Gatling | |
|---|---|---|
| `{loadtest.request.name: "*"}` | `forAll()` | **can** — the quantified reading: one assertion per observed request, not one number over all of them |
| `{loadtest.group.name: G, loadtest.request.name: "*"}` | — | **cannot** — no scope both quantifies and carries a path, so "every request inside one group" has no correspondence |
| `{loadtest.group.name: "*", loadtest.request.name: X}` | — | **cannot** — the same, and a group is not addressable on its own |
| any path value that is not a string | — | **cannot** — a path is `AssertionPathParts(parts: List[String])`. `{loadtest.request.name: 200}` and `{loadtest.request.name: "200"}` are different documents and only the second is renderable |

The first three are commit 3 (#55, #56); the fourth is commit 2 (#60).

## Rows amended

The two existing `details(...)` rows gain a value constraint. Their Gatling column and verdict do
not change.

| Was | Becomes |
|---|---|
| `{loadtest.request.name: X}` | `{loadtest.request.name: X}`, **`X` a string other than `"*"`** |
| `{loadtest.group.name: G, loadtest.request.name: X}` | `{loadtest.group.name: G, loadtest.request.name: X}`, **both strings other than `"*"`** |

The literal reading becomes explicit on those rows rather than being the residue left over once the
`"*"` rows are read — `X` is a path part, never a pattern.

## The sentence the table gains

**The value is part of the correspondence, not a detail of it.** An earlier draft of this contract
partitioned this axis by key set alone, and the gate written from it approved
`{loadtest.request.name: "*"}` — which the contract then rendered as a request literally named `*`,
a path matching nothing, failing the run for a reason unrelated to what was asserted. The fraction
axis learned the same lesson about `bad`, one table down.

## The note that moves

The absent-data paragraph in § *Two things Gatling cannot do at all* currently describes a scope no
document can select, which is #56's complaint. It becomes a note on the `forAll()` row: the
behaviour is unchanged, what changes is that a row now reaches it.

Nothing in the format compensates for that behaviour. A document is not obliged to carry a guard and
the gate does not require one — recording a fact about a target and legislating around it are
different things, and only the first is this repository's business.

## Where `"*"`'s meaning is written

Not here. `"*"` says the attribute is present **and** that each distinct value is a statement of its
own — a statement about the format, whose home is `GLOSSARY.md` § *selector*, restated for the field
in `README.md` and for the schema's reader in `$defs/selector`'s description. This contract only
maps it: the quantifier reaches `forAll()` here, and would reach whatever a second target calls the
same idea.

The two readings stay distinguishable, which is the point: `{}` is pooled, `{loadtest.request.name:
"*"}` is quantified. "The average endpoint is fast" and "no endpoint is slow" are different
requirements, and the format can now write both.

## What the gate must do

Not a copy of anything — `gatling-reach.md` states the rules and this is the behaviour they require
of `scripts/verify.sh`.

| Input | Verdict | Message names |
|---|---|---|
| key set not one of the three | reject | the selector, and that it is not an assertion path |
| any path value not a string | reject | that an assertion path part is a string |
| `"*"` on `loadtest.group.name` | reject | that a quantified selection cannot carry a path |
| `"*"` on `loadtest.request.name`, with a group also present | reject | the same |
| `"*"` on `loadtest.request.name` alone | accept | — |
| all path values strings, none `"*"` | accept | — |

Every rejection above has a probe (spec FR-008), and the probe table has a floor (FR-009). The
section keeps reading `examples/` and never the schema.

## Not touched

The Metrics, Operators and Units tables. The Aggregations table changes in one row — the percentile
row loses its ellipsis, research.md R3 — which is a different axis and a different commit.
