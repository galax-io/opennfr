# Contract: the delta to two `cannot` rows

**Feature**: `009-what-was-measured` | **Issues**: [#62](https://github.com/galax-io/opennfr/issues/62), [#52](https://github.com/galax-io/opennfr/issues/52)

The reach tables live in `README.md` § *What any tool can actually run* and stay there. This file
holds only the delta: one row gains a reason, one row stops deferring and gains a better one.

## What was withdrawn from this contract

An earlier draft defined **two kinds of `cannot`** — the target's limit and the format's — in
§ *How these tables are applied*, and marked rows of the second kind. That is withdrawn, for a
reason found inside this very file: it filed `good` under "the target having nothing", while the
published row says the opposite —

> `good` in any form | — | **cannot**. `successfulRequests` **exists**, and no OpenNFR fraction
> corresponds to it, for the reason § `selector` gives

— which is the format's limit by the draft's own definition. A taxonomy that misclassifies a row in
the document that defines it is worse than none. Four of the fifteen `cannot` rows do not classify
cleanly, nothing in the gate checks the classification, and the milestone owes a `cannot` **with its
reason**, not with its kind.

**Every `cannot` row states its reason. No row states a category of reason.** That is the rule, and
most rows already obey it.

## The row that gains a reason — Metrics (#62)

The table's existing row is amended. No row is added: the left column holds metric **names**, and a
row whose left cell is a prose class can never be matched in a table whose published law is
*"assertable only if it matches a row exactly"*.

| Was | Becomes |
|---|---|
| `any other` \| — \| **cannot** | `any other` \| — \| **cannot** — `responseTime` is reached through the four rows above and nothing else here has been checked against a rendering. Two different cases sit under this row and § *Names* separates them: a name a convention already carries for an operation on another protocol is a valid document with no dated rendering, while a duration recorded for a span an author bracketed across several requests has no name at all |

**The row asserts nothing about Gatling beyond what is already published and dated.** An earlier
draft added *"`responseTime` would render it, being the same statistic whatever recorded the entry"*.
That is a claim about an external tool, which Principle IV requires to be sourced and dated, and
this branch cannot re-check the decompiled evidence #62 reports. The row does not need it.

**And it does not claim a naming gap where there is none.** § *Names* § *Metrics* must state the two
halves differently:

- **the format's gap**: a duration recorded for a span an author bracketed — a business transaction
  across several requests — which no convention names, and for which
  `http.client.request.duration` is false;
- **an evidence gap, not a naming one**: an operation on another protocol, which semantic
  conventions do name. Such a document is valid today under the general Names rule. It is absent
  from these tables because no rendering has been checked and dated and no example uses one — and
  the text must not name a specific convention unless that name is checked and dated in the same
  change.

## The row that stops deferring — Selection (#52)

| Was | Becomes |
|---|---|
| `{loadtest.group.name: [G₁, …, Gₙ]}`, no request name \| — \| **cannot** — it denotes the requests whose hierarchy is exactly those groups, and Gatling's group scope measures a *cumulated* duration the Metrics table cannot name. *"Whether a group-scoped statement should exist at all is open, as #52"* | the same verdict, the same first clause, and the deferral replaced by the reason below |

The reason, in the row:

> **cannot** — it denotes the requests whose hierarchy is exactly those groups, and **no scope
> denotes the requests a path encloses**. The scopes are `Global`, `ForAll` and `Details(parts)`, and
> `Details` on a group's path resolves to the group, whose statistics are its own — so neither a
> duration of the enclosed requests nor a count of them is reachable. What the group scope does
> compute is a *cumulated* response time, which no name in § *Names* is true of.

Two things this fixes beyond the deferral:

1. **The old reason was under-inclusive.** The row governs every predicate under that selector,
   including one carrying no `metric` at all — and `selection_why` refuses those on the key set,
   before `shape_of` looks for a metric. "A cumulated duration the Metrics table cannot name" is not
   the obstacle for `{aggregation: count}`; "no scope denotes the enclosed requests" is the obstacle
   for both.
2. **It stops pricing a construct the row does not express.** An earlier draft said the shape would
   need *"a denotation for a group as well as a request, and a name for what a group scope
   measures"*. That describes a different feature; the row's job is to say why this selector is
   refused.

**Every claim here is already published, sourced and dated** — the three scopes at `README.md`'s
provenance note (checked 2026-08-20, re-checked 2026-08-24), and the cumulated statistic (2026-08-25,
v3.15.1 and v3.13.5). Nothing new about Gatling is asserted.

## What the gate must do

**Nothing changes.** That is the point of recording it here.

| Input | Verdict | Message |
|---|---|---|
| `{loadtest.group.name: ["Checkout"]}` | rejected | `selector ['loadtest.group.name'] is not an assertion path` — unchanged |
| any metric other than `http.client.request.duration` in `examples/` | rejected | `metric … is not addressable` — unchanged |

One comment changes. The note above `SELECTIONS` currently ends *"…a cumulated duration the Metrics
table cannot name (#52)"*. **The pointer goes; the sentence stays.** It must not gain a copy of the
row's paragraph — `README.md` is the only place the tables are stated, and a reach rule in a second
artifact is what #68 closed a release ago.

## What is not done here

- **The metric axis is not widened.** A convention's name for another protocol's operation stays
  valid in the format, outside the corpus, and outside these tables.
- **No row becomes a `can`.** This feature changes no verdict on either axis.
- **No name is minted.** `GLOSSARY.md` § *metric* records the declined name and why, which is where
  this repository keeps what a term declined to become.
- **`docs/ideas.md` gains no entry.** Its `loadtest.*` registry entry gains one clause naming the
  composite-span case; the condition is already published there, and the isolation gate requires the
  entry count and the *Would need* count to stay equal.
- **`specs/004-strip-to-schema/contracts/gatling-reach.md` is not edited.** It is a dated redirect;
  `specs/007-reach-table-rules/contracts/reach-selection.md` is a completed feature's delta. Both are
  history.
