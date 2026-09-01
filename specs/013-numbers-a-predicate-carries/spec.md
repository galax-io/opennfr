# Feature Specification: Which Numbers a Predicate May Carry

**Feature Branch**: `013-numbers-a-predicate-carries`

**Created**: 2026-09-01

**Status**: Draft

**Input**: User description: "https://github.com/galax-io/opennfr/milestone/11" — milestone **v0.9.0**, three open issues: #73, #59 and #74, in that order. A fourth, #94, was in this milestone and landed on `main` at `906f8d2` before this specification was written; it is not in scope here.

**Scope note**: One question runs through all three: *which numbers may a predicate carry, and which artifact decides?* Three axes answer it today and they answer differently. The gate calls `p100` and `p999` assertable where the row and the schema reject both (#73). The whole-number threshold rule is stated without an arithmetic model, so two conforming renderers disagree about `1.001 s` (#59). And the Units table calls `ns`, `us`, `min` and `h` unreachable in a row that groups them with seven units that genuinely are (#74). A renderer written from one artifact refuses what a renderer written from another accepts.

Nothing here is about a report, a verdict, or anything a consumer displays. A renderer turns a requirement document into a target's assertions, and this milestone stays inside that.

**No term is added and no term is renamed**, so Principle I asks nothing of this milestone beyond leaving `GLOSSARY.md` alone. `examples/` does not change: every published document is already renderable under every answer below, and stays so. Two files change: `README.md` and `scripts/verify.sh`. The schema does not, and *Decisions* records the two independent reasons it does not.

**The format is not narrowed and not widened by #73 and #59.** `p999` is already schema-invalid; `1.001 s` is already schema-valid. Both issues are about artifacts disagreeing over documents whose validity is already settled. #74 alone changes which schema-valid documents may be published: four units move from **cannot** to **can**.

#73 comes first because it is the cheapest and touches one line of rule. #59 comes next because it decides how a conversion is computed before more conversions exist. #74 comes last because it adds the conversions that decision governs.

## Decisions

### Session 2026-09-01

- **Q**: #59 offers two closes — state the arithmetic model in the contract, or bound `threshold`'s precision in the schema. Which? → **A**: **State the model; the schema does not change.** Two independent reasons, and either alone would settle it. `GLOSSARY.md` § *aggregation* already rejected narrowing the schema to a target's reach, in those words, when #57 proposed it for `count` and `rate`; a precision bound on `threshold` exists only because one target's target type is an `Int`, which is the same move. And the bound does not work: `multipleOf: 0.001` **rejects** `1.001`, `1.003` and `1.005` under `jsonschema` 4.26.0, because `multipleOf` is itself evaluated in binary floating point. The schema option reproduces the exact defect it was proposed to fix, one layer down.

- **Q**: "Exact decimal arithmetic on the literal **as written**" would oblige a renderer to read raw document text, which JSON and YAML parsers discard. Is that the rule? → **A**: **No — the rule is about the value the literal denotes, not the characters.** A renderer must compute with the decimal value `threshold` denotes rather than with the binary double nearest to it. A renderer that has already parsed into a double conforms by recovering the shortest decimal that round-trips that double and computing exactly from there, which is exactly the literal's value for any literal of at most fifteen significant digits — the classic round-trip guarantee, and far more precision than a threshold carries. This is what makes the gate's `Fraction(str(...))` correct rather than accidental, and it is statable in one sentence without obliging anyone to keep the source text.

- **Q**: #73 says the helper becomes the row's pattern. Where does the pattern then live — one copy read from the schema at runtime, or a literal in the gate that the row names? → **A**: **A literal in the gate, with the row named as its source, plus the rejection probe.** The milestone says so, and the alternative contradicts a published property: `README.md` § *How these tables are applied* states that the gate "enforces the restriction on `examples/` and never reads the schema". The residual — the schema could widen and leave both the row and the gate stale — is recorded under *Out of Scope* rather than solved here.

- **Q**: #59's closing section is confirmed — the `Int` is the DSL builders' type parameter, consumed by `numeric.toDouble` at the boundary, and the `Assertion` a renderer may construct itself carries a `double`. What does § *Units* do about it? → **A**: **Narrow the attribution; change no rule.** The table stops calling the `Int` a property of the target and says it is the type of the two DSL entry points that reach it, sourced to the re-read. The whole-number rule bites exactly as it does today. The alternative — saying the rule binds a DSL renderer and not a model-emitting one — would make **reach depend on how a renderer is built** rather than on what Gatling can assert, and these tables are about the target. That is a change to what the section is, not to what it says.

- **Q**: #74 says "splitting the row in two", which would give the four durations a row of their own. Is that the shape? → **A**: **No — the two duration statistics' `Accepts` cells grow, and the unreachable row shrinks.** § *Units* opens by stating that units are per statistic, and a statistic appearing in two rows contradicts the sentence the table is organised around. The effect is the one #74 asks for — four units move, seven stay — and the unreachable row stays derived, which the issue's shape would also have preserved but at the cost of the table's own invariant.

- **Q**: The re-read also showed § *Units* calls the count target an `Int` where the DSL says `Long`. No issue mentions it. Own issue, or here? → **A**: **Here, inside #59, on the maintainer's call — and it turns out not to be separate work at all.** FR-017 restates what the `Target` column *means*; the count cell is wrong under the new meaning as much as the old, so a correct FR-017 cannot leave it. Beyond the cell, the whole-number rule is written as "where the target is an `Int`", so correcting the cell alone would silently exempt counts from the rule — and nothing probes the count rows' integrality, so neither today's error nor that regression is visible to the gate. One cell, one rule and one probe, all downstream of the sentence #59 asks us to write. AGENTS.md's "does not ride along" governs work that is *not* one of the milestone's issues; this is what doing one of them correctly entails.

## What the milestone counts, and what is actually true

Read at `906f8d2`. Every number below was reproduced rather than quoted.

### #73 — the helper admits five shapes the row rejects, not four

`scripts/verify.sh:634` is `def percentile(a): return a.startswith("p") and a[1:].replace(".", "", 1).isdigit()`. Against the row's `^p\d{1,2}(\.\d+)?$`:

| aggregation | helper | row and schema |
|---|---|---|
| `p95`, `p99.9`, `p1`, `p10`, `p0.1`, `p99.99` | accepts | accepts |
| `p100` | **accepts** | rejects |
| `p999` | **accepts** | rejects |
| `p1234` | **accepts** | rejects |
| `p.5` | **accepts** | rejects |
| `p1.` | **accepts** | rejects |
| `p` | rejects | rejects |

The issue names four. `p1.` is a fifth: `"1.".replace(".", "", 1)` is `"1"`, and `"1".isdigit()` is true. It is listed because a fix written to the issue's four could still admit it, and because it is the one a careless anchor-less pattern would also miss.

### #59 — the two arithmetics, and the escape that does not work

| document | exact decimal | IEEE-754 double |
|---|---|---|
| `threshold: 1.001, unit: s` | `1001` → renders | `1000.9999999999999` → refused |
| `threshold: 1.003, unit: s` | `1003` → renders | `1002.9999999999999` → refused |
| `threshold: 1.005, unit: s` | `1005` → renders | `1004.9999999999999` → refused |
| `threshold: 0.5, unit: s` | `500` → renders | `500.0` → renders |
| `threshold: 0.5, unit: ms` | `1/2` → refused | `0.5` → refused |

And the schema escape, tested rather than assumed:

| constraint | `1.001` | `1.003` | `1.005` | `0.5` | `500` |
|---|---|---|---|---|---|
| `multipleOf: 0.001`, `jsonschema` 4.26.0, Draft 2020-12 | **rejected** | **rejected** | **rejected** | accepted | accepted |

### #59, closing section — the `Int` target is the builder's, and it was re-read here

#59 reports that the `Int` the whole-number rule rests on is a property of Gatling's builder entry
point rather than of the assertion it produces. **Re-read locally 2026-09-01** from the Coursier
cache — `gatling-core` and `gatling-core-java` **3.13.5**, `gatling-shared-model_2.13` **0.0.11**,
the release 3.13.5 pins — rather than carried, because the jars are present:

| read | says |
|---|---|
| `AssertionBuilders.scala`, `gatling-core` 3.13.5 sources | `AssertionWithPathAndTimeMetric.{min,max,mean,stdDev,percentile}` return `AssertionWithPathAndTarget[Int]` |
| the same file | `AssertionWithPathAndTarget[T: Numeric].lt/lte/gt/gte/is` call `numeric.toDouble(threshold)` and build `Condition.Lt(Double)` — the `Int` is consumed at the boundary |
| `javap` on `Condition$Lt`, `Condition$Lte` | `public double value()` |
| `javap` on `Condition$Between` | `public double lowerBound()`, `public double upperBound()` |
| `javap` on `Assertion$WithPathAndTimeMetric`, `gatling-core-java` 3.13.5 | `max()` returns `WithPathAndTarget<Integer>` — the Java DSL is Int-typed too |

So the constraint is real for anyone going through either DSL, and absent for anyone constructing
`Assertion(path, target, Condition.Lt(0.5))` directly, which is what a renderer emitting
`Iterable[Assertion]` does. The issue's reading holds. What the format does about it is Q1.

The same read turned up something no issue mentions, and it is **not** separable from FR-017.
Every DSL entry point, read from the same file:

| entry point | target type |
|---|---|
| `AssertionWithPathAndTimeMetric.{min,max,mean,stdDev,percentile}` | `Int` |
| `AssertionWithPathAndCountMetric.count` | **`Long`** |
| `AssertionWithPathAndCountMetric.percent` | `Double` |
| `AssertionWithPath.requestsPerSec` | `Double` |

§ *Units* calls the target of `allRequests.count` and `failedRequests.count` an **`Int`**. One cell,
wrong under the reading it has today and wrong under the reading FR-017 gives it — the column is
about to be restated as *the type of the DSL entry point*, and for count that type is `Long`.
Correcting the column and leaving that cell would make FR-017's own new sentence false in the same
table it is written into.

And the correction cannot be made alone, which is the part that matters. The whole-number rule is
worded **"Where the target is an `Int`"**. Change the cell to `Long` without touching the rule and
counts fall out of the rule's scope: `threshold: 20.5, unit: {request}` becomes renderable, and the
gate — which is right, and reasons over an `integral` flag rather than over the word `Int` —
would then disagree with the page. So the rule has to stop being about one Scala type and start
being about the property it was always testing.

Third, nothing probes it. `PREDICATE_PROBES` carries two fractional-threshold probes, `0.1 ms` and
`0.05` in `1`, and neither reaches a count row. Both count rows carry `integral=True` in the gate's
table, and flipping either to `False` leaves the gate **green** — a rule nothing checks, which is
Principle III's own failure class sitting under the paragraph this milestone is rewriting.

### #74 — the four durations, and the rule that still governs them

| written | native (ms), exact | whole? |
|---|---|---|
| `2000000 ns` | `2` | yes — renders |
| `1500000 us` | `1500` | yes — renders |
| `2 min` | `120000` | yes — renders |
| `1 h` | `3600000` | yes — renders |
| `1500 ns` | `3/2000` | no — refused by the whole-number rule, with the right reason |
| `1 us` | `1/1000` | no — refused by the whole-number rule, with the right reason |

The last two are why this is not an exception to the whole-number rule: the four units need to stop being refused *before* that rule gets to run, and then be refused by it where it applies.

## User Scenarios & Testing *(mandatory)*

The reader throughout is the author of the first OpenNFR renderer, turning a requirement document into a target's assertions. The three stories are three things that reader cannot learn from the repository without getting a different answer depending on which artifact they open.

### User Story 1 - One rule decides what a percentile is (#73, Priority: P1)

A renderer author reads the Aggregations row, sees `^p\d{1,2}(\.\d+)?$`, and reimplements it. They then check their reading against `scripts/verify.sh`, which § *Gatling* calls "the only implementation" of these tables — and find a strictly wider test. On `p999` the gate's reach section reports assertable while its schema section reports the document invalid: two sections of one run give opposite answers about one predicate.

After this story the helper is the row, the row is the helper, and a probe fails the gate if they part again.

**Why this priority**: cheapest of the three, and the only one that leaves the repository actively contradicting itself within a single run. It is also the one that damages the artifact a second implementer checks their reading against.

**Independent Test**: run the row's pattern and the gate's percentile test over `p95`, `p99.9`, `p0.1`, `p99.99`, `p100`, `p999`, `p1234`, `p.5`, `p1.` and `p`. The two agree on all ten. Then delete the fix and the gate goes red rather than quiet.

**Acceptance Scenarios**:

1. **Given** the corrected gate, **When** a predicate carries `aggregation: p999`, **Then** the reach section refuses it, and the reason is the one the row's own lookup gives — that the aggregation over that shape has no equivalent — not a message written specially for percentiles.
2. **Given** the corrected gate, **When** a predicate carries `p100`, `p1234`, `p.5` or `p1.`, **Then** each is refused for the same reason.
3. **Given** the corrected gate, **When** a predicate carries `p95`, `p99.9`, `p1`, `p10`, `p0.1` or `p99.99`, **Then** it renders, and every published document still renders.
4. **Given** the helper reverted to its `isdigit()` form, **When** the gate runs, **Then** it FAILs and names the probe that caught it.
5. **Given** a reader at the gate's percentile test, **When** they ask where the pattern came from, **Then** the site names the reach row it implements.

---

### User Story 2 - The conversion has one arithmetic (#59, Priority: P2)

The same author reaches the whole-number rule. It forbids rounding, on the ground that rounding "moves the bar the author wrote". They implement it the obvious way — parse the YAML number, multiply by the factor, test for a whole number — and their renderer refuses `1.001 s`, which the reference gate accepts. Neither is wrong under the published text: `threshold` is a bare number with no stated precision, the conversion is stated as a factor, and "whole number" is stated with no arithmetic model at all. So a rule whose entire purpose is that being wrong here moves the bar silently is itself the place two conforming renderers disagree.

After this story the contract says which arithmetic, says what a renderer that has already parsed into a double must do, and the gate's round-trip is the rule rather than an implementation detail nobody else knows to reproduce.

**Why this priority**: second because #74 adds four conversions, and adding conversions before the arithmetic governing them is settled multiplies the disagreement by four. It is the milestone's only `severity:high` issue.

**Independent Test**: implement the whole-number rule twice from the corrected text alone — once with exact decimal arithmetic, once starting from a parsed double and following the conformance sentence. Both accept `1.001 s`, `1.003 s`, `1.005 s` and `0.5 s`; both refuse `0.5 ms`.

**Acceptance Scenarios**:

1. **Given** the corrected § *Units*, **When** a renderer author asks how a threshold is converted, **Then** the text names exact decimal arithmetic on the value the literal denotes, and says binary floating-point multiplication is not it.
2. **Given** a renderer that parses `threshold` into a binary double, **When** its author reads the same text, **Then** they can conform without keeping the document's source text, and the text says how.
3. **Given** the gate, **When** a reader reaches the `Fraction(str(...))` round-trip, **Then** a comment names the rule it implements, so a future edit to a plain float multiplication is visibly a change to the rule.
4. **Given** the corrected gate, **When** a predicate carries `threshold: 1.001, unit: s`, **Then** it renders — and the probe that says so fails if the arithmetic is changed to a double.
5. **Given** the corrected gate, **When** a predicate carries `threshold: 0.5, unit: ms`, **Then** it is refused, and the reason still names the value, the statistic and the integer target.
6. **Given** the schema, **When** a reader looks for a precision constraint on `threshold`, **Then** there is none, and the reason a bound was rejected is on the record.
7. **Given** the corrected § *Units*, **When** a reader reads the `Target` column, **Then** every cell is the type the corresponding DSL entry point returns — `Long` for the two count rows — and the column says which of the two it is describing.
8. **Given** the corrected whole-number rule, **When** a predicate carries `aggregation: count, threshold: 20.5, unit: {request}`, **Then** it is refused, exactly as it is refused today, and the rule that refuses it no longer names a Scala type the count rows do not have.
9. **Given** either count row's integral flag flipped in the gate, **When** the gate runs, **Then** it FAILs — which it does not do today.

---

### User Story 3 - The Units row says only what is true (#74, Priority: P3)

The author now wants a sub-millisecond budget for a fast internal service, and the outer bound of a soak run in hours. Both units are in the format's closed enumeration. The reach section refuses both, in a row that gives one reason for eleven units — and the reason is true of seven. `responseTime.*` is a duration statistic whose native unit is milliseconds; `1500000 us` is exactly 1500 ms and `1 h` is exactly 3600000 ms, by the same arithmetic that already converts `s`.

After this story the four durations are reachable, subject to the whole-number rule that governs every other duration, and the unreachable row holds the seven units for which its reason holds.

**Why this priority**: last because it is the only one of the three that changes which documents may be published, and it is written from #59's answer. Its refusals are wrong rather than merely under-described, but nothing in the corpus depends on them.

**Independent Test**: write the four documents in the table above and the two sub-millisecond ones, and run each through the gate. The first four render, the last two are refused by the whole-number rule and by nothing else.

**Acceptance Scenarios**:

1. **Given** the corrected § *Units*, **When** a reader asks which units a duration statistic accepts, **Then** the answer is the six duration units, for both `responseTime.*` and `groupCumulatedResponseTime.*`.
2. **Given** the corrected § *Units*, **When** a reader reads the unreachable row, **Then** it holds exactly the seven units no statistic reaches, and its reason is true of all seven.
3. **Given** the corrected § *Units*, **When** a reader checks the unreachable row against the enumeration in § *Units* above, **Then** it is still the enumeration minus every unit a statistic reaches — the row is still derived, and adding a unit to the format is still one decision and not two.
4. **Given** the corrected gate, **When** a predicate carries `1500000 us`, `2 min`, `1 h` or `2000000 ns` on a duration statistic, **Then** it renders.
5. **Given** the corrected gate, **When** a predicate carries `1500 ns` or `1 us`, **Then** it is refused because the converted value is not whole, and the message names the converted value and the statistic — not "not a unit of".
6. **Given** any one of the four new factors deleted, **When** the gate runs, **Then** it FAILs, because each has a rendering probe of its own.

### Edge Cases

- **A percentile the pattern admits but no target computes.** `p0.1` and `p99.99` are inside the row and inside the schema. Nothing changes for them: they render, as they do today.
- **`p100`.** Refused, and § *Aggregations* already says why it needs no row of its own — the quantity it names is `max`. This milestone does not add one.
- **A threshold with more than fifteen significant digits.** Outside the round-trip guarantee the conformance sentence rests on. No threshold carries one, and the rule is stated about the value the literal denotes, so such a literal is governed by the same rule; only the double-parsing recovery route stops being guaranteed. Recorded, not legislated.
- **`threshold` in scientific notation.** `5e2` denotes 500 and converts like `500`. The rule is about the value, not the spelling, so no case is added.
- **Non-finite thresholds.** Already refused before this section is reached: the gate rejects YAML that cannot map onto JSON, non-finite numbers included.
- **A new duration unit added to the format later.** The unreachable row stays derived, so whether it appears there follows from whether a statistic reaches it, and the gate's factor table is where that is said.
- **A count threshold above what an `Int` holds.** `Long` admits it and `Int` does not, but nothing in the format, the gate or the assertion model bounds a threshold's magnitude — and the model carries a `double` regardless. So the cell's correction changes which type is named and nothing else; no magnitude rule is added, and none is implied.
- **A unit reachable for one statistic and not another.** Unchanged and still load-bearing: `%` is a unit of `failedRequests.percent` and not of `responseTime.percentile`, and the probe that says so stays.

## Requirements *(mandatory)*

### Functional Requirements

**#73 — the percentile test is the row**

- **FR-001**: The gate's percentile test MUST admit exactly the aggregations `^p\d{1,2}(\.\d+)?$` admits, and no others.
- **FR-002**: The gate MUST carry at least one rejection probe for an aggregation the previous helper admitted and the row rejects, asserting the reason the gate gives.
- **FR-003**: That reason MUST be produced by the existing aggregation-row lookup — the message that names the aggregation and the shape — and MUST NOT be a message written specially for out-of-range percentiles. A second message would be a second rule.
- **FR-004**: The site carrying the pattern MUST name the reach row it implements, so a reader can see the two are one rule and not two that happen to agree.
- **FR-005**: `p95`, `p99.9`, `p1`, `p10`, `p0.1` and `p99.99` MUST continue to render, and the existing `p99.9` rendering probe MUST survive.
- **FR-006**: The predicate rejection floor MUST rise by the number of probes added, so a later deletion of one is a red gate rather than a quiet one.

**#59 — the conversion has an arithmetic model**

- **FR-007**: `README.md` § *Units* (under § *Gatling*) MUST state the arithmetic by which a threshold is converted to a statistic's native unit, adjacent to the whole-number rule it governs.
- **FR-008**: That statement MUST be exact decimal arithmetic on the value `threshold` denotes, and MUST say that binary floating-point multiplication is not it.
- **FR-009**: It MUST tell a renderer that has already parsed `threshold` into a binary double how to conform without retaining the document's source text, and MUST state the precision bound that route rests on.
- **FR-010**: The statement MUST NOT oblige a renderer to read raw document text, because JSON and YAML parsers discard it and the format may not require a parser nobody has.
- **FR-011**: `schema/opennfr.io/v1/requirementset.schema.json` MUST NOT gain a precision constraint on `threshold`.
- **FR-012**: The reason a schema bound was rejected MUST be recorded where a future contributor proposing one will meet it, and MUST name both grounds: that it narrows the schema to one target's reach, and that `multipleOf` is itself evaluated in binary floating point and rejects the very values it was proposed to admit.
- **FR-013**: The gate's exact-arithmetic round-trip MUST carry a comment naming the rule it implements, so replacing it with a float multiplication reads as a change to the rule.
- **FR-014**: The gate MUST carry a rendering probe for a threshold on which exact and double arithmetic disagree — `1.001 s` — so the rule's whole subject is exercised rather than assumed.
- **FR-015**: The existing rejection probe for `0.1 ms` and its message MUST survive unchanged in meaning: a fractional native value is still unrenderable and still not rounded.
- **FR-016**: The predicate rendering floor MUST rise by the number of rendering probes added.
- **FR-017**: § *Units* MUST stop attributing the integer constraint to the statistic's target, and MUST say instead that it is the type of the two DSL entry points that reach that statistic.
- **FR-017a**: That statement MUST name what was read and carry the versions and the date — `gatling-core` and `gatling-core-java` 3.13.5, `gatling-shared-model_2.13` 0.0.11, 2026-09-01 — as § *Gatling*'s other sourced claims do.
- **FR-017b**: It MUST record that a renderer constructing the assertion model itself does not pass through those entry points, and MUST NOT thereby relax the rule: the whole-number rule binds every renderer after this milestone exactly as it binds them before it, and no document changes renderability on account of FR-017.
- **FR-017c**: The reason the rule was not relaxed MUST be on the record — that reach is a property of the target and not of how a renderer is built — so the next reader of this paragraph meets the argument rather than reopening it.
- **FR-017d**: The `Target` cell for `allRequests.count` and `failedRequests.count` MUST read `Long`, which is what `AssertionWithPathAndCountMetric.count` returns. Every other cell in that column MUST be checked against the same read and left correct: `Int` for the two duration statistics, `Double` for `failedRequests.percent` and `requestsPerSec`.
- **FR-017e**: The whole-number rule MUST stop being conditioned on the word `Int` and MUST be conditioned on the target being integral, so that it governs the count rows exactly as it governs the duration rows. No document may change renderability because of FR-017d: a fractional count threshold is unrenderable before this milestone and unrenderable after it.
- **FR-017f**: The gate MUST carry a rejection probe for a fractional threshold on a count row, and the predicate rejection floor MUST rise for it. Today both count rows carry an integral flag that no probe reaches, so either could be flipped and the gate would stay green.

**#74 — the Units row says what is true**

- **FR-018**: `ns`, `us`, `min` and `h` MUST be reachable through `responseTime.*` and `groupCumulatedResponseTime.*`, subject to the whole-number rule and to nothing else.
- **FR-019**: The gate's duration factor table MUST carry all six duration units with exact factors, so no conversion is approximate at the point it is computed.
- **FR-020**: The unreachable Units row MUST hold exactly `By`, `KiBy`, `MiBy`, `GiBy`, `{iteration}`, `{iteration}/s` and `{vu}`, and its stated reason MUST be true of all seven.
- **FR-021**: The unreachable row MUST remain derived — the enumeration in § *Units* minus every unit a statistic reaches — so adding a unit to the format stays one decision.
- **FR-022**: The `Accepts` cells of the `responseTime.*` and `groupCumulatedResponseTime.*` rows MUST become the six duration units, and the table MUST keep exactly one row per statistic. A separate row for the four newly reachable durations MUST NOT be added: § *Units* opens by stating that units are per statistic, and a statistic in two rows contradicts the sentence the table is organised around.
- **FR-023**: Each of the four newly reachable units MUST have a rendering probe of its own, so deleting any one factor fails the gate.
- **FR-024**: The gate MUST carry a rejection probe for a sub-millisecond value written in a newly reachable unit, and its reason MUST be the whole-number rule's — naming the converted value, the statistic and its integer target — and not "not a unit of".
- **FR-025**: The predicate rendering and rejection floors MUST rise by the number of probes added.

**Across all three**

- **FR-026**: `examples/` MUST NOT change. Every published document renders before and after.
- **FR-027**: No term is added, renamed or redefined, so `GLOSSARY.md` MUST NOT gain or lose an entry. Where a decision above bears on an existing entry, it is recorded at the entry's own *Rejected* line rather than as a new term.
- **FR-028**: Each of the three issues MUST land as one semantic commit carrying its own `Closes` link, in the order #73, #59, #74, behind the spec commit.
- **FR-029**: `bash scripts/verify.sh` MUST pass after each of the three commits, not only after the last.

### Key Entities

- **The percentile test**: the gate's decision that an aggregation is a percentile. One rule, currently stated twice — as a pattern in the row and the schema, and as a string test in the gate — and the two disagree.
- **The conversion**: threshold and unit reduced to a statistic's native unit. It has a factor, a result, and — until this milestone — no stated arithmetic.
- **The whole-number rule**: the constraint that a converted value against an integer target must be whole. Depends entirely on the conversion's arithmetic, which is why #59 precedes #74.
- **The Units reach table**: one row per statistic, plus one derived row for what nothing reaches. Its last row currently gives one reason for two different facts.
- **A probe**: a predicate the contract says renders, or says does not, paired with the reason. The gate's only means of showing that a rule still fires — the corpus cannot, because it holds only documents that render.
- **A floor**: the exact probe count each class must meet. Adding a probe means raising it, which is the intended cost of a new rule.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader can determine which aggregations are percentiles from any one of the schema, the reach row or the gate, and the three answers are identical across all ten aggregations in the divergence table above.
- **SC-002**: No single run of `scripts/verify.sh` reports one predicate as both assertable and invalid.
- **SC-003**: Two people implementing the whole-number rule from the corrected text alone — one with exact decimal arithmetic, one from a parsed double — accept and refuse the same documents, on all five rows of the arithmetic table above.
- **SC-004**: The corrected text answers "how is the conversion computed?" without the reader consulting `scripts/verify.sh`, and without them needing the document's source text.
- **SC-005**: Every unit in the format's closed enumeration is either reached by a named statistic or listed in the unreachable row with a reason true of it — seventeen units, no unit in both places and none in neither.
- **SC-006**: The four documents in the #74 table are publishable, and the two sub-millisecond ones are refused with the whole-number rule's reason.
- **SC-007**: Reverting any single rule this milestone changes — the percentile pattern, any one duration factor, or the exact arithmetic — turns the gate red, and the failure names the probe that caught it.
- **SC-008**: A contributor proposing a precision bound on `threshold` meets the recorded reason it was rejected before they change the schema.
- **SC-009**: Every cell of § *Units*' `Target` column matches what the correspondingly named DSL entry point returns, at the version the section is dated to — five rows, five types, checkable by one reader with one file open.
- **SC-010**: Flipping either count row's integral flag turns the gate red. It does not today.
- **SC-011**: `examples/` is byte-identical before and after the milestone.

## Assumptions

- **The milestone's order is the order.** #73, then #59, then #74, as the milestone states and for the reason it gives: #74 adds conversions that #59's answer governs.
- **The arithmetic model is stated, not enforced by the schema.** Settled on two independent grounds, both recorded in *Decisions*: narrowing the schema to a target's reach is already rejected in `GLOSSARY.md` § *aggregation*, and `multipleOf` reproduces the defect it would be added to fix.
- **Gatling's assertion types were re-read for this milestone, not carried.** The jars are in the local Coursier cache, so #59's closing claim was checked here on 2026-09-01 at `gatling-core` / `gatling-core-java` 3.13.5 and `gatling-shared-model_2.13` 0.0.11, and any text this milestone writes about them carries that version and that date. This is what Principle IV asks; carrying the issue's reading would have been the fallback, not the plan.
- **`http.client.request.duration` stays retired.** It is absent from the gate's addressable metrics and refused by the row that names it, and nothing here revisits that.
- **The reach section continues not to read the schema.** Recorded in *Decisions* Q3; it is why the percentile pattern is a literal in the gate rather than one read from the schema at runtime.
- **`p100` gains no row.** § *Aggregations* already explains why, and this milestone makes the gate agree with that explanation rather than changing it.
- **The gate's `str()` round-trip is retained, not replaced.** It already implements the rule FR-008 states; what it lacks is the sentence saying so.

## Dependencies

- **`README.md` § *Units* (under § *Gatling*)** — the reach table and the whole-number rule; changed by #59 and #74.
- **`README.md` § *Aggregations*** — the percentile row whose pattern #73 makes the gate agree with; read, not changed.
- **`scripts/verify.sh` § *Examples are assertable by Gatling*** — the only implementation of both tables; changed by all three.
- **`schema/opennfr.io/v1/requirementset.schema.json`** — `$defs/aggregation`'s pattern and `threshold`'s type; read by #73 and #59, changed by neither under the recommended answer to Q1.
- **`GLOSSARY.md` § *aggregation* and § *threshold and unit*** — carry the rejections #59's answer rests on; read, and extended only if FR-027's second sentence applies.

## Out of Scope

- **The schema, the row and the gate could still drift as a group.** If `$defs/aggregation`'s pattern widened, the reach row quoting it and the gate implementing it would both be stale, and the probe added by #73 would not notice. Solving that means the gate checking the row's text against the schema's pattern, which crosses the line § *How these tables are applied* draws. Recorded here so it is a known gap rather than an assumed one; it needs its own issue.
- **`p100` as a row, or as an alias for `max`.** An alias is forbidden outright by Principle II, and the row is already argued against in § *Aggregations*.
- **Widening the format's unit enumeration.** All seventeen units are already in the schema. #74 is about which of them a table calls reachable.
- **Anything a renderer would do with a refused document.** The format says a predicate has no equivalent; what a consumer reports is not in this repository's scope.
- **#94.** In this milestone, already on `main` at `906f8d2`, and not revisited.
