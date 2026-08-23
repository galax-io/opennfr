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
| `rate` with `bad: {error.type: "*"}` | `failedRequests.percent` | **can** — percent, 0..100, not a 0..1 rate |
| `count` with `bad: {error.type: "*"}` | `failedRequests.count` | **can** |
| any narrower `bad` — a status code, an error class | — | **cannot**. `failedRequests` counts KO and nothing else; a filtered numerator has no correspondence |
| `bad: {}` | — | **cannot**. Its numerator is every selected request, which is the denominator |
| `good` in any form | — | **cannot**. `successfulRequests` exists, but a selector matches presence and never absence, so no OpenNFR fraction corresponds to it |
| a percentile of a fraction | — | rejected by the schema before it reaches a target |

**The numerator is part of the correspondence, not a detail of it.** An earlier draft of this
contract listed the fraction shape without constraining `bad`, and the gate written from it
accepted `bad: {}` and arbitrary status-code filters — both of which would have to be
approximated at render time, which Principle III forbids.

## Operators

| OpenNFR `op` | Gatling | |
|---|---|---|
| `lt`, `lte`, `gt`, `gte` | `lt`, `lte`, `gt`, `gte` | **can** |
| `eq` | `is` | **can** |
| `neq` | — | **cannot** — conditions are `lt`, `lte`, `gt`, `gte`, `between`, `around`, `deviatesAround`, `is`, `in`. There is no negation, and `in` over the complement of a continuous quantity is not expressible |

## Units

Units are per statistic, not a shared pool: a unit valid for one statistic is not thereby valid
for another. A percentile in `%` is not a Gatling assertion.

| Statistic | Accepts | Native | Target |
|---|---|---|---|
| `responseTime.*` | `ms`, `s` | milliseconds | **`Int`** |
| `failedRequests.percent` | `%`, `1` | percent, 0..100 | `Double` |
| `allRequests.count`, `failedRequests.count` | `{request}` | count | **`Int`** |
| `requestsPerSec` | `{request}/s` | per second | `Double` |

**Where the target is an `Int`, the threshold converted to the native unit must be a whole
number.** `threshold: 0.5, unit: ms` is unrenderable; `threshold: 0.5, unit: s` is 500 ms and is
fine. Rounding is not an option — it would move the bar silently, which is the approximation
Principle III forbids.
| `ns`, `us`, `min`, `h`, `By`, `KiBy`, `MiBy`, `GiBy`, `{iteration}`, `{iteration}/s`, `{vu}` | — | not reachable through any assertable statistic |

## Two things Gatling cannot do at all

- **Abort a run on a violated assertion.** Assertions are evaluated after the run.
- **Fail on absent data in one case.** A `ForAll` assertion expands to the requests observed; if
  none were observed it yields zero results and the run exits successfully — nothing failed
  because nothing was checked. A `details(...)` path that matches nothing behaves the opposite
  way and fails with a resolution error. Both are recorded because the difference reads as an
  inconsistency otherwise.

## How this contract is applied

`scripts/verify.sh` § *Examples are assertable by Gatling* implements these tables and is the
only implementation — this page is the source, the gate is the check, and nothing else restates
either.

**The tables partition each axis.** A predicate is assertable only if it matches a row exactly;
anything unlisted is rejected. That direction is load-bearing. The first implementation was
written as a denylist — reject `sum`, reject `neq`, accept the rest — and defaulting to *allow*
is what let four unrenderable shapes through: a filtered `bad`, an empty `bad`, a percentile in
percent, and a fractional millisecond. A gap in these tables must fail the corpus, not pass it.
