# Contract: the delta to the Selection table

**Feature**: `008-path-denotation`

After #68 the Selection table lives in `README.md` § *What any tool can actually run*. This file
holds only what this feature **changes** about it — two rows amended, four rows added, one
precondition attached, one note — so a reviewer argues the delta instead of diffing two copies of
one table. Rows this feature does not touch are not restated here, and the Metrics, Aggregations,
Operators and Units tables are untouched entirely.

Following `specs/007-reach-table-rules/contracts/reach-selection.md`, which did the same thing for
the previous milestone.

## Rows amended

Both `details(...)` rows change on the OpenNFR side only. Their Gatling column and their verdict do
not change; what changes is that each now says what it denotes, and one of them can now be written
at any depth.

| Was | Becomes |
|---|---|
| `{loadtest.request.name: X}`, `X` a string other than `"*"` | `{loadtest.request.name: X}`, `X` a string other than `"*"` — **the request named `X` with no enclosing group**, which is what a one-part path resolves against |
| `{loadtest.group.name: G, loadtest.request.name: X}`, both strings other than `"*"` | `{loadtest.group.name: [G₁, …, Gₙ], loadtest.request.name: X}` — **the request named `X` whose hierarchy is exactly `G₁…Gₙ`, outermost first**, at any depth. `details("G₁" / … / "Gₙ" / "X")` |

The second row absorbs the depth-one case; there is no separate row for one group, because there is
no separate spelling for one group.

## Rows added

| OpenNFR selector | Gatling | |
|---|---|---|
| `{loadtest.group.name: [G₁, …, Gₙ]}`, no request name | — | **cannot** — it denotes the requests whose hierarchy is exactly those groups, and Gatling's group scope measures a *cumulated* duration the Metrics table cannot name. Open as [#52](https://github.com/galax-io/opennfr/issues/52) |
| `{loadtest.group.name: ["*"], …}` | — | **cannot** — a hierarchy is matched by equality, and an element that is not a recorded name leaves the path unwritten. There is no scope that carries a wildcard part |
| `loadtest.group.name` as a **string** | — | rejected by the **schema**, not by this table: a hierarchy has one spelling, and a scalar would be a second one for the depth-one case |
| `loadtest.group.name: []` | — | rejected by the **schema**: "no enclosing group" is said by omitting the key |

The last two are the only shapes this milestone makes the *format* refuse. Both are format defects —
two spellings of one statement — and neither is a target's limitation, which is why they sit in the
schema and not here.

## The row that stays, restated

| OpenNFR selector | Gatling | |
|---|---|---|
| `{loadtest.request.name: "*"}` | `forAll()` | **can** — one statement per **request position** the run records, at any depth |

The verdict is unchanged from #56. What changes is the count: "one assertion per observed request"
becomes "per recorded request position", because `allRequestPaths()` `collect`s the request keys of
a map — each `(hierarchy, name)` pair exactly once, groups discarded. Not once per distinct attribute
value, and not once per occurrence.

## The precondition the two `details(...)` rows gain

**The rendered path must not also be the full hierarchy of a recorded group.**

Where it is, Gatling's own resolution is unspecified: `LogFileData.findPathByParts` is a
`collectFirst` over the keys of a `mutable.HashMap` holding request paths and group paths together,
so which one matches depends on hash order and can change when an unrelated request is added to the
simulation. Where the group wins, the assertion measures that group's **cumulated** response time
rather than the request's — a different quantity under the same metric name.

This is recorded, not legislated around. The format cannot express "a request, not a group", nothing
in Gatling's assertion API consumes such a distinction, and whether a run records a group of that
name is not knowable when a document is written. Read from source 2026-08-25 at `v3.15.1` and
`v3.13.5`; see [research.md](../research.md) R1, which also labels which part of the evidence is a
replication rather than a reading.

`forAll()` is **immune**: it never calls `findPathByParts`.

## The note the table gains

**A requirement's guards are quantified with its criteria.** The selector is written once and binds
both, so a guard under `{loadtest.request.name: "*"}` renders `forAll().requestsPerSec…` and states
its condition of each request position rather than of the run. On a run that recorded nothing it
expands to zero assertions and passes — vacuous in exactly the case a guard exists to catch. The
guard that says the run happened has to sit on a `{}` requirement, and today it cannot sit there
alone: `requirement.required` is `["name", "selector", "criteria"]` and `criteria` is `minItems: 1`.
Open as [#61](https://github.com/galax-io/opennfr/issues/61).

## Where the meaning of these values is written

Not here. `loadtest.group.name`'s arity and the rule about its absence are statements about the
**format**, whose home is `GLOSSARY.md` § *selector*, restated for the field in `README.md`
§ `selector` and for the schema's reader on `$defs/selector`. This table only maps them.

After #68 the definition and the table are both inside `README.md`. They stay distinguishable and
must not merge: § `selector` owns the definition, and a Selection row carries the correspondence and
never a second definition of the same value.

## What the gate must do

Not a copy of anything — the table states the rules and this is the behaviour they require of
`scripts/verify.sh`.

| Input | Verdict | Message names |
|---|---|---|
| key set not one of the three | reject | the selector, and that it is not an assertion path |
| `loadtest.group.name` not a list | reject | that a hierarchy is a list of names and never one name |
| `loadtest.group.name` an empty list | reject | that no enclosing group is spelled by omitting the key |
| any path part not a string | reject | that an assertion path part is a string |
| `"*"` anywhere in the path but in place of the request name | reject | that `"*"` is not a recorded name and `forAll()` carries no path |
| `"*"` in place of the request name, alone | accept | — |
| a hierarchy of any depth, all parts strings, none `"*"` | accept | — |

Two rules of the gate's own, both from [research.md](../research.md) R2 and both measured:

- **the list check must precede the flattening.** A scalar hierarchy flattened first becomes one
  path part per character — `"Checkout"` becomes eight parts — and every rule after it passes.
- **the `"*"` test reads the flattened path, not the selector's values.** Under `sel.values()` a
  hierarchy is a list and never equals `"*"`, so the branch goes silently dead and
  `{loadtest.group.name: ["*"], …}` is accepted — reinstating the defect #55 closed.

Every rejection above has a probe, and the probe table has a floor. **A rejection table cannot show
that a row still renders**, and the corpus cannot either — nothing published nests two groups, so a
depth bound added to the rule would leave every existing check green. So the section gains a second,
positive probe table whose last row is the three-level requirement from #53.

The three rejections the **schema** now makes — a scalar, an empty list, an array under any other
attribute — are probed in § *The schema holds up its own examples, and still rejects*, not here: this
section reads `examples/` and never the schema, by a rule it carries in its own comments.

## Not touched

The Metrics, Aggregations, Operators and Units tables. The absent-data note, which #56 already
attached to the `forAll()` row. Whether a group-scoped statement should exist at all (#52), and
whether a guard may carry its own selection (#61).
