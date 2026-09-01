# Contract: the percentile test is the row it implements (#73)

**Feature**: [spec.md](../spec.md) | **Plan**: [plan.md](../plan.md) | **Commit 2 of 4**

Closes [#73](https://github.com/galax-io/opennfr/issues/73). Satisfies FR-001 … FR-006.

**Files**: `scripts/verify.sh` only. `README.md` § *Aggregations* is the **source** of this rule
and its text is final — this commit changes no prose.

---

## What is wrong today

`scripts/verify.sh:634`:

```python
def percentile(a): return a.startswith("p") and a[1:].replace(".", "", 1).isdigit()
```

Against the row's `^p\d{1,2}(\.\d+)?$`, which § *Aggregations* quotes from the schema, this admits
five shapes the row and the schema both reject:

| aggregation | helper | row / schema |
|---|---|---|
| `p95` `p99.9` `p1` `p10` `p0.1` `p99.99` | accepts | accepts |
| `p100` `p999` `p1234` `p.5` `p1.` | **accepts** | rejects |
| `p` | rejects | rejects |

On any of the five, one run of the gate calls the predicate assertable in its reach section and
the document invalid in its schema section.

## The change

**1. `import re`** joins the Gatling heredoc's imports, which today are `glob`, `sys`,
`Fraction`, `identity` and `yaml`.

**2. The helper becomes the row's pattern**, held as a named constant and applied with
`re.fullmatch`:

```python
# The row this implements, verbatim: README > Gatling > Aggregations quotes it from
# $defs/aggregation, and the three copies are one string so a reader can compare them by eye.
# fullmatch and not match: Python's `$` also matches before a trailing newline and ECMA-262's --
# the dialect a JSON Schema `pattern` is written in -- does not, so `match` would admit "p95\n",
# which is the row's own defect one input smaller (#73).
PERCENTILE = r"^p\d{1,2}(\.\d+)?$"
def percentile(a): return re.fullmatch(PERCENTILE, a) is not None
```

The `^` and `$` are redundant under `fullmatch` and are kept: their job is that the constant, the
row and `$defs/aggregation` are character-identical (FR-004).

**3. Three rejection probes** join `PREDICATE_PROBES`, each the sole catcher of one regression:

```python
({**RENDERABLE, "aggregation": "p999"},
 "aggregation p999 over a metric has no equivalent"),
({**RENDERABLE, "aggregation": "p.5"},
 "aggregation p.5 over a metric has no equivalent"),
({**RENDERABLE, "aggregation": "p95\n"},
 "aggregation p95\n over a metric has no equivalent"),
```

| probe | catches |
|---|---|
| `p999` | `\d{1,2}` widened, or the `isdigit()` helper returning |
| `p.5` | the integer part made optional |
| `"p95\n"` | `re.fullmatch` swapped for `re.match` |

**4. The rejection floor** rises `13` → `16` in `FLOORS`.

## What must NOT change

- **No new message.** All three reasons come from the existing aggregation-row lookup: once
  `percentile()` returns false, the key falls through `TABLE["metric"].get(...)` to `None` and the
  existing branch fires. A message written specially for out-of-range percentiles would be a
  second rule (FR-003). Verified by simulation — [research.md](../research.md) R5.
- **`p100` gains no row.** § *Aggregations* already says why: the quantity it names is `max`.
- **The schema is not read and not written.** § *How these tables are applied* states this section
  never reads the schema, and the heredoc's own header comment repeats the reason.
- **`README.md` is not edited by this commit**, and `examples/` is not edited by any of them.

## Acceptance

```bash
bash scripts/verify.sh
```

`== Examples are assertable by Gatling` reports `16 predicate probes still rejected` and
`16 still rendered`, and the whole gate is **PASS**.

Then, each on its own, and each must turn the gate **red**:

| revert | expected failure |
|---|---|
| `re.fullmatch` → `re.match` | probe `p95\n` |
| `\d{1,2}` → `\d+` | probe `p999` |
| `\d{1,2}` → `\d*` | probe `p.5` |
| the whole constant → the old `isdigit()` helper | probes `p999` and `p.5` |
| any probe deleted | the floor, before any probe runs |

And the six accepted percentiles still render: `p95`, `p99.9`, `p1`, `p10`, `p0.1`, `p99.99`.
