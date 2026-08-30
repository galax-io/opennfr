# Phase 1: Data Model

**Feature**: `009-what-was-measured` | **Date**: 2026-08-30 | **Revised** the same day after adversarial review

No entity is added, no field is added, **and nothing changes about what the schema validates**. What
changes is what two descriptions say, and what one table lists.

The first draft of this file presented the predicate as a partition the schema would enforce. That is
withdrawn: the partition is the *target's*, not the format's, and the difference is the milestone's
substance.

---

## The predicate: what the format says, and what a target reaches

A predicate is one of three shapes, decided by which optional key it carries. The format admits an
aggregation over a shape wherever the aggregation has a meaning there; Gatling reaches a narrower
set. **The two are different tables and this feature keeps them apart.**

| Shape | Written as | Aggregations the **format** admits | Of those, what **Gatling** reaches |
|---|---|---|---|
| **measurement** | `metric` present, no `bad`/`good` | any percentile, `avg`, `min`, `max`, `stddev`, `sum`, `count`, `rate` | percentiles, `avg`, `min`, `max`, `stddev` |
| **fraction** | `bad` or `good` present, no `metric` | `count`, `rate` | `count`, `rate`, with `bad: {error.type: "*"}` only |
| **count** | neither | `count`, `rate` | `count`, `rate` |

Three shapes on the left that the schema enforces; a narrower right-hand column that the reach tables
enforce on the corpus. Reading the measurement row across is the whole of #57: `sum` was already
format-yes / Gatling-no and nobody confused it; `count` and `rate` were the same and the gate had
them on the wrong side.

**What `count` over a metric denotes**: how many observations of that metric the selection carries.
That is not how many requests the selection carries, wherever the metric is not recorded for every
request — and the format admits such metrics, because it does not enumerate metric names and it
publishes `http.server.request.duration` for requirements stated over the system's own data. The
quantity is real; no surveyed target computes it; so it is a `cannot` row, like `sum`.

**The rules, unchanged** — four branches in `$defs/predicate.allOf`, each carrying its own
description:

1. A metric is measured; a fraction is counted. Not both.
2. At most one side of a fraction.
3. A fraction has no percentile — with `bad`/`good`, the aggregation is `rate` or `count`.
4. A percentile, mean or spread needs values, so it needs a metric.

No fifth branch. The one that was written is in `research.md` R1, with the condition that would ship
it.

---

## The selector, and what a value denotes

Unchanged in what it admits. What changes is that the schema states three things it already decides
and one it did not decide at all.

| Value | Denotes | Where it is stated after this feature |
|---|---|---|
| any string, number or boolean | that attribute, matched by equality | `$defs/selector` — unchanged |
| `loadtest.group.name`, an array of strings | the request's enclosing groups, outermost first, at any depth, matched as the whole hierarchy | `$defs/selector` — unchanged |
| `"*"` in any value position | the attribute is present with any value | `$defs/selector` — unchanged |
| `"*"` **as a request name** | not a name, so the anchoring rule does not fire and no hierarchy is claimed | `$defs/selector` — **added** (#78) |
| `"*"` **in a hierarchy element** | a group at that position with **any** name — presence, as everywhere; never a group recorded under the name `*` | `$defs/selector` — **added** (#77) |

**The anchoring rule is unchanged and now decidable**: *where a selector names a request, an absent
`loadtest.group.name` means the empty hierarchy*. Its trigger — what counts as naming a request — was
the undecidable part, and `"*"` is not a name is what decides it.

**The quantifier needs no new clause.** `$defs/selector` already says the requirement is stated once
of *"each request position the selector admits"*, which is key-agnostic: a `"*"` element admits
positions the same way a `"*"` request name does. The first draft proposed spelling that out; it is
withdrawn as a restatement.

**The closing sentence is corrected, not removed.** *"Attribute names are not enumerated — they are
borrowed from OpenTelemetry, whose values may be strings, numbers or booleans"* justifies
`additionalProperties: {type: [string, number, boolean]}` and must survive; it gains the exception for
the one attribute the same description names, whose only admissible value is an array.

---

## Three names this feature does not add

Recorded because the milestone's substance is the decision not to add them, and a data model listing
only what exists hides that. All three land in `GLOSSARY.md` as *Rejected* material.

| Not added | What it would have named | Why not |
|---|---|---|
| a name for an author-bracketed span | a business transaction across several requests | no convention names it, and a `loadtest.*` name nothing emits is a vocabulary of one. Admitting it to reach one target's feature is what the binding constraints call insufficient |
| a name for a group's cumulated response time | what a group-scoped assertion measures | the same — **and** it would not make the shape renderable, because no scope denotes the requests a path encloses |
| a schema rule making `{metric, count}` invalid | — | it would narrow the format to one target's reach, against a binding constraint. `research.md` R2 carries the condition that would reverse this |

A fourth is not a name and is recorded here for the same reason: the **two kinds of `cannot`**
taxonomy, withdrawn because it misclassified a row in the document that defined it.

---

## The invariant

**A selector value means one thing wherever it appears, and a `cannot` row says why.**

Before this feature both halves were false: `"*"` meant presence in a value and a literal name in a
hierarchy element, and two rows refused a shape while deferring or omitting the reason. Both are
checkable — the first by reading the three artifacts against each other, the second by reading the
tables — and both are what the quickstart checks.

The invariant the first draft claimed — *a predicate carries no field its aggregation cannot read* —
is **not** an invariant of this format, and asserting it was the error the review caught.
