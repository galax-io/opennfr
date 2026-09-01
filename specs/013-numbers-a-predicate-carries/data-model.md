# Phase 1 — Data Model: Which Numbers a Predicate May Carry

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-09-01

Nothing here is a data structure in a program. These are the entities the milestone's rules are
written about, each with where it lives, what decides it, and what it may hold after the change.

---

## 1. The percentile pattern

**What it is**: the decision that an aggregation names a percentile.

| | |
|---|---|
| **Stated in** | `schema/…/requirementset.schema.json` → `$defs/aggregation.anyOf[1].pattern` |
| **Restated in** | `README.md` § *Aggregations*, first row, quoting the schema |
| **Implemented in** | `scripts/verify.sh`, the Gatling heredoc |
| **Value** | `^p\d{1,2}(\.\d+)?$` — one string, three places, character-identical |

**Admits**: `p0` … `p99`, optionally with a decimal fraction of any length. `p95`, `p99.9`,
`p0.1`, `p99.99`, `p1`, `p10`.

**Refuses**: an integer part of three or more digits (`p100`, `p999`, `p1234`), a missing integer
part (`p.5`), a trailing bare dot (`p1.`), a bare `p`, and — under `re.fullmatch`, not under
`re.match` — a trailing newline (`"p95\n"`). See [research.md](research.md) R1.

**Invariant after this milestone**: the three copies are one string. The row is the argued
artifact; the schema decides validity; the gate implements the row. Drift between the gate and
the row is caught by three probes. Drift of all three *together* — if the schema's pattern
widened — is caught by nothing, and is in [spec.md](spec.md) § *Out of Scope*.

**Does not change**: the pattern's value, the schema, or § *Aggregations*' text.

---

## 2. The conversion

**What it is**: a `threshold` and a `unit` reduced to a statistic's native unit.

| | |
|---|---|
| **Inputs** | `threshold` (a JSON `number`, no stated precision) and `unit` (closed enumeration, 17 values) |
| **Factor** | per statistic — `TIME`, `SHARE`, `COUNT`, `PERSEC` in the gate; the `Accepts` and `Native` columns of § *Units* |
| **Output** | one exact rational in the statistic's native unit |
| **Arithmetic** | **exact decimal on the value `threshold` denotes** — new, and the whole of #59 |

**The arithmetic, stated**: the conversion is computed exactly over the decimal value the
threshold denotes, never over the binary double nearest to it. A renderer that has already parsed
into a double conforms by recovering the shortest decimal that round-trips that double and
computing from there; that decimal is the literal's value for any literal of at most fifteen
significant digits, which is more precision than a threshold carries.

**Why this and not "the literal as written"**: JSON and YAML parsers discard source text, and a
format may not require a parser nobody has (FR-010). Why not shortest-round-trip *as* the rule:
Java's `Double.toString` did not always produce the shortest decimal before JDK 19, so the answer
would depend on the JDK. The rule is about the value; the recovery is one route to it.

**Where the two arithmetics disagree** — the reason the rule cannot stay unstated:

| document | exact decimal | IEEE-754 double |
|---|---|---|
| `1.001 s` | `1001` → renders | `1000.9999999999999` → refused |
| `1.003 s` | `1003` → renders | `1002.9999999999999` → refused |
| `1.005 s` | `1005` → renders | `1004.9999999999999` → refused |

---

## 3. The whole-number rule

**What it is**: the constraint that a converted value must be whole where the target cannot hold
a fraction. It forbids rounding, because rounding moves the bar the author wrote.

| | before | after |
|---|---|---|
| **Condition** | "Where the target is an `Int`" | "Where the target is **integral**" |
| **Governs** | the two duration statistics; the count rows only by the accident that they were also labelled `Int` | the two duration statistics **and** both count rows, explicitly |
| **Implemented by** | the gate's `integral` flag — already correct, already covering both count rows | unchanged |

**Why the wording must change with the cell**: § *Units* labels `allRequests.count` and
`failedRequests.count` as `Int`; the DSL returns `Long` ([research.md](research.md) R3).
Correcting the cell while the rule still says `Int` drops counts out of the rule and makes
`threshold: 20.5, unit: {request}` renderable. The gate never read the word — it reads a boolean —
so the gate was right and the page was wrong.

**Refuses, after the change, exactly as before**: `0.5 ms` (1/2), `0.1 ms` (1/10),
`20.5 {request}` (41/2), and newly reachable sub-millisecond values `1500 ns` (3/2000) and
`1 us` (1/1000).

---

## 4. The Units reach table

**What it is**: one row per statistic, plus one derived row for what nothing reaches.

**After this milestone**:

| Statistic | Accepts | Native | Target |
|---|---|---|---|
| `responseTime.*` | `ns` `us` `ms` `s` `min` `h` | milliseconds | `Int` — the DSL entry point's type |
| `groupCumulatedResponseTime.*` | `ns` `us` `ms` `s` `min` `h` | milliseconds | `Int` — the same |
| `failedRequests.percent` | `%` `1` | percent, 0..100 | `Double` |
| `allRequests.count`, `failedRequests.count` | `{request}` | count | **`Long`** |
| `requestsPerSec` | `{request}/s` | per second | `Double` |
| — | `By` `KiBy` `MiBy` `GiBy` `{iteration}` `{iteration}/s` `{vu}` | — | not reachable through any assertable statistic |

**Invariants**:

- **One row per statistic.** Why the four durations join the two `Accepts` cells rather than
  taking a row of their own, which is what #74's wording proposes: § *Units* opens by stating
  units are per statistic, and a statistic in two rows contradicts it. Recorded in
  [spec.md](spec.md) § *Decisions*.
- **The last row is derived**: the enumeration in § *Units* minus every unit a statistic reaches.
  17 − 10 = 7, and the seven are exactly the ones listed ([research.md](research.md) R7). Adding
  a unit to the format stays one decision, not two.
- **The `Target` column is the DSL entry point's type**, and says so. Five rows, five types, each
  checkable against `AssertionBuilders.scala` at the version the cell is dated to.

---

## 5. A probe

**What it is**: a predicate this contract says renders, or says does not, paired with the reason
the gate must give. The gate's only means of showing a rule still fires — the corpus cannot,
because it holds only documents that render.

| | |
|---|---|
| **Rejection probe** | `(predicate, expected_message)` in `PREDICATE_PROBES`; fails if the message is absent |
| **Rendering probe** | `predicate` in `PREDICATE_RENDERS`; fails if any reason is produced |
| **Exercises** | `predicate_why` — the same function the corpus is judged by, never a copy |

**Fifteen added**, each the sole catcher of one regression; the table is in
[research.md](research.md) R6. It said ten until implementation showed the two count rows sit in
different shapes and need a probe each, and eleven until code review found the rule was a range as
well as a divisibility and that the stated arithmetic was unreachable past fifteen significant
digits. **No new message string**: every refusal comes from a code path
that already exists (R5).

---

## 6. A floor

**What it is**: the exact probe count a class must meet. A pruned probe table reports no failures
and reads exactly like a sound one, so each floor is exact and adding a probe means raising it.

| class | today | after #73 | after #59 | after #74 |
|---|---|---|---|---|
| predicate rejection | 13 | **16** | **20** | **22** |
| predicate rendering | 16 | 16 | **18** | **22** |

The four selection and pairing floors — 9, 6, 4, 4 — are untouched.

---

## 7. The DSL entry point *(read, not written)*

**What it is**: the Gatling constructor a rendered predicate would pass through, and the source of
the `Target` column. Read **2026-09-01** at `gatling-core` / `gatling-core-java` **3.13.5** and
`gatling-shared-model_2.13` **0.0.11**.

| entry point | target type | reaches |
|---|---|---|
| `AssertionWithPathAndTimeMetric.{min,max,mean,stdDev,percentile}` | `Int` | `responseTime.*`, `groupCumulatedResponseTime.*` |
| `AssertionWithPathAndCountMetric.count` | **`Long`** | `allRequests.count`, `failedRequests.count` |
| `AssertionWithPathAndCountMetric.percent` | `Double` | `failedRequests.percent` |
| `AssertionWithPath.requestsPerSec` | `Double` | `requestsPerSec` |

The type is consumed at the boundary — `lt(threshold: T)` calls `numeric.toDouble(threshold)` —
and the `Assertion` it produces carries a `double` in every `Condition`. So a renderer constructing
the model itself never passes through the typed builder. § *Units* records that and **does not**
relax the rule for it: reach is a property of the target, not of how a renderer is built
([spec.md](spec.md) § *Decisions*).
