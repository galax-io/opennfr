# Phase 1 — Data Model

**Feature**: [003-assertion-first-format](spec.md) | **Date**: 2026-08-20 | **Research**: [research.md](research.md)

Three document kinds and one corpus. Every field below is validatable by JSON Schema draft 2020-12
with no bespoke parser, no open grammar and no string that must be parsed to be understood —
Principle V. Where that was hard to hold, it is called out.

`additionalProperties: false` everywhere, at every level. An unknown field is an error (FR-006).

---

## 1. `RequirementSet` — edited

`schema/opennfr.io/v1/requirementset.schema.json`. Two additions, nothing removed.

### 1.1 `displayName` — the human half of a name

| Field | Type | Required | Where |
|---|---|---|---|
| `displayName` | string, `minLength: 1` | no | `metadata`, each requirement, each predicate |

Free text, any script, none of the identifier's constraints. `name` is restricted to lowercase
letters, digits and hyphens because a rendering has to point at it; a person writing a requirement
wants a sentence, and today has nowhere to put one.

**Inert, and provably so.** It changes nothing selected, measured, compared or rendered. SC-013 makes
that a check rather than a promise: strip every display name from a document and every rendering must
come out byte-identical. An inert field that is not *provably* inert is one that quietly acquires
meaning.

**It does not reach the target's report.** No surveyed target has a field for an author-chosen string
(spec Appendix D). This must be said wherever the field is documented, because a format that lets an
author believe otherwise repeats decision D1's mistake — and this time with a field named
`displayName`, which invites exactly that belief.

**Additive, not breaking.** Optional everywhere, so every existing document stays valid. This is the
only change of the two originally planned for the container; the aggregate-versus-each distinction
was withdrawn (spec D2).

**It must not restate a structured value** (FR-007a). `displayName: 99th percentile under 500 ms`
beside `threshold: 500` is a second source for one number and will diverge the first time the
threshold moves. Write `99th percentile` — the quantity, not the answer.

**Not mechanically checkable, and said out loud rather than assumed.** SC-013 proves a display name
is *inert*; nothing proves it is *accurate* or that it does not duplicate a threshold. A digit-match
heuristic was considered and rejected: `p99` legitimately contains `99`, and a check with a false
positive on the most common percentile in the corpus would be turned off within a week.

**Rejected spellings**, for the glossary entry FR-042 owes: `label` — in one surveyed tool a *label*
is the sampler name, i.e. a selector value, so the word already means an address here;
`title` — collides with the document's own title and with JSON Schema's `title`;
`description` — invites paragraphs where a phrase is wanted.

### 1.2 Predicate identity

Not a new field — a rule made explicit and now load-bearing, because the sum rule counts identities.

```
identity(predicate) = predicate.name  if present
                    = predicate.aggregation  otherwise
```

| Rule | Where enforced |
|---|---|
| Unique within a requirement across `criteria` **and** `guards` **together** | Corpus runner, not the schema — JSON Schema cannot express a cross-array uniqueness over a computed key |
| May be a name, matching the format's own `name` pattern, **or** an aggregation — `p99.9` contains a dot and is therefore not a valid name | Wherever an identity is referenced, the type is `anyOf: [name, aggregation]` |

The current gate checks uniqueness **per section**, so a criterion and a guard may collide today.
That is a defect this feature closes, and it needs a corpus case.

### 1.3 Preconditions

`guards` keeps its name in the schema. The rendering carries `role: guard` per entry, which is where
FR-009's repair lives (R1). Nothing about a name in a report survives into the format.

---

## 2. `TargetDescription` — new

`schema/opennfr.io/v1/targetdescription.schema.json`, instances in `mappings/<target>.yaml`.
Supersedes the incumbent `MetricMapping` kind (R9).

### 2.1 Top level

| Field | Type | Required | Meaning |
|---|---|---|---|
| `apiVersion` | const `opennfr.io/v1` | yes | |
| `kind` | const `TargetDescription` | yes | |
| `metadata.name` | name | yes | **The only place a tool name legitimately appears.** SC-004 counts tool names in the format and in requirement documents; this file is neither |
| `spec.evidence` | array, minItems 1 | yes | See 2.2 |
| `spec.native` | object | yes | What a native assertion is made of, here |
| `spec.report` | object | yes | How this target's own report line is derived |
| `spec.units` | array | yes | Conversions, as exact rationals |
| `spec.names` | object | yes | Canonical ↔ native, with the complement declared |
| `spec.assertable` | array, minItems 1 | yes | The capability table |

### 2.2 `evidence` — SC-007 by schema rather than by review

| Field | Type | Meaning |
|---|---|---|
| `id` | name, unique | Cited by every claim |
| `source` | string | Repository path and tag, or URL |
| `checked` | date | `^\d{4}-\d{2}-\d{2}$` |
| `states` | string | **What the source says**, not what was concluded from it |

Every capability claim and every gap carries `evidence: [<id>, …]`, `minItems: 1`. A claim with no
citation is a schema error, which is what turns FR-026 from a habit into a rule.

### 2.3 `native` and `report`

```yaml
native:
  fields: [scope, path, statistic, reduce, percentile, condition, value]  # ordered
  evidence: [assertion-builders]
report:
  derivedFrom: [scope, selection, metric, aggregation, comparison, threshold]
  carriesAuthorName: false        # false on both surveyed targets — R1
  evidence: [assertion-builders, run-result-processor]
```

`native.fields` is declared **per file** so a third target with an unanticipated assertion shape
needs no schema edit (FR-016). The declared order is also the serialisation order, which is half of
FR-015's determinism.

`report.derivedFrom` is load-bearing: **two predicates whose projections onto it are equal are
indistinguishable in that target's report.** That is what makes SC-012 checkable — and what makes it
honest, because the corpus can then say "these two collide" instead of claiming a distinction that
does not exist.

### 2.4 `units` — exact rationals, never floats

```yaml
units:
  - {from: s, to: ms, multiplyBy: {numerator: 1000, denominator: 1}}
```

Integers, `denominator >= 1`. FR-013 requires deciding whether a threshold is *exactly*
representable in the target's own numeric type; floating-point conversion cannot answer that. This
is the field that keeps the three-orders-of-magnitude error from becoming a rounding opinion.

### 2.5 `names`, and the declared complement

`metrics` and `attributes` map canonical → native, each with evidence. `names.unlisted` is
**required**: it says what happens to a canonical name not in the list, per axis, with a reason and
evidence. Without it the infinite complement is undefined, and an unlisted metric would fall through
as *supported* — the wrong default under Principle III.

### 2.6 `assertable` — the capability table

Exact-match lookup on `(shape, metric, side, scope, selections)`, then `aggregations[agg]`, then
`comparisons[op]`. **Nothing is expanded by rule**; there is no inference step for a reader to
simulate.

Two partitions make FR-017 structural rather than aspirational:

- `aggregations` and `aggregationGaps` together partition the aggregation axis;
- `comparisons` and `comparisonGaps` together partition the comparison axis.

A combination in neither half is a **defect of the description**, detectable by the corpus runner —
which is FR-017 stated as an executable rule.

Each aggregation entry carries `parts`, the emitted native assertion identity, built from the
declared `native.fields`. `statistic` may differ per aggregation, which is what the second target's
shape requires.

---

## 3. `Rendering` — new

`schema/opennfr.io/v1/rendering.schema.json`, instances in `conformance/render/<case>/rendering.<target>.yaml`.

### 3.1 Top level

| Field | Type | Required | Meaning |
|---|---|---|---|
| `spec.document` | name | yes | `metadata.name` of the RequirementSet. Resolves **inside the case directory**; never a path |
| `spec.target.description` | name | yes | `metadata.name` of the TargetDescription |
| `spec.target.version` | string | yes | The target's version the literals were read against. MUST equal the description's — a staleness check |
| `spec.target.checked` | date | yes | A pinned literal without a date is an unsourced claim about a third party |
| `spec.predicates` | array, minItems 1 | yes | See below |

### 3.2 `predicates` — one ordered list, not two

**Exactly one entry per predicate, in document order**: for each requirement in order, its `guards`
in order, then its `criteria` in order. `rendered` and `unrenderable` are *projections* of this list,
not separate arrays.

This is the design decision that makes FR-033 hold by construction rather than by arithmetic: there
is no way to spell a predicate that appears twice, and no way to spell one that appears in neither
bucket.

| Field | Type | Meaning |
|---|---|---|
| `predicate.requirement` | name | |
| `predicate.role` | enum `criterion` \| `guard` | **FR-009's repair.** The only place either target can carry the distinction |
| `predicate.id` | `anyOf: [name, aggregation]` | The identity from 1.2 |
| `rendered` \| `unrenderable` | exactly one, `oneOf` | |

### 3.3 `rendered`

`assertions`, `minItems: 1` — *a rendered entry with no assertion is unspellable*. Success by
omission has no syntax here, which is Principle III expressed as a schema constraint.

More than one assertion per predicate is admissible **only** as a conjunction that strictly narrows
the pass condition, and only where the description mandates it (R6).

Each assertion carries the criterion restated in the target's tokens — `metric`, `selector`,
`aggregation`, `percentile`, `op`, `threshold`, `unit` — all normative and all checked. No display
name appears here: the rendering points at a predicate by identity, and a display name is not one. `percentile`
is a number, never the string `"percentile(95)"`.

Then `native.text`: a string, `minLength: 1`, and **no `pattern`, ever**. A pattern is the first line
of a decoder. This half is dated evidence, not an authority — when it disagrees with the tokens
above, the literal is the finding and the tokens are the bug.

### 3.4 `unrenderable`

`reasons`, `minItems: 1`, `uniqueItems`, ordered by `gap`. Each reason cites the gap in the target
description that produced it, so an unrenderable claim is traceable to a declared capability rather
than asserted. The spec's edge cases require the three kinds — missing statistic, missing comparison,
threshold that does not convert exactly — to be distinguishable, and they are distinguishable by
*which axis the gap partitions*, not by a free-text note.

**Cost, recorded**: the reason vocabulary is a closed enum, so a target that fails in a way no code
describes needs a schema change plus a re-review of every existing entry. The alternative — free text
— would lose the traceability check entirely. The enum is the right trade and the churn is real.

---

## 4. The corpus

`conformance/`, three parts, each with a different notion of a case.

| Part | A case is | Expectation lives |
|---|---|---|
| `parse/` | one document that must be accepted or rejected | a sidecar file naming every finding: gate, path, keyword |
| `render/` | a directory holding `document.yaml`, and one `rendering.<target>.yaml` per target | the rendering **is** the expectation |
| `gate/` | a described mutation of a tracked file | the exit code and the line the gate must print |

Two rules that make `parse/` cases readable:

- **one mutation per rejection** — a case differs from a valid document by exactly one change, so
  exactly one rule can be responsible (FR-030);
- **the expectation is a sidecar, never inside the case** — an `expect:` key in the document would
  itself be an unknown field and would mask the finding (FR-031).

`reject/` cases may not live in `examples/`: the gate requires everything there to validate, and the
constitution puts "any field name that appears in a published example" on the compatibility-sensitive
surface.

### 4.1 What the corpus checks that no schema can

| Check | Why it is not a schema constraint |
|---|---|
| Predicate identity unique across `criteria` and `guards` together | Cross-array uniqueness over a computed key |
| The sum rule: every predicate in exactly one bucket | Needs both documents at once |
| Order: rendered entries follow document order | Needs both documents at once |
| Conversion: the threshold recomputed in exact rational arithmetic | Needs the description's `units` and the document's value |
| Gap traceability: an unrenderable reason cites a gap the description actually declares | Needs both documents at once |
| Collision: two predicates with equal `report.derivedFrom` projections | This is SC-012, and it reports a collision rather than failing on one |

---

## Relationships

```text
RequirementSet ──identity──> predicate
      │                          │
      │                          └──> exactly one Rendering entry  (FR-033, structural)
      │
      └──rendered against──> TargetDescription ──declares──> capabilities ∪ gaps  (a partition)
                                     │                              │
                                     └──units (exact rationals)     └──cited by unrenderable reasons
```

One `RequirementSet` has one `Rendering` **per target**. A `Rendering` names its document and its
description by `metadata.name`, resolved inside its own case directory — never by path, so a case can
be moved without editing its contents.
