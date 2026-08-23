# Phase 1 Data Model: Repository Architecture and Operating Principles

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-08-18

This feature ships no runtime data, so the model here is structural: the things the repository
holds, the roles the architecture names, and the words that identify both. These are the
entities the two new documents are made of.

---

## 1. Artifact class

A kind of thing the repository holds. Exactly one home directory, one rule for changing it.

| Field | Rule |
|---|---|
| `name` | Unique. Named in the layout table |
| `home` | Exactly one directory path. Two homes, or none, is a defect of the layout (FR-015) |
| `who may change it` | Uniform: "Anyone, by pull request". Differences live in obligations, never in permission ([research.md](research.md) § D4c) |
| `obligations` | What changing it requires — the only column that varies between classes |
| `on the compatibility surface` | Boolean. The experimental area is excluded by construction (FR-018) |

### Instances

| Class | Home | Obligations | Compat. surface |
|---|---|---|---|
| Normative core | `docs/` top level, plus `docs/semconv/` | term change updates `docs/GLOSSARY.md` in the same PR with a rejected alternative; naming disagreements argued in an issue first; compatibility-sensitive change requires an ADR | partly |
| Decision records | `docs/adr/NNNN-slug.md` | a PR contradicting an ADR amends it instead; status stays `proposed` until something validates it | no |
| Tool mappings | `mappings/` | claimed conformance level evidenced and dated | no (content); the level ladder itself is |
| Conformance corpus | `docs/examples/` | every file announces itself as a sketch until a schema validates it | field names in published examples are |
| Experimental area | `docs/experimental/` | self-labelling with promotion and retirement conditions; no inbound markdown links; markdown only | **no, by construction** |
| Reference implementation | declared, not created | — | no |

**`specs/` is not an artifact class.** It is the spec-kit working directory. The layout table
says so explicitly in one sentence, because a newcomer scanning the tree assumes otherwise.

**Known unfiled artifact** (FR-015 names it): `docs/semconv/loadtest.md` — an unsubmitted
proposal to an external standards body that core constructs already depend on. Filed in the
normative core with a widened class definition; see [research.md](research.md) § D4b.

---

## 2. Component role

A named job on the path from a requirement to an outcome. Roles are contracts, not modules —
see [contracts/component-roles.md](contracts/component-roles.md) for the full contracts.

**Provenance, because this is the feature's most load-bearing table.** These roles are
**authored here**, not inherited. `reference/compatibility.md` § Layering
lists four layers, but it gives four *responsibilities* and zero contracts — no inputs, no
outputs, no forbidden dependencies — and it sits under `## Requirements for the Go
implementation`, which that document classifies as a proposal. FR-013 makes component roles
**binding**, so inheriting them would rest binding text on a proposal. The layering table is
cited as corroboration; the contracts below are new.

**Reconciliation with the glossary.** `Adapter` already umbrellas two of these roles — the
glossary defines it as doing four jobs, of which rendering assertions is one and collecting a
tool's output is another. Render and Ingest are therefore *sub-roles of `Adapter`*, not rivals
to it, and the architecture document must say so rather than introduce a competing
decomposition, which Principle I forbids. The count of four and the placement of `gate`
inside Evaluate are decisions of this model, corroborated by compatibility.md § Layering. No
requirement fixes either.

| Field | Rule |
|---|---|
| `name` | Unique. Must not collide with a glossary word at another layer |
| `input` | What it is handed |
| `output` | What it returns |
| `forbidden knowledge` | At least one thing it must not depend on (FR-002) |
| `status` | `binding` or `proposed`. No statement may be unmarked (FR-013, SC-014) |

### The four roles

| Role | Input | Output | Must not know |
|---|---|---|---|
| Parse | A document | An object model with unknown fields already rejected, alternatives resolved to one, units present | Which target will consume it |
| Render | Criteria + a tool mapping | The target's native artifact, plus a named list of criteria it could not render | Whether the run will pass |
| Ingest (file adapter) | A target's raw output + a tool mapping | Normalised series under canonical names, in canonical units | What the criteria say |
| Evaluate | Normalised series + criteria + guards | Verdicts, then an outcome through `gate` | Which target produced the measurements, or how |

The fourth row is Principle VI. It is the whole reason one document can mean one thing.

---

## 3. The traced path

The architecture document traces this, three times, over
`docs/examples/checkout-perf.yaml`.

```text
requirement → criterion → verdict → gate → outcome
```

**The endpoint matters.** The specification originally ended the trace at *verdict*, but in
`reference/glossary.md` a `Verdict` is the result of checking **one** criterion;
what a CI job prints is an `Outcome`, the aggregated result of the whole run. Ending at
`verdict` stops one component short of `gate` — which User Story 1's own acceptance scenario
requires to be named. See [research.md](research.md) § D5.

---

## 4. Vocabulary entry

Every word this feature introduces, with exactly one home (FR-012, SC-013).

| Field | Rule |
|---|---|
| `word` | The term |
| `home` | `glossary` if it collides with a word already in `docs/GLOSSARY.md`; `layout` otherwise. Never both |
| `definition` | One line |
| `rejected alternative` | Mandatory, with the reason. This is the durable part |

### Words settled in the glossary — they collide

| Word | Collides with | Disposition |
|---|---|---|
| `target` | "target load" in the Requirement entry; OpenSLO's `target` field | New `### Target` in Layer 2. Runtime, between `### Assertion` and `### Adapter`. No fourth layer |
| `monitoring backend` | `backend`, already used for the thing that evaluates after the run | Defined **inside** the `Target` entry as its second class. Reverses the 2026-08-18 clarification, which predates the discovery of this collision |
| `binding` | `MetricMapping`; and `binding` is already load-bearing as an adjective meaning normative | **Dropped.** The artifact class becomes `tool mapping` |

### Words defined in the layout document — no collision

`artifact class`, `home`, `normative core`, `compatibility-sensitive surface`,
`experimental area`, `follow-up spec`, `obligation`, `non-conformance list`. Each carries its
own rejected alternative.

### Words fixed, not introduced

| Word | Problem | Fix |
|---|---|---|
| `reader` | Two senses — a human (SC-001, US1, eight occurrences) and a software component | The component becomes `file adapter`; `reader` stays human |
| `interpreter` | A straight synonym of the glossary's `Adapter` | Dropped outside the quoted user input. The architecture document states plainly that it means `Adapter`, whose sub-roles are `renderer` and `file adapter` |
| `source` | Four committed senses | Always written `data source` in full; never the bare noun |
| `data source` | Inherited, not introduced (ADR-0002 § D18) | Cited, never redefined |

---

## 5. Document status

Applies to every document this feature produces (FR-013).

| Value | Meaning |
|---|---|
| `binding` | Later specs must obey it. Component roles, forbidden dependencies, follow-up boundaries |
| `proposed` | Describes something that does not exist yet |

No statement may be unmarked (SC-014). Amending a binding statement is an ordinary PR landing
before the diverging spec — **no decision record required**, because the architecture document
is not on the compatibility-sensitive surface (FR-023). The sanctioned route has to stay
cheaper than the workaround, or people take the workaround.

---

## 6. Follow-up entry

One future spec. Named by **slug, never by ordinal** — `specs/NNN-` records creation order, not
completion order.

| Field | Rule |
|---|---|
| `slug` | Unique |
| `delivers` | Concrete files. The unit of claim under FR-022 — a file, not an artifact class |
| `depends on` | Other slugs. Stated explicitly, never implied by numbering |
| `role` | Which component role it implements |
| `scheduling` | `scheduled`, or `parked` with promotion and retirement conditions in place of a position (SC-011) |

**Disjointness invariant**: no individual deliverable appears in two entries (SC-008). At
artifact-class granularity the list would be unwritable — the schema, the object model and the
corpus all add to the normative core, which is exactly why FR-022 names the file as the unit.

---

## 7. Non-conformance entry

The layout document publishes what is currently mis-filed rather than moving it (FR-013).

| Field | Rule |
|---|---|
| `path` | The file |
| `class it belongs to` | Where the layout says it should live |
| `why not moved` | AGENTS.md forbids opportunistic refactors outside scope |
| `obligation attached to the eventual move` | What the move must also do |

The two sharpest entries, and the reason the list exists rather than a rename commit:

- `docs/examples/mapping-k6.yaml`, `docs/examples/mapping-jmeter.yaml` — tool mappings sitting
  in the corpus home. Linked from five other documents, so a move turns `verify.sh` red across
  the tree. **Hidden obligation**: `verify.sh`'s sketch-label check is hardcoded to
  `docs/examples/*.yaml`, so mappings relocated to `mappings/` silently stop being checked
  until the script is extended.
- `docs/compatibility.md` — spans three classes by its own admission: conformance levels
  (normative), the tool survey (evidence), the Go notes (proposal).
