# Implementation Plan: Which Numbers a Predicate May Carry

**Branch**: `013-numbers-a-predicate-carries` | **Date**: 2026-09-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/013-numbers-a-predicate-carries/spec.md`

## Summary

Milestone **v0.9.0**, three issues, one question under all of them: *which numbers may a predicate carry, and which artifact decides?* Three artifacts answer today and they answer differently.

The milestone stays inside what a renderer does — turning a requirement document into a target's assertions. Nothing here describes a report, a verdict, or anything a consumer builds after the run.

- **#73**: the gate's percentile test is `a.startswith("p") and a[1:].replace(".", "", 1).isdigit()`, which admits **five** shapes the row's `^p\d{1,2}(\.\d+)?$` and the schema both reject — `p100`, `p999`, `p1234`, `p.5` and `p1.`, the last of which no issue names. On those, one run of the gate calls a predicate assertable in its reach section and the document invalid in its schema section. The helper becomes the row's pattern, matched with `re.fullmatch` and not `re.match` ([research.md](research.md) R1), plus three rejection probes.
- **#59**: the whole-number rule forbids rounding but never says which arithmetic decides whether a value is whole, and exact decimal disagrees with a double on `1.001 s`, `1.003 s` and `1.005 s`. The contract gains the arithmetic and a conformance route for a renderer that already parsed into a double (R2). The schema does **not** gain a precision bound: `GLOSSARY.md` § *aggregation* already rejected narrowing the schema to a target's reach, and `multipleOf: 0.001` **rejects `1.001`** under the repository's own validator, reproducing the defect one layer down.
- **#59, closing section**: the `Int` the rule rests on is the type of two DSL entry points, not of the target — re-read here at 3.13.5 / 0.0.11 (R3). The attribution is corrected, no rule is relaxed, and one cell in the same column is wrong: `count` returns `AssertionWithPathAndTarget[`**`Long`**`]`. That correction is not separable — the rule is worded *"where the target is an `Int`"*, so fixing the cell alone would drop counts out of the rule and make `20.5 {request}` renderable.
- **#74**: the Units table gives one reason for eleven units and it is true of seven. `responseTime.*` reaches `ns`, `us`, `min` and `h` exactly, by the same arithmetic that already converts `s`. Four factors are added, the two duration statistics' `Accepts` cells grow, and the unreachable row shrinks to the seven for which its reason holds.

**The work is three files.** `README.md` (§ *Aggregations* untouched but named as the source; § *Units* — the `Accepts` cells, the `Target` column, the whole-number rule, and a new sentence stating the arithmetic), `GLOSSARY.md` (one sentence joining § *threshold and unit*'s existing *Rejected* line, recording why a precision bound on `threshold` was refused) and `scripts/verify.sh` (`import re`, the percentile constant and test, four `TIME` factors, the `Int`/`Long` bounds, a literal-preserving loader, fifteen probes, four raised floors). The schema is read and not written.

**`examples/` does not change**, and R8 shows why rather than asserting it: across all ten published predicates the aggregations are `p50`/`p95`/`p99`/`max`/`count`/`rate`, the units are `ms`/`s`/`%`/`{request}`/`{request}/s`, and every threshold is a whole number in a whole unit. Every change here either refuses something no document says or admits something no document says.

The plan's four load-bearing decisions:

- **`re.fullmatch`, and the pattern carried verbatim with its anchors.** Python's `$` also matches before a trailing newline; ECMA-262's — the dialect JSON Schema `pattern` is defined in — does not. `re.match` with the row's pattern would accept `"p95\n"` and leave a strictly smaller copy of #73 installed by the commit that closes it (R1). The anchors are redundant under `fullmatch` and kept anyway, so a reader can hold the gate's constant beside the row and beside `$defs/aggregation` and see three identical strings.
- **The rule is about the value, and the double route is a conformance note.** "The literal as written" would oblige a renderer to keep source text that JSON and YAML parsers discard (FR-010). Shortest-round-trip recovery is named as *a route to* the value, not as the rule: Java's `Double.toString` did not always produce the shortest decimal before JDK 19, so a Scala renderer's answer would otherwise depend on its JDK.
- **The gate was right; the page was wrong.** The gate reasons over an `integral` flag and never over the word `Int`, so its existing refusal message — *"whose target is an integer"* — stays true and correct under `Long`. FR-017e makes the page say what the gate already does, and no message string changes anywhere in this milestone (R5).
- **Fifteen probes, each the sole catcher of one regression.** That is the standard the section's own comment already sets. Without probe 3 (`"p95\n"`) the `fullmatch`→`match` swap passes green; without probe 5 either count row's integral flag can be flipped and the gate stays green today.

## Technical Context

**Language/Version**: none for the format. The gate is POSIX `bash` driving `python3` heredocs. This feature adds one standard-library import, `re`, to the Gatling heredoc, which today imports `glob`, `sys`, `Fraction`, `identity` and `yaml`.

**Primary Dependencies**: unchanged. `jsonschema` and `pyyaml` are already required and nothing joins them.

**Storage**: N/A.

**Testing**: `bash scripts/verify.sh` is the only gate, and this feature adds to one of its sections — *Examples are assertable by Gatling*. There is no test runner and nothing to compile.

**Target Platform**: N/A — the artifacts are a JSON Schema, three markdown documents and a shell gate.

**Project Type**: format specification with a validating gate.

**Performance Goals**: N/A. The gate reads four YAML documents and one schema.

**Constraints**: `examples/` is byte-identical before and after. No compatibility-sensitive surface is touched: no borrowed OpenTelemetry name changes, and no field name appearing in a published example is added, removed or renamed. The schema is not edited. `git rm -r docs && bash scripts/verify.sh` stays green.

**Scale/Scope**: three files, fifteen probes, four floors. Four schema-valid documents become publishable that were not; none stops being publishable.

## Constitution Check

*GATE: evaluated before Phase 0 research and re-evaluated after Phase 1 design. Both passes recorded.*

See `.specify/memory/constitution.md` (v4.0.0).

- [x] **I. Vocabulary Before Features** — no term is introduced and none is renamed. `threshold`, `unit`, `aggregation` and every unit spelling are unchanged. `GLOSSARY.md` gains **no entry and loses none**; § *threshold and unit*'s existing *Rejected* line gains one sentence, which is the shape this principle asks for — *"the rejection outlives the term it protects"* — and is what [spec.md](spec.md) FR-027's second sentence provides for. The line already refuses full UCUM and `threshold: "500ms"`, the latter being the shape a "keep the source text" reading of #59 would have pushed toward; the refused precision bound joins them. All three issues were argued before any file changed.
- [x] **II. Borrow Names, Never Invent Them** — no metric or attribute name is touched. The four units entering the reach tables are already in the format's closed enumeration and are UCUM spellings; nothing is minted. No alias, no derived or composite quantity.
- [x] **III. No Silent Green** — the principle this milestone is most exposed to, and #73 and FR-017f are both instances of it. Every rule changed gains a probe that fails when it is reverted (R6), and each of the four floors is raised in the commit that adds its probes. Two rules that are unprobed **today** stop being so: the percentile pattern, and both count rows' integral flag, either of which can currently be flipped with the gate staying green.
- [x] **IV. Honest Status** — every external claim carries its artifact, its version and its date. R3 was re-read here at `gatling-core` / `gatling-core-java` **3.13.5** and `gatling-shared-model_2.13` **0.0.11** on **2026-09-01**, and § *Units* will name those rather than borrowing § *Gatling*'s 3.15.1 header — the same treatment v0.8.0's Identity row received. FR-017d exists because a published table stated a type nobody had checked.
- [x] **V. Structure Over Grammar** — no field is added and no value set changes. The percentile pattern is a schema `pattern` today and stays one; the gate carries a copy of it as a constant, which is an implementation of a row, not a second grammar. `threshold` stays a bare `number` — FR-011 declines the one change that would have put a decoding rule in the schema.
- [x] **VI. The Requirement Is Target-Blind** — no requirement document names a target and `examples/` does not change. Every prose edit that is a **target fact** lands in `README.md` § *What any tool can actually run*, the **one** description Gatling has; no second copy is created. The one edit that is *not* a target fact — why the format declined to bound `threshold` in its own schema — lands in `GLOSSARY.md` instead, because a renderer reads nothing from it and a description is defined as what a renderer reads. An earlier draft of the contract had put it in § *Units*; `/speckit-analyze` caught it. The gate implements that description and carries no second copy of its rows — every new refusal comes from a code path that already existed, and no message string is added (R5). Adding these four reachable units changes no format, no schema and no requirement document.
- [x] **VII** — *withdrawn in 3.0.0. No gate.*
- [x] **VIII. Ideas Are Parked, Not Merged** — nothing under `docs/` is touched, no construct is proposed or parked, and no document outside `docs/` gains a link into it. `git rm -r docs && bash scripts/verify.sh` is unaffected.
- [x] **Compatibility** — no borrowed OpenTelemetry name is touched. No field name in a published example is added, removed or renamed. **The published corpus widens rather than narrows**: four units the format already carried become publishable, and the "at least one surveyed target can assert it exactly" bar is cleared by the arithmetic in R4 — `1500000 us` is 1500 ms with no rounding, which is exactly what "assert it exactly" asks. Nothing enters the format at all, so the second clause — that a construct must not enter solely to reach one target's feature — has nothing to bind.

**Post-Phase-1 re-check**: unchanged. Three things the design passes made explicit, none a violation.

1. **R1 changed how #73 is implemented, not what it decides.** The spec's FR-001 asks that the gate admit exactly what the row admits; a naive `re.match` would have missed that by one input. The requirement did not move — the implementation that satisfies it did, and [contracts/percentile-pattern.md](contracts/percentile-pattern.md) fixes the call so a later "simplification" is a visible change.
2. **The `Long` correction stays inside #59 and does not become its own commit.** It is downstream of FR-017's sentence, not adjacent to it: the column's *meaning* changes, and one cell is wrong under the new meaning. Splitting it out would produce a commit whose only content is a cell that the previous commit had just made false.
3. **Code review found the rule was under-stated twice, and both are now in the gate.** The
   whole-number rule is a **range** as well as a divisibility — `597 h` is exactly 2 149 200 000 ms
   and the `Int` the table now names stops at 2 147 483 647 — so `TABLE` carries a bound per row
   rather than a boolean. And the arithmetic § *Units* states is about the value the literal
   denotes, which `Fraction(str(float))` cannot recover past fifteen significant digits: the gate
   rendered `1.0000000000000001 s` as a whole 1000 ms while the rule refused it. `ExactLoader`
   keeps the literal, and `LOADER`'s own check guards the wiring, which no probe can reach because
   no published document carries a threshold that long.
4. **The count rows needed two probes, not one, and implementation is where that surfaced.**
   FR-017f and this plan said "a rejection probe for a fractional threshold on a count row",
   singular. The two count rows sit in **different shapes** — `allRequests.count` under `requests`,
   `failedRequests.count` under `fraction` — so a single probe reaches one and leaves the other as
   unguarded as T002's baseline found it. The T025 revert set caught it before the commit: with one
   probe, flipping `failedRequests.count`'s integral flag left the gate green. Two probes now, and
   the rejection floors are 18 and 19 rather than 17 and 18. Recorded here rather than silently
   corrected, because the probe count is the milestone's own claim about what it checks.
5. **`GLOSSARY.md` gains one sentence, and the plan was wrong to say otherwise.** This entry said the file was untouched. `/speckit-analyze` found that it put FR-012's recorded rejection — why a precision bound on `threshold` was refused — inside § *Units*, which is a target description, and Principle VI defines one as what a renderer reads to turn a document into assertions. A rejected schema change is not that. The rejection moves to § *threshold and unit*'s *Rejected* line, beside the two neighbouring decisions about the same field. **The spec never narrowed this**: FR-027 already read *"where a decision above bears on an existing entry, it is recorded at the entry's own Rejected line"*, and § *Dependencies* already said `GLOSSARY.md` was "extended only if FR-027's second sentence applies". The plan and the contract narrowed what the spec allowed; the spec needs no change.

## Project Structure

### Documentation (this feature)

```text
specs/013-numbers-a-predicate-carries/
├── spec.md
├── plan.md                         # this file
├── research.md                     # Phase 0 — eight questions; R1 changed an implementation
├── data-model.md                   # Phase 1 — the pattern, the conversion, the row, the probe
├── quickstart.md                   # Phase 1 — how to check the milestone landed
├── contracts/
│   ├── percentile-pattern.md       # the constant, the call, the three probes          (#73)
│   ├── threshold-arithmetic.md     # the arithmetic sentence, the Target column, Long  (#59)
│   └── duration-units.md           # the factors, the two Accepts cells, the last row  (#74)
└── checklists/
    └── requirements.md
```

### Repository (what this feature edits)

```text
README.md                                       # § Units (under § Gatling) — the two Accepts cells,
                                                #   the Target column incl. Long, the whole-number
                                                #   rule reworded, one new sentence on the arithmetic
scripts/verify.sh                               # import re; PERCENTILE + fullmatch; four TIME
                                                #   factors; bounds; loader; fifteen probes; four floors

# read, and deliberately not written
schema/opennfr.io/v1/requirementset.schema.json # $defs/aggregation's pattern is the source of the
                                                #   constant; $defs/threshold gains no bound (FR-011)
# ^ and the reason it gains none is recorded in GLOSSARY.md above, not in a target description
GLOSSARY.md                                     # § threshold and unit — one sentence joins the
                                                #   existing *Rejected* line: why a precision bound
                                                #   on `threshold` was refused (FR-012)
README.md § Aggregations                        # the percentile row is the source; its text is final

# untouched, and checked to be untouched (quickstart step 1)
examples/                                       # byte-identical; every document keeps its verdict
docs/                                           # no idea added, moved or edited
.specify/memory/constitution.md                 # stays at 4.0.0; no amendment is needed
specs/                                          # except this feature's own directory
```

**Structure Decision**: the repository has no source tree. The format is `schema/`, explained by `README.md`, its terms in `GLOSSARY.md`, its corpus in `examples/`, and its gate in `scripts/`. This feature edits three of those five and reads the other two; `examples/` is deliberately untouched, and the schema is deliberately not written.

## Implementation Order

Four commits, one per issue in the milestone's own order, preceded by the spec commit. Each is green on its own, and each raises the floors it earns.

1. **`docs(speckit): add 013-numbers-a-predicate-carries spec/plan/tasks`** — this directory.
2. **`fix(gate): the percentile test is the row it implements (#73)`** — `scripts/verify.sh`: `import re`, the `PERCENTILE` constant, `re.fullmatch`, three rejection probes, rejection floor 13 → 16. No `README.md` change: § *Aggregations* is already correct and is the source. Contract: [contracts/percentile-pattern.md](contracts/percentile-pattern.md).
3. **`fix(format): the conversion is exact decimal arithmetic (#59)`** — `README.md` § *Units*: the arithmetic sentence, the `Target` column with `Long`, the whole-number rule conditioned on an integral target. `GLOSSARY.md` § *threshold and unit*: one sentence on the refused precision bound. `scripts/verify.sh`: the round-trip's comment, one rendering probe (`1.001 s`), four rejection probes (`20.5 {request}` once per count row, the 17-digit literal, the `Long` bound) and two rendering, floors 16 → 20 and 16 → 18. Contract: [contracts/threshold-arithmetic.md](contracts/threshold-arithmetic.md).
4. **`fix(format): responseTime reaches ns, us, min and h (#74)`** — `README.md` § *Units*: the two `Accepts` cells, the last row down to seven. `scripts/verify.sh`: four `TIME` factors, four rendering probes, one rejection probe, floors 20 → 22 and 18 → 22. Contract: [contracts/duration-units.md](contracts/duration-units.md).

#73 is first because it is one line of rule and touches nothing the other two touch. #59 is second because #74 adds four conversions that #59's sentence governs, and adding them first would multiply the ambiguity by four. #74 is last and is the only commit that changes which documents may be published.

## Complexity Tracking

> Three costs are paid deliberately. None is a Constitution Check violation; each is recorded because a reviewer should meet it here rather than find it in a diff.

| Cost | Why needed | Simpler alternative rejected because |
|---|---|---|
| A third copy of the percentile pattern, as a constant in the gate | The row and the schema already hold it; the gate must too, because § *How these tables are applied* states this section "never reads the schema" and the heredoc says so in a comment. The copy is what makes the gate an implementation of the row rather than a second rule. | **Reading `$defs/aggregation` at runtime** gives one copy and crosses the line the section draws — and the direction matters less than the sentence, which a reader would then have to reconcile against the code. **Leaving the helper and widening the row** inverts #73: the row is the argued artifact and the helper is the accident. The residual — schema, row and gate could drift *as a group* — is in spec § *Out of Scope* with the note that it needs its own issue. |
| Three probes for #73 where FR-002 asks for one | Each catches a distinct regression: a widened integer part, an optional integer part, and `fullmatch` swapped for `match` (R1). At one probe, two of the three pass green. | **One probe** meets the letter of FR-002 and leaves the two most likely edits — "simplify the regex", "match is shorter" — undetected. The section's own comment already sets this standard: *"Each probe here is the sole catcher of its own class."* |
| A cell correction (`Int` → `Long`) riding inside #59 rather than taking its own issue | It is downstream of FR-017, not adjacent to it. FR-017 restates what the `Target` column **means**; under the new meaning the count cell is wrong, and correcting it alone would drop counts out of a rule worded *"where the target is an `Int`"*, making `20.5 {request}` renderable. | **Its own issue and commit** would land a commit whose only content is a cell the immediately preceding commit had just made false — and would leave the milestone shipping a rule that exempts counts. AGENTS.md's "does not ride along" governs work that is *not* one of the milestone's issues; this is what doing one of them correctly entails. Recorded in spec § *Decisions* as the maintainer's call. |
