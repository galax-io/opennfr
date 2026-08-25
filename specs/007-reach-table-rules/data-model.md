# Phase 1: what a Selection row is, before and after

**Feature**: `007-reach-table-rules` | **Date**: 2026-08-24

No entity is added to the format. One entity in the *contract* gains a field, and that is the whole
feature: a Selection row stops being keyed by a set of attribute names and starts being keyed by
the pair (names, what their values may be).

## The entity that changes

**Selection row** — one line of the reach contract's Selection table. It is the unit an
implementer matches a document against, and the unit the gate implements.

| Field | Today | After |
|---|---|---|
| `keys` | the set of attribute names present | unchanged |
| `values` | **absent** — the row says nothing | what each named attribute may carry: a string, and whether `"*"` is admitted in that position |
| `gatling` | the scope and path emitted | unchanged in form; three rows are added and their scope is `forAll()` or none |
| `verdict` | **can** / **cannot** | unchanged |
| `reason` | present on **cannot** rows | unchanged; the three new **cannot** rows carry theirs |

A row is matched **exactly**, on both fields. That is the invariant at `gatling-reach.md:111`, and
adding `values` is what makes it true on this axis.

## The term that changes

**`"*"`** — defined in `GLOSSARY.md:56`, `README.md:246` and the schema's `$defs/selector`
description as *the attribute is present with any value; presence, not a glob*.

| | Today | After |
|---|---|---|
| Meaning | the attribute is present, with any value | the attribute is present, **and each distinct value is a statement of its own** |
| Reading of `{loadtest.request.name: "*"}` | one number over all named requests — which is every request, so `global` | one statement per observed request |
| Written in | `GLOSSARY.md`, `README.md`, schema `$defs/selector` description | the same three, changed together in one commit — research.md R8 |

This is the Principle I obligation. It is a redefinition, not an addition: the old definition is
not wrong, it is silent on the question that decides how a document renders. See research.md R1.

## What each artifact carries afterwards

| Artifact | Changes | What must not change |
|---|---|---|
| `specs/004-strip-to-schema/contracts/gatling-reach.md` | Selection table gains value constraints and three rows; percentile row loses its ellipsis; two Principle III citations become arguments; the absent-data note attaches to the `forAll()` row; **Checked** date moves to 2026-08-24 | Every existing **can** row keeps its verdict. The Metrics, Operators and Units tables are untouched |
| `scripts/verify.sh` | § *Examples are assertable by Gatling* rejects on (key set, value); gains a probe table with a floor | It keeps reading `examples/` and never the schema. The `checked == 0` floor stays |
| `GLOSSARY.md` | § *selector* states the quantifier; records the rejected alternative | The other twelve entries |
| `README.md` | selector table states the quantifier; the Names section's derived-quantities sentence drops apdex | The exclusion itself: apdex still must not become a metric |
| `docs/ideas.md` | gains an apdex entry with its `*Would need*` clause | The `loadtest.*` registry list keeps its `loadtest.apdex` (composite) mention — that is about a **name** not entering a namespace, not a construct not entering the format |
| `examples/` | gains one document, three → four | The three existing documents keep validity and verdict |
| `schema/.../requirementset.schema.json` | the `$defs/selector` **description**, so all three definitions of `"*"` say the same thing (research.md R8) | every constraint it makes today, byte for byte. The gate's embedded-example and closure-probe counts must come out unchanged |
| `.specify/memory/constitution.md` | nothing | Principle II's apdex sentence and Principle III's cut clauses are knowingly left — spec FR-015 |

## Validation rules, and where each lives

| Rule | Source | Check |
|---|---|---|
| A path value is a string | contract, Selection table | gate, on the value; probe: a numeric path value |
| `"*"` on `loadtest.request.name` alone quantifies | contract, Selection table | gate accepts; corpus document exercises it |
| `"*"` elsewhere in a path has no correspondence | contract, two **cannot** rows | gate rejects; two probes |
| A non-`"*"` path value is a literal path part | contract, Selection table | gate accepts; the three existing corpus documents exercise it |
| Any percentile the schema's pattern admits | contract, Aggregations table | gate, unchanged behaviour; the row now states what the gate already does |

Two things this table is making explicit, because both were the defect being fixed: every rule has
exactly one source and one check, and no rule's only home is the gate.

## State transitions

None. Nothing in this feature has a lifecycle — a document is either assertable or it is not, and
the verdict is a function of the document alone.
