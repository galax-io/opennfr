# Contract: responseTime reaches ns, us, min and h (#74)

**Feature**: [spec.md](../spec.md) | **Plan**: [plan.md](../plan.md) | **Commit 4 of 4**

Closes [#74](https://github.com/galax-io/opennfr/issues/74). Satisfies FR-018 … FR-025.

**Files**: `README.md` § *Units* (under § *Gatling*) and `scripts/verify.sh`.

This is the only commit in the milestone that changes which documents may be published.

---

## What is wrong today

The last row of the Units table gives one reason for eleven units:

> | — | `ns`, `us`, `min`, `h`, `By`, `KiBy`, `MiBy`, `GiBy`, `{iteration}`, `{iteration}/s`, `{vu}` | — | not reachable through any assertable statistic |

The reason is true of seven. It is false of the four durations: `responseTime.*` is a duration
statistic whose native unit is milliseconds, and the same arithmetic that already converts `s`
converts all four exactly ([research.md](../research.md) R4).

## The change — `README.md` § *Units*

**1. The two duration rows' `Accepts` cells** grow from `ms`, `s` to the six duration units:

| Statistic | Accepts | Native | Target |
|---|---|---|---|
| `responseTime.*` | `ns`, `us`, `ms`, `s`, `min`, `h` | milliseconds | `Int` |
| `groupCumulatedResponseTime.*` | `ns`, `us`, `ms`, `s`, `min`, `h` | milliseconds | `Int` |

Both, and by one edit: they share a factor table because they share one `Stats` type, which
§ *Metrics* already sources and dates.

**2. The last row** loses the four and keeps its reason, which is now true of everything in it:

| | Accepts | | |
|---|---|---|---|
| — | `By`, `KiBy`, `MiBy`, `GiBy`, `{iteration}`, `{iteration}/s`, `{vu}` | — | not reachable through any assertable statistic |

**3. The derived-row sentence stands unchanged** and is re-checked rather than re-worded: the
enumeration in § *Units* is 17, the statistics above reach 10 distinct units, 17 − 10 = **7**, and
the seven are exactly those listed (R7).

**4. The whole-number rule is named as what still governs them** — it is not an exception for
these four but the rule they now answer to: `1500000 us` is 1500 ms and renders; `1500 ns` is
3/2000 ms and is refused, by that rule and with its reason.

**No separate row for the four durations**, which is what #74's wording proposes. § *Units* opens
by stating that units are per statistic, and a statistic in two rows contradicts the sentence the
table is organised around. Recorded in [spec.md](../spec.md) § *Decisions*.

## The change — `scripts/verify.sh`

**1. Four factors** join `TIME`, which both duration statistics already share:

```python
TIME = {"ns": Fraction(1, 1000000), "us": Fraction(1, 1000), "ms": Fraction(1),
        "s":  Fraction(1000),       "min": Fraction(60000),  "h":  Fraction(3600000)}
```

Every factor is exact; no conversion rounds.

**2. Four rendering probes** in `PREDICATE_RENDERS`, one per new unit, so deleting any single
factor fails the gate:

```python
{**RENDERABLE, "threshold": 2000000, "unit": "ns"},
{**RENDERABLE, "threshold": 1500000, "unit": "us"},
{**RENDERABLE, "threshold": 2,       "unit": "min"},
{**RENDERABLE, "threshold": 1,       "unit": "h"},
```

**3. One rejection probe** in `PREDICATE_PROBES` — a sub-millisecond value in a newly reachable
unit, refused by the whole-number rule and not by "not a unit of":

```python
({**RENDERABLE, "threshold": 1500, "unit": "ns"},
 "threshold 1500 ns is 3/2000 for responseTime.percentile, whose target is an integer"),
```

**4. Floors**: rejection `20` → `22`, rendering `18` → `22`.

## The conversions, verified

| written | native (ms), exact | verdict |
|---|---|---|
| `2000000 ns` | 2 | renders |
| `1500000 us` | 1500 | renders |
| `2 min` | 120000 | renders |
| `1 h` | 3600000 | renders |
| `1500 ns` | 3/2000 | refused — whole-number rule |
| `1 us` | 1/1000 | refused — whole-number rule |

## What must NOT change

- **No message string**, and in particular the sub-millisecond refusal must come from the
  whole-number branch, not from `unit … is not a unit of …`. The four units are reachable first
  and governed second; that ordering is the whole of #74.
- **The unit enumeration.** All seventeen are already in `$defs/unit`; this changes which of them
  a table calls reachable, not what the format carries. The schema is not edited.
- **`examples/` stays byte-identical.** These four units are newly *publishable*; publishing an
  example in one is a separate decision and no issue asks for it.

## Acceptance

```bash
bash scripts/verify.sh
```

`22 predicate probes still rejected, 22 still rendered`, whole gate **PASS**.

| revert | expected failure |
|---|---|
| any one of the four factors deleted from `TIME` | that unit's rendering probe |
| the whole-number check skipped for the new units | the `1500 ns` rejection probe |
| any probe deleted | the floor |

And by reading: every unit in `$defs/unit` is either in a statistic's `Accepts` cell or in the last
row — seventeen units, none in both, none in neither.
