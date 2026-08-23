# Contract: what Gatling can assert

**Source**: `mappings/gatling.yaml` @ `cb7cb58`, itself sourced to the Gatling v3.15.1 source
files `AssertionSupport.scala`, `AssertionBuilders.scala`, `AssertionPathParts.scala` and
`AssertionModel.scala`. **Checked 2026-08-20.**

This is the bar FR-010, FR-011 and FR-012 test the corpus against. A predicate that is not in the
**can** column below may not appear in a published example. It may still appear in a document
somebody writes — the format is not narrowed (FR-014).

## Selection

Gatling's assertion scope is `Global`, `ForAll`, or `Details(parts)` where `parts` is a path of
recorded group and request names. Nothing else is addressable — not a route, not a method, not a
status code, not an error type.

| OpenNFR selector | Gatling | |
|---|---|---|
| `{}` | `global` | **can** |
| `{loadtest.request.name: X}` | `details("X")` | **can** |
| `{loadtest.group.name: G, loadtest.request.name: X}` | `details("G" / "X")` | **can** |
| `{http.route: ...}` | — | **cannot** |
| `{http.request.method: ...}` | — | **cannot** |
| `{http.response.status_code: ...}` | — | **cannot** |
| any other attribute | — | **cannot** |

## Metrics

| OpenNFR `metric` | Gatling | |
|---|---|---|
| `http.client.request.duration` | `responseTime` | **can** |
| `http.client.request.body.size`, `http.client.response.body.size` | — | **cannot** — the assertion DSL reaches response time and request counts only |
| any other | — | **cannot** |

## Aggregations

Over a metric:

| | Gatling | |
|---|---|---|
| `p50`…`p99.9` | `responseTime.percentile(n)` | **can** — target is `Int` milliseconds, so a fractional millisecond is not representable |
| `max`, `min` | `responseTime.max` / `.min` | **can** |
| `avg` | `responseTime.mean` | **can** |
| `stddev` | `responseTime.stdDev` | **can** |
| `sum` | — | **cannot** — `responseTime` offers no sum and no arithmetic that would produce one |

Over the requests themselves, with no `metric` and no `bad`/`good`:

| | Gatling | |
|---|---|---|
| `count` | `allRequests.count` | **can** |
| `rate` | `requestsPerSec` | **can** — a `Double` target |

Over a fraction, with `bad` or `good`:

| | Gatling | |
|---|---|---|
| `rate` with `bad` | `failedRequests.percent` | **can** — percent, 0..100, not a 0..1 rate |
| `count` with `bad` | `failedRequests.count` | **can** |
| `rate` with `good` | `successfulRequests.percent` | **can** |
| `count` with `good` | `successfulRequests.count` | **can** |
| a percentile of a fraction | — | rejected by the schema before it reaches a target |

## Operators

| OpenNFR `op` | Gatling | |
|---|---|---|
| `lt`, `lte`, `gt`, `gte` | `lt`, `lte`, `gt`, `gte` | **can** |
| `eq` | `is` | **can** |
| `neq` | — | **cannot** — conditions are `lt`, `lte`, `gt`, `gte`, `between`, `around`, `deviatesAround`, `is`, `in`. There is no negation, and `in` over the complement of a continuous quantity is not expressible |

## Units

| OpenNFR | Gatling expects | |
|---|---|---|
| `ms` | milliseconds, `Int` | direct |
| `s` | milliseconds | ×1000 |
| `%` | percent, 0..100 | direct |
| `1` | percent | ×100 |
| `{request}/s` | `requestsPerSec`, `Double` | direct |
| `{request}` | count, `Int` | direct |
| `ns`, `us`, `min`, `h`, `By`, `KiBy`, `MiBy`, `GiBy`, `{iteration}`, `{iteration}/s`, `{vu}` | — | not reachable through any assertable statistic |

## Two things Gatling cannot do at all

- **Abort a run on a violated assertion.** Assertions are evaluated after the run.
- **Fail on absent data in one case.** A `ForAll` assertion expands to the requests observed; if
  none were observed it yields zero results and the run exits successfully — nothing failed
  because nothing was checked. A `details(...)` path that matches nothing behaves the opposite
  way and fails with a resolution error. Both are recorded because the difference reads as an
  inconsistency otherwise.

## How this contract is applied

The corpus is checked predicate by predicate against these tables. A mechanical check is possible
and is what SC-002 asks for: for each predicate, the selector's key set must be one of the three
in **Selection**; `metric` if present must be `http.client.request.duration`; the aggregation must
be in the row matching the predicate's shape; the operator must not be `neq`; the unit must be
reachable.
