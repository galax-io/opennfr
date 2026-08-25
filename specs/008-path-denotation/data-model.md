# Phase 1: Data Model

There is no data model in the ordinary sense — this repository ships a schema and documents
validated against it. What follows is the one node this feature changes, what each of its value
shapes means, and the invariant that decides whether the change is done.

## The node

`$defs/selector` — a map of attribute name to expected value, shared by three places: a
requirement's `selector`, and a predicate's `bad` and `good`.

| | Before | After |
|---|---|---|
| keys | any string; not enumerated | unchanged |
| values | `string`, `number`, `boolean` | unchanged, **except** `loadtest.group.name` |
| `loadtest.group.name` | a string | an array of strings, `minItems: 1` |
| how the schema says so | `additionalProperties` only | `properties` names the one attribute; `additionalProperties` is left as it is |

The schema names an attribute for the first time. It names it to fix the shape of its value, not to
enumerate which keys are admitted — any string is still a key, and `README.md` carries that
qualifier (FR-013). This is the only way the **schema** can reject a scalar; leaving the schema
name-blind would demote that rejection to the gate and admit an array under every attribute.

## The value shapes and what each denotes

A selector is a conjunction matched by equality. One rule is added and no other: **where a selector
names a request, an absent `loadtest.group.name` means the empty hierarchy.**

| Selector | Denotes | Renders |
|---|---|---|
| `{}` | every request, pooled | `global` |
| `{loadtest.request.name: X}` | the request named `X` with no enclosing group | `details("X")` |
| `{loadtest.group.name: [G₁…Gₙ], loadtest.request.name: X}` | the request named `X` whose hierarchy is exactly `G₁…Gₙ`, outermost first | `details("G₁"/…/"Gₙ"/"X")` |
| `{loadtest.request.name: "*"}` | one statement per request position the run records, at any depth | `forAll()` |
| `{loadtest.group.name: [G₁…Gₙ]}` | the requests whose hierarchy is exactly `G₁…Gₙ` | — (#52) |
| `{loadtest.group.name: [G₁…Gₙ], loadtest.request.name: "*"}` | one statement per position inside that hierarchy | — |
| `{loadtest.group.name: ["*"], …}` | a group at that position with any name | — no scope carries a wildcard path part |
| `{loadtest.group.name: "G", …}` | — | rejected by the schema |
| `{loadtest.group.name: [], …}` | — | rejected by the schema |

The last two are the only shapes the **format** refuses. Everything else without a Gatling scope
stays a valid document, as the constitution's corpus clause requires — the corpus narrows, the
format does not.

## Three terms this feature fixes

- **Hierarchy** — the value of `loadtest.group.name`: an ordered list of at least one recorded group
  name, outermost first. Matched as the *whole* hierarchy, never a prefix of one. Its absence
  beside a named request is a statement, not a default.
- **Position** — a request's hierarchy, then its name. What a singular row names, and what the
  quantifier ranges over. The word exists because three granularities were in play across four
  documents — per distinct value, per named request, per occurrence — and only per position is what
  the target enumerates.
- **Quantified selection** — a requirement's selector carrying `"*"` in place of a request name. It
  names no request, so the anchoring rule does not fire, which is why it reaches a scope carrying no
  path rather than by an exception written for one row.

## The invariant

Every row in the **can** column is an exact correspondence: the set of recorded requests the row
denotes and the set the Gatling scope resolves to are the same set, at any depth.

One precondition qualifies rows 2 and 3 and cannot be closed from the format's side: **the rendered
path must not also be the full hierarchy of a recorded group.** Where it is, Gatling resolves the
collision out of a hash map and may measure the group's cumulated response time instead — see
[research.md](./research.md) R1. It is a statement about the target, dated and sourced, not a
narrowing of the format and not a construct.

Two consequences follow from the invariant rather than being asserted beside it:

- the quantified row instantiates into the singular rows of the same table at every depth, because
  every position `forAll()` enumerates is now nameable by a row — except one, and it is unnameable
  rather than unrendered: a request recorded literally as `*`, or one under a group recorded as `*`.
  `"*"` is reserved as presence everywhere it appears, so no singular selector can name such a
  position. A limitation of the value, not of the hierarchy;
- no row in the **can** column is a narrowing recorded as a note, which is what #54 reported.
