# Contract: Repository shapes

**Feature**: [spec.md](../spec.md) | **Status**: proposed until the layout document lands

The layout document, the follow-up list and the experimental area each publish rows that later
work reads. These are the shapes those rows must have, so a reviewer can check a draft
mechanically instead of by feel.

---

## Layout table row

One row per artifact class. Every column mandatory.

| Column | Rule |
|---|---|
| Class | Unique name. Defined in the layout document with a rejected alternative — it is a governance word, not a format term |
| Home | Exactly one directory. Two or none is a layout defect (FR-015) |
| Who may change it | **Uniform across every row: "Anyone, by pull request."** Differences belong in the next column |
| Obliges | What a change requires — glossary entry, ADR, dated evidence, sketch label |
| On the compatibility surface | Yes / partly / no. The experimental area is `no` by construction (FR-018) |

**Why the third column is uniform**: the constitution already forbids a surface only
maintainers can extend, and no class has a reason to be narrower. Classes differ by what a
change obliges, not by who may propose it. Two sentences below the table carry that argument,
and no role vocabulary is introduced — Principle I prices every added governance word.

**One sentence the table needs beside it**: `specs/` is not an artifact class. It is the
spec-kit working directory, and flow is one-directional — a follow-up spec writes into the
homes this table names, and never becomes one.

---

## Non-conformance row

The layout publishes what is mis-filed rather than moving it. AGENTS.md forbids opportunistic
refactors outside scope; FR-013 forbids the silent mismatch.

| Column | Rule |
|---|---|
| Path | The file as it sits today |
| Belongs to | The class the table assigns it |
| Why not moved now | The scope argument |
| The move's obligation | What the eventual move must **also** do, so the cost is visible before someone starts |

The obligation column is the one that earns the row. Moving the two tool mappings out of
`docs/examples/` slips them past `verify.sh`'s sketch-label check, which is hardcoded to that
directory — a move that looks like tidying silently removes a gate.

---

## Follow-up entry

| Column | Rule |
|---|---|
| Slug | Unique. **Named by slug, never by ordinal** |
| Delivers | Concrete files. This is FR-022's unit of claim |
| Depends on | Other slugs, stated explicitly |
| Role | Which component role it implements |
| Scheduling | `scheduled`, or `parked` |

**Numbering is not scheduling.** `specs/NNN-` records the order specs were *created*, not the
order they must be *completed*. The list must say so in one sentence, because
`001-nfr-format-architecture` already sets a numbering a reader will read as a schedule.

**Disjointness** (SC-008): no individual deliverable appears in two entries. The unit is the
file, not the class — at class granularity the list is unwritable, since the schema, the object
model and the corpus all add to the normative core.

**A parked entry carries conditions instead of a position** (SC-011): promotion conditions,
retirement conditions, a date, and nothing that looks like a schedule.

---

## Experimental artifact

Every file in the experimental area, without exception (FR-018, SC-011).

| Element | Rule |
|---|---|
| Status | States in its own text that it is experimental |
| Promotion | What would move it to stable, in checkable terms |
| Retirement | What would kill it |
| Date | When the status was last true |
| Owner | The follow-up spec that owns verifying it |

**Two structural rules make SC-007 executable rather than aspirational**:

1. **No markdown link points into the area from outside it.** Outside references name the path
   in prose, inside a code span. `verify.sh` fails the build on any dangling internal link, so
   one inbound link turns the one-operation deletion red.
2. **The area holds markdown only, no YAML.** This keeps it clear of the sketch-label check.

With both rules, the criterion is a command:

```bash
git rm -r docs/experimental && bash scripts/verify.sh
```

---

## Statement marker

SC-014 requires every statement in the architecture document to be marked binding or proposed,
and the number of unmarked ones to be zero — which is unfalsifiable unless "statement" has a
unit.

| | |
|---|---|
| Unit | A numbered clause or a table row. Not a sentence, not a heading |
| Marker | A dedicated column for tables; an explicit `(binding)` / `(proposed)` tag for clauses |
| Counting | Mechanical: rows and clauses without a marker, counted |

**Default**: nothing is binding by default. An unmarked clause is a defect, not an implicit
`proposed` — otherwise the safest draft is the vaguest one.
