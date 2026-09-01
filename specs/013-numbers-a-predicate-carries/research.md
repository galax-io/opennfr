# Phase 0 — Research: Which Numbers a Predicate May Carry

**Feature**: [spec.md](spec.md) | **Date**: 2026-09-01 | **Read at**: `906f8d2`

Eight questions. Two changed a requirement's implementation, and one of those would have
reintroduced a smaller copy of the defect #73 is about.

---

## R1 — The corrected percentile test must use `re.fullmatch`, not `re.match`

**Question**: the helper becomes the row's pattern. Which Python call applies it?

**Finding**: `re.match` is wrong, and wrong in the same direction as the bug being fixed.

Python's `$` matches at the end of the string **or immediately before a trailing newline**.
ECMA-262's `$` — the dialect JSON Schema `pattern` is defined in, and therefore the dialect the
row's pattern is written in — matches only at the very end. So with the row's pattern carried
verbatim:

| input | `re.match` | `re.fullmatch` | what the schema does |
|---|---|---|---|
| `p95`, `p99.9`, `p1`, `p10`, `p0.1`, `p99.99` | accepts | accepts | accepts |
| `p100`, `p999`, `p1234`, `p.5`, `p1.`, `p` | rejects | rejects | rejects |
| `"p95\n"` | **accepts** | rejects | rejects |

`re.match` would leave the gate admitting one shape the row and the schema reject — a strictly
smaller instance of #73, installed by the commit that closes it.

**Decision**: `re.fullmatch(PERCENTILE, a) is not None`, with `PERCENTILE` holding the row's
pattern **character-for-character including its `^` and `$`**. The anchors are redundant under
`fullmatch` and are kept anyway: the value of this constant is that a reader can hold it beside
the row and beside `$defs/aggregation` and see three identical strings. Stripping the anchors to
tidy it would make the three no longer comparable by eye, which is the whole mechanism.

**Alternatives rejected**: `re.match` with the pattern (above). `re.fullmatch` with the anchors
stripped — same behaviour, loses the by-eye comparison. Reading the pattern out of the schema at
runtime — `README.md` § *How these tables are applied* states this section "never reads the
schema", and the gate says so in a comment above its own heredoc.

**Consequence**: `import re` is added to the Gatling heredoc, which today imports only
`glob`, `sys`, `Fraction`, `identity` and `yaml`.

---

## R2 — The arithmetic rule can be stated without obliging anyone to keep the source text

**Question**: FR-008 says exact decimal arithmetic on the value `threshold` denotes. A renderer
that parsed into a double has lost the decimal. Is the rule implementable, or does it oblige a
renderer to read raw document text — which FR-010 forbids?

**Finding**: implementable, and the escape is a guarantee rather than a convention. Converting the
double back to its **shortest round-tripping decimal** and computing exactly from there recovers
the literal's value for any literal of at most fifteen significant digits.

Spot-checked over 20 000 random 15-significant-digit literals with exponents in `1e-6 … 1e3`:
`Fraction(str(float(lit))) != Fraction(lit)` in **0** cases. And on the values the rule is about:

| literal | parsed | shortest decimal | exact value recovered |
|---|---|---|---|
| `1.001` | `1.001` | `1.001` | `1001/1000` — yes |
| `1.0010` | `1.001` | `1.001` | same value — yes |
| `0.5` | `0.5` | `0.5` | `1/2` — yes |
| `1.23456789012345` | — | same | yes |

**Decision**: state the rule as *exact decimal arithmetic on the value the threshold denotes*, and
add one sentence naming the recovery route and the precision it holds to. The gate's
`Fraction(str(p["threshold"]))` **is** that route; FR-013's comment says so.

**Alternatives rejected**: "on the literal as written" — obliges a renderer to retain source text,
which JSON and YAML parsers discard (FR-010). Naming shortest-round-trip as *the* rule rather than
as a conformance route — Java's `Double.toString` did not always produce the shortest decimal
before JDK 19, so a Scala renderer's answer would depend on its JDK; the rule is about the value,
and the route is one way to reach it.

**Checked and not a problem**: `yaml.safe_load("5e2")` returns the **string** `'5e2'`, because
YAML 1.1 requires a `.` before an exponent. Such a document is rejected by the schema's
`"type": "number"` before any of this applies, in a different section of the same gate. Noted so
the next reader does not rediscover it as a defect of this rule.

---

## R3 — Every DSL entry point's target type, re-read here

**Question**: #59's closing section reports the `Int` is the builder's, not the target's. True at
the versions this repository names, and what are the other four?

**Finding**: true, and one published cell is wrong. Read **2026-09-01** from the local Coursier
cache — `gatling-core` and `gatling-core-java` **3.13.5**, `gatling-shared-model_2.13` **0.0.11**,
the release Gatling 3.13.5 pins.

`AssertionBuilders.scala`, read from the sources jar:

| entry point | returns |
|---|---|
| `AssertionWithPathAndTimeMetric.{min,max,mean,stdDev,percentile}` | `AssertionWithPathAndTarget[Int]` |
| `AssertionWithPathAndCountMetric.count` | `AssertionWithPathAndTarget[`**`Long`**`]` |
| `AssertionWithPathAndCountMetric.percent` | `AssertionWithPathAndTarget[Double]` |
| `AssertionWithPath.requestsPerSec` | `AssertionWithPathAndTarget[Double]` |

And the type is consumed at the boundary — `AssertionWithPathAndTarget[T: Numeric]`:

```scala
def lt(threshold: T): Assertion = next(Condition.Lt(numeric.toDouble(threshold)))
```

`javap` on the model confirms the other side: `Condition$Lt.value()` and `Condition$Lte.value()`
are `public double`, and `Condition$Between` carries two. `javap` on
`io.gatling.javaapi.core.Assertion$WithPathAndTimeMetric` shows the Java DSL is Int-typed too —
`max()` returns `WithPathAndTarget<Integer>`, where `T extends Number`.

**Decision**: the `Int` is the type of the two DSL entry points, both of them, and the count cell
must read `Long` (FR-017d). The whole-number rule stops being conditioned on the word `Int`
(FR-017e) — otherwise correcting the cell drops counts out of the rule.

**Alternatives rejected**: relaxing the rule for a renderer that emits the model directly — makes
reach a property of how a renderer is built; argued in [spec.md](spec.md) § *Decisions*. Carrying
#59's reading with attribution instead of re-reading — the jars are here, and Principle IV prefers
a dated read.

---

## R4 — The four factors, exactly

**Question**: what does `TIME` become, and does any conversion need rounding?

**Finding**: none does. Every factor is exact in `Fraction`:

```python
TIME = {"ns": Fraction(1, 1000000), "us": Fraction(1, 1000), "ms": Fraction(1),
        "s":  Fraction(1000),       "min": Fraction(60000),  "h":  Fraction(3600000)}
```

Simulated against the corrected `predicate_why`:

| predicate | converted | verdict |
|---|---|---|
| `2000000 ns` | 2 ms | renders |
| `1500000 us` | 1500 ms | renders |
| `2 min` | 120000 ms | renders |
| `1 h` | 3600000 ms | renders |
| `1500 ns` | 3/2000 ms | `threshold 1500 ns is 3/2000 for responseTime.percentile, whose target is an integer` |
| `1 us` | 1/1000 ms | same form |

**Decision**: the four factors go in `TIME`, which both duration statistics already share, so
`groupCumulatedResponseTime.*` gains them without a second table.

---

## R5 — Every new refusal comes from an existing code path

**Question**: do the new probes need new messages? FR-003 forbids a message written specially for
out-of-range percentiles.

**Finding**: no new message is needed anywhere. Simulated:

| probe | message, from which existing path |
|---|---|
| `aggregation: p999` | `aggregation p999 over a metric has no equivalent` — the row lookup, because `percentile()` now returns false and the key falls through |
| `aggregation: p100` | same form |
| `threshold: 1500, unit: ns` | the whole-number branch |
| `aggregation: count, threshold: 20.5, unit: {request}` | the whole-number branch — `threshold 20.5 {request} is 41/2 for allRequests.count, whose target is an integer` |

The last line is worth stating plainly: the gate's existing wording — *"whose target is an
integer"* — stays true and correct under `Long`. The gate reasoned over an `integral` flag and
never over the word `Int`, so **the gate was right and only the page was wrong**. FR-017e makes
the page say what the gate already does.

**Decision**: no message changes. FR-003, FR-015 and FR-024 are satisfied by touching no strings.

---

## R6 — Which probes, and what the floors become

**Question**: the floors are exact and adding a probe means raising the number beside it. Which
probes, and to what?

**Finding**: nine probes, each the sole catcher of one regression — the standard the section's own
comment sets.

| # | probe | direction | sole catcher of |
|---|---|---|---|
| 1 | `aggregation: p999` | rejection | the pattern's `\d{1,2}` widening, or the old `isdigit()` helper returning |
| 2 | `aggregation: p.5` | rejection | the integer part being made optional |
| 3 | `aggregation: "p95\n"` | rejection | `re.fullmatch` becoming `re.match` (R1) |
| 4 | `threshold: 1.001, unit: s` | rendering | the exact arithmetic becoming a double multiplication |
| 5 | `aggregation: count, threshold: 20.5` | rejection | `allRequests.count`'s integral flag being flipped |
| 5b | the same with `bad: {error.type: "*"}` | rejection | `failedRequests.count`'s integral flag being flipped |
| 5c | `threshold: ExactFloat("1.0000000000000001"), unit: s` | rejection | the literal being read off the double again |
| 5d | `threshold: 1e19, unit: {request}` | rejection | the `Long` bound being dropped |
| 5e | `threshold: 2147483647, unit: ms` | rendering | the `Int` bound going off by one |
| 5f | `threshold: 597, unit: h` | rejection | the range being checked before the conversion rather than after |
| 6–9 | `2000000 ns`, `1500000 us`, `2 min`, `1 h` | rendering | each of the four new factors being deleted |
| 10 | `threshold: 1500, unit: ns` | rejection | the whole-number rule stopping at `ms`/`s` |

Floors, per commit — each is exact, and each commit is green on its own:

| after | predicate rejection | predicate rendering |
|---|---|---|
| today | 13 | 16 |
| #73 | **16** | 16 |
| #59 | **20** | **18** |
| #74 | **22** | **22** |

**Decision**: fifteen probes, floors raised in the commit that adds them.

**Corrected twice.** First during implementation, then by code review; both corrections are in
the direction of a rule this milestone claimed and did not check.

Review added four. The whole-number rule is a **range** and not only a divisibility — a converted
threshold can be whole and still be one no target holds, and `h`/`min` make that ordinary to write
(`597 h` is 2 149 200 000 ms against an `Int` that stops at 2 147 483 647). And the arithmetic
`README.md` now states is about the value the literal denotes, which `Fraction(str(float))` cannot
recover past fifteen significant digits: `1.0000000000000001 s` arrived as `1.0` and rendered as a
whole 1000 ms, which is the rule refusing a document the gate blessed. Probes 5c–5f close both, and
`LOADER`'s own check closes the wiring no probe can reach.

**Corrected during implementation.** This table said ten, with one probe for "either count row".
The two count rows live in **different shapes** — `allRequests.count` under `requests`,
`failedRequests.count` under `fraction` — so one probe reaches one row and leaves the other exactly
as unguarded as it was. T025's revert set caught it: `failedRequests.count`'s flag flipped green
with the single probe in place. Probe 5b is the fix, and the rejection floors move to 18 and 19.

**Alternative rejected**: one probe for #73 instead of three. FR-002 asks for "at least one", and
one would leave two distinct regressions — a widened integer part and a swapped match call — each
one edit away from passing green.

---

## R7 — The unreachable row is still derived

**Question**: FR-021 requires the last row stay the enumeration minus what a statistic reaches.
Does the arithmetic still work after four units move?

**Finding**: yes. Seventeen units in `$defs/unit`. Reached after this milestone:

| statistic | units |
|---|---|
| `responseTime.*`, `groupCumulatedResponseTime.*` | `ns` `us` `ms` `s` `min` `h` |
| `failedRequests.percent` | `%` `1` |
| `allRequests.count`, `failedRequests.count` | `{request}` |
| `requestsPerSec` | `{request}/s` |

Ten distinct. 17 − 10 = **7**: `By`, `KiBy`, `MiBy`, `GiBy`, `{iteration}`, `{iteration}/s`, `{vu}`
— exactly FR-020's list, and the existing reason holds for all seven (no statistic carries bytes;
nothing counts iterations or virtual users).

---

## R8 — `examples/` needs no change, and that is checkable rather than assumed

**Question**: FR-026 and SC-011 require the corpus byte-identical. Is any published predicate
affected?

**Finding**: no. Enumerated from the four documents rather than assumed — the corpus is ten
predicates, and across all of them:

| axis | every value the corpus uses |
|---|---|
| `aggregation` | `p50`, `p95`, `p99`, `max`, `count`, `rate` |
| `unit` | `ms`, `s`, `%`, `{request}`, `{request}/s` |
| `threshold` | `3`, `5`, `20`, `200`, `500`, `1000` |

No out-of-range percentile, so #73 refuses nothing published. Every threshold is a whole number
written in a whole unit, so the two arithmetics agree on all six and #59 changes no verdict. No
duration unit outside `ms` and `s`, so #74 admits something no document yet says. Every change in
this milestone either refuses something no document says, or admits something no document says.

**Decision**: `examples/` is untouched, and quickstart step 1 checks it with `git diff --stat`
rather than by reading.
