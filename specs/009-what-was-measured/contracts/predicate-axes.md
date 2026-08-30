# Contract: the delta to the reach tables' predicate axes, and to the gate

**Feature**: `009-what-was-measured` | **Issue**: [#57](https://github.com/galax-io/opennfr/issues/57)

The reach tables live in `README.md` § *What any tool can actually run* and stay there. The
predicate's schema rules live in `schema/opennfr.io/v1/requirementset.schema.json` and **do not
change**. This file holds only the delta: two rows added to one table, two lines deleted from the
gate, and a probe list for axes that have never had one.

## What does not change, and why that is the decision

`{metric: X, aggregation: count}` and `{metric: X, aggregation: rate}` stay **valid**.

An earlier draft of this contract made them invalid with a fifth `allOf` branch. That is withdrawn.
The shape has a referent — how many observations of `X` the selection carries, which is not how many
requests it carries wherever the metric is not recorded for every request — and `README.md` states
that at format level, four hundred lines above any target. Making it invalid would have deleted a
format-level claim to fit one target's reach, against a binding constraint:

> The published corpus MAY be narrower than the format, and the format MUST NOT be narrowed to match
> it… The schema keeps what no target reaches, and the field description says which parts those are.

It would also have made this the only reach-`cannot` the schema rejects. `{metric, sum}` and
`op: neq` are valid today and both are `cannot` rows; nothing distinguishes `{metric, count}` from
them.

**The condition that would reopen it**, recorded so the decision is reversible: if no surveyed target
computes a per-metric observation count, and the format cannot say what the shape denotes
independently of the request count, then the field has no referent and the rule becomes correct.
Nobody has checked, on either side. The check is k6's Trend `count` and Prometheus's `_count`,
against dated documentation, as Principle IV requires. Because this ships as a two-line deletion,
adding the rule later costs exactly what it costs today.

## The rows added

`README.md` § *Aggregations* → *Over a metric* gains two rows, so the shape is matched by a row and
refused, rather than excluded by the table's silence:

| | Gatling | |
|---|---|---|
| `count` | — | **cannot** — `responseTime` offers no count of its own observations, and `allRequests.count` counts requests, which is a different question wherever a metric is not recorded for every request |
| `rate` | — | **cannot** — the same: `requestsPerSec` is a rate of requests, not of a metric's observations |

The partition rule at the foot of the section already says an unlisted shape is rejected. Listing
these two makes the refusal a row a reader can find, and gives the gate's message a published home.

## The rows kept, against the earlier draft

| Where | Earlier draft | Now |
|---|---|---|
| § *What a criterion can be about*, the `metric` row | delete `count` and `rate` from its aggregations | **kept**. It is a format-level claim about what a criterion can be about, and it is true |
| § *A predicate*, the note after the rules | withdraw *"Note what rule 4 does not cover: `count` and `rate` are absent from it…"* | **kept**. Rule 4 still does not cover them, and the note still explains what lets a predicate carrying neither `metric` nor `bad` count the requests themselves |
| § *What you will see when it is wrong* | one new row for a new schema message | **no row**. There is no new message: the schema is unchanged |

## The gate: what is deleted

`TABLE["metric"]` (line ~597) loses its `"count"` and `"rate"` entries:

```python
"metric": {
    "PERCENTILE": ("responseTime.percentile", TIME, True),
    "max":        ("responseTime.max",        TIME, True),
    "min":        ("responseTime.min",        TIME, True),
    "avg":        ("responseTime.mean",       TIME, True),
    "stddev":     ("responseTime.stdDev",     TIME, True),
-   "count":      ("allRequests.count",       COUNT, True),
-   "rate":       ("requestsPerSec",          PERSEC, False),
},
```

Those two lines are the whole defect. They are byte-identical to the `"requests"` rows, so
`shape_of` classified a predicate carrying a `metric` as shape `"metric"`, the aggregation resolved
to the request-counting row, and the `metric` key was reported nowhere. Two documents that differ
produced identical assertions.

After the deletion, the existing fall-through fires:

```
aggregation count over a metric has no equivalent
```

which is the reach tables' own verdict, in the gate's own words. No new message is introduced.

## The gate: what is added

**A predicate probe list, with its own floor**, in the shape `SELECTION_PROBES` already has.

This is the milestone's largest finding and it is not #57's report. The Gatling section probes
**one** of its five axes. `SELECTION_PROBES` and `SELECTION_RENDERS` cover selection; the metric,
aggregation, operator and unit partitions have no probe at all. The corpus cannot stand in for them,
because it holds only documents that are assertable — so every rejection rule on four axes is
unexercised, and any of them could be deleted green. That is how `TABLE["metric"]` carried `count`
and `rate` for five releases.

| Probe | Expected refusal |
|---|---|
| `{metric: M, aggregation: count, …}` | `aggregation count over a metric has no equivalent` |
| `{metric: M, aggregation: rate, …}` | `aggregation rate over a metric has no equivalent` |
| `{metric: M, aggregation: sum, …}` | `aggregation sum over a metric has no equivalent` |
| `{metric: "http.client.response.body.size", …}` | `metric … is not addressable` |
| `{… op: neq …}` | `op neq has no equivalent` |
| `{… aggregation: p95, unit: "%"}` | `unit % is not a unit of responseTime.percentile` |
| `{… aggregation: p95, threshold: 0.5, unit: ms}` | the integer-target refusal |

The first is the sole catcher of the `TABLE["metric"]` defect regressing. The rest are the axes that
have never been probed; each is the sole catcher of its own rule. The floor is set to the count, as
the selection floors are, and raising it is the intended cost of adding a probe.

**A rendering counterpart** is not needed here: every accepted predicate shape is already exercised
by the corpus, which the selection axis could not claim.

## What the gate must not do

- **It must not read the schema.** The section says so in its own comment, and the reason is this
  milestone's reason: the format is wider than the corpus, and a gate that read the schema would
  narrow one to the other.
- **It must not reject `{metric, count}` on the author's behalf anywhere but here.** The shape is
  valid; what is refused is its appearance in a published example.

## Not touched

`$defs/predicate` and every rule in it. `$defs/aggregation` — its description has a separate,
unrelated defect (it defines `rate` over a `distribution` and a `ratio`, two terms the schema does
not contain), which needs its own issue and does not travel in this commit. `shape_of`, `BAD`,
`OPS`, the fraction table, and every selection probe and floor.
