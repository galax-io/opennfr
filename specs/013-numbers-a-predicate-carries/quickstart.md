# Quickstart: checking that v0.9.0 landed

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-09-01

Nine steps. Each is a command or a read, each has an expected result, and together they check
every functional requirement without reading a diff. Run from the repository root.

**Prerequisites**: `python3` with `jsonschema` and `pyyaml` — the gate's existing dependencies.
Nothing is added. Steps 8 and 9 additionally need a JDK's `javap` and the Gatling jars in the
local Coursier cache; skip them and say so if the jars are absent, rather than passing them
silently.

---

## 1. The corpus did not change

```bash
git diff --stat main -- examples/
```

**Expect**: empty output. FR-026 and SC-011. This is checked rather than read: byte-identical is
not an impression.

## 2. The gate is green and the floors moved

```bash
bash scripts/verify.sh
```

**Expect**: `PASS`, and the reach line reading

```
ok    10 predicates assertable by Gatling, 9 selection probes still rejected, 6 still rendered,
      22 predicate probes still rejected, 22 still rendered, 4 pairing probes still rejected,
      4 still rendered
```

**13 → 22** and **16 → 22** are the fifteen probes this milestone adds. The four selection and pairing
counts are unchanged, which is how you know nothing else moved.

## 3. Three artifacts say one thing about percentiles

```bash
python3 - <<'CHECK'
import json, re
schema = json.load(open("schema/opennfr.io/v1/requirementset.schema.json"))
sp = [b["pattern"] for b in schema["$defs"]["aggregation"]["anyOf"] if "pattern" in b][0]
readme = set(re.findall(r"`(\^p\\d\{1,2\}\(\\\.\\d\+\)\?\$)`",
                        open("README.md", encoding="utf-8").read()))
gate = set(re.findall(r'PERCENTILE\s*=\s*r"([^"]+)"',
                      open("scripts/verify.sh", encoding="utf-8").read()))
print("  schema:", sp)
print("  README:", readme or "NOT FOUND")
print("  gate  :", gate or "NOT FOUND")
print("  all three identical:", bool(gate) and bool(readme) and {sp} == readme == gate)
CHECK
```

**Expect**: `all three identical: True`. FR-001 and FR-004. Run it before #73 lands and the gate
line reads `NOT FOUND` — which is the point: the named constant is what makes the three comparable
at all, and the `isdigit()` helper it replaces was never a pattern anyone could hold beside the
row. The gate's site must also name the row it implements, in a comment.

## 4. Every out-of-range percentile is refused, and the six in range render

```bash
python3 - <<'PY'
import re
P = r"^p\d{1,2}(\.\d+)?$"
for a in ["p95","p99.9","p1","p10","p0.1","p99.99","p100","p999","p1234","p.5","p1.","p","p95\n"]:
    print(f"  {a!r:10} {'renders' if re.fullmatch(P,a) else 'refused'}")
PY
```

**Expect**: the first six render, the last seven are refused. FR-005. If `p95\n` renders, the gate
is using `re.match` — [research.md](research.md) R1.

## 5. The arithmetic is answerable from the page alone

Open `README.md` § *Units* under § *Gatling* and, **without opening `scripts/verify.sh`**, answer:

- How is a threshold converted to the native unit? → *exact decimal arithmetic on the value the
  threshold denotes.*
- I have already parsed it into a double. What do I do? → *recover the shortest decimal that
  round-trips it, then compute exactly; that is the literal's value up to fifteen significant
  digits.*
- Must I keep the document's source text? → *no.*

Then open `GLOSSARY.md` § *threshold and unit* and confirm its *Rejected* line names the refused
precision bound on `threshold` and both grounds — that it narrows the schema to one target's reach,
and that `multipleOf` is itself evaluated in binary floating point. Confirm § *Units* says **nothing**
about the schema: a target description is what a renderer reads, and a renderer reads nothing from
a rejected schema change.

FR-007 … FR-010, FR-012, FR-027, SC-003, SC-004.

## 6. The two arithmetics are reconciled on the values that split them

```bash
python3 - <<'PY'
from fractions import Fraction
for lit in ["1.001","1.003","1.005","0.5"]:
    print(f"  {lit} s -> exact {Fraction(lit)*1000}   double {float(lit)*1000.0}")
PY
```

**Expect**: exact gives `1001`, `1003`, `1005`, `500` — all whole, all rendering. The double column
shows why the rule could not stay unstated. The gate must render all four.

## 7. Every unit is placed exactly once

```bash
python3 - <<'PY'
import json
units = set(json.load(open("schema/opennfr.io/v1/requirementset.schema.json"))["$defs"]["unit"]["enum"])
reached = {"ns","us","ms","s","min","h","%","1","{request}","{request}/s"}
print("  total", len(units), "| reached", len(reached), "| unreachable", len(units-reached))
print("  unreachable:", sorted(units - reached))
PY
```

**Expect**: `total 17 | reached 10 | unreachable 7`, and the seven are `By`, `GiBy`, `KiBy`,
`MiBy`, `{iteration}`, `{iteration}/s`, `{vu}`. Read § *Units*' last row and confirm it holds
exactly those. FR-020, FR-021, SC-005.

## 8. The `Target` column matches the DSL

```bash
SRC=$(find ~/Library/Caches/Coursier ~/.cache/coursier -name 'gatling-core-3.13.5-sources.jar' 2>/dev/null | head -1)
unzip -p "$SRC" 'io/gatling/core/assertion/AssertionBuilders.scala' | grep -n 'AssertionWithPathAndTarget\[' | head -20
```

**Expect**: `[Int]` for `min`/`max`/`mean`/`stdDev`/`percentile`, **`[Long]` for `count`**,
`[Double]` for `percent` and `requestsPerSec`. Compare against § *Units*' `Target` column: five
rows, five types, no mismatch. FR-017d, SC-009.

## 9. The rule survives every revert that should kill it

Apply each on its own, run `bash scripts/verify.sh`, expect **red**, then revert:

| edit | expected failure |
|---|---|
| `re.fullmatch` → `re.match` | probe `p95\n` |
| `\d{1,2}` → `\d+` in the pattern | probe `p999` |
| `Fraction(str(...))` → `p["threshold"] * factor` | the `1.001 s` rendering probe |
| either count row's `True` → `False` in `TABLE` | that row's own `20.5 {request}` rejection probe — one per shape |
| any one of the four new `TIME` factors deleted | that unit's rendering probe |
| the range check removed, or its bound off by one | `597 h`, or the `2147483647 ms` rendering probe |
| `threshold_literal` back to `str(...)`, or `LOADER` swapped | the 17-digit probe, or `LOADER`'s own check |
| any single probe deleted | the floor beside it |

SC-007 and SC-010. The fourth row is the one that fails **today**: before this milestone, flipping
either count row's integral flag leaves the gate green.
