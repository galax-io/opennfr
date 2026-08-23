# Implementation Plan: Repository Architecture and Operating Principles

**Branch**: `001-nfr-format-architecture` | **Date**: 2026-08-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-nfr-format-architecture/spec.md`

## Summary

Publish how OpenNFR works and where its parts live, and give the project the rules that decide
the arguments the architecture creates — without writing any of it.

Six pull requests in a fixed order: the spec; a glossary settlement that fixes three live word
collisions before anything uses them; a constitution amendment to v1.1.0 adding two principles
and widening one binding constraint; the architecture document with three worked walkthroughs
over `docs/examples/checkout-perf.yaml`; and the layout document naming one home per artifact
class; and the follow-up list appended to it. No schema, no validator, no code, no tool
mapping.

The order is not cosmetic. The constitution says a conflicting document "is wrong and MUST be
fixed", so an architecture document written against unamended text is born wrong; and the
amendment PR may contain nothing but the constitution and the templates it affects, which
forbids it from carrying the glossary entry its own new wording needs. Settling the vocabulary
first is what makes the amendment legal.

## Technical Context

**Language/Version**: None — this feature ships no code. Markdown as GitHub renders it, and
YAML 1.2 restricted to its JSON-compatible subset (`reference/adr/0002-compatibility.md`)
where existing sketches are quoted.

**Primary Dependencies**: OpenTelemetry semantic conventions, as the source of every borrowed
name; this repository's own dated tool survey (`reference/compatibility.md`,
"Verified against documentation as of August 2026").

**Storage**: Files in git. No database, no state.

**Testing**: `bash scripts/verify.sh` — four checks: YAML sketches parse, internal markdown
links resolve, documents contain no non-English text, examples announce themselves as
sketches. Plus one criterion this feature makes literally executable: `git rm -r docs/experimental`
followed by `bash scripts/verify.sh` must stay green (SC-007).

**Target Platform**: A git repository rendered on GitHub; `scripts/check-linkage.sh` in CI.

**Project Type**: Documentation and governance artifacts for a format specification. Not an
application, not a library.

**Performance Goals**: None applicable.

**Constraints**:
- `bash scripts/verify.sh` must pass on every commit; weakening it requires justification in
  the PR, not in the script.
- English only — `verify.sh` fails on any Cyrillic in `*.md` or `*.yaml`.
- FR-025: zero executable artifacts. No schema, validator, parser, renderer or tool mapping.
- The amendment PR contains exactly two files.
- The link check filters `grep -v '^\./\.'`, so anything under a dot-prefixed root directory
  has its outgoing links **unchecked**. The checked set is 12 files today.
- The sketch-label check is hardcoded to `docs/examples/*.yaml`.
- Every PR needs milestone `v0.2.0` and a closing link to an issue in that milestone. **No such
  issue exists yet** — issue creation is task one, not an afterthought.

**Scale/Scope**: The repository holds 168 files, of which **ten** are format artifacts. This
feature adds two documents, one directory with one file, one glossary section, a constitution
amendment across two files, and an eleven-entry follow-up list.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against [constitution.md](../../.specify/memory/constitution.md) v1.0.0. Re-evaluated
after Phase 1 design — result unchanged except where noted.

- [x] **I. Vocabulary Before Features** — Yes, this feature introduces terms, and it also
      *removes* one. Settled by sequencing: the glossary PR lands before any document uses the
      words. `target` gets an entry in Layer 2 with a rejected alternative; the noun `binding`
      is dropped in favour of `tool mapping`; the component sense of `reader` is renamed to
      `file adapter`. Principle I's ordering clause binds a term to reach the glossary "before
      it appears in an example, a schema, or an implementation" — the architecture and layout
      documents are none of those three, so landing the glossary PR first satisfies it with
      room to spare. No ADR is contradicted: adding `Target` to Layer 2 is consistent with
      ADR-0001 § D2, and dropping a word this repository never ratified contradicts nothing.

- [x] **II. Borrow Names, Never Invent Them** — This feature adds no metric and no attribute
      name. The `loadtest.*` registry is unchanged; it is *filed*, not edited. No aliases, no
      derived quantities.

- [x] **III. No Silent Green** — This feature adds no check that can fail to find data, so the
      gate is trivially satisfied for what it ships. It is **not** trivially satisfied for what
      it discovered: the three walkthroughs will expose four silent-green defects that already
      exist in `docs/examples/checkout-perf.yaml` and the gate vocabulary
      ([research.md](research.md) § D7). They are pre-existing, not introduced here. The plan
      files them as issues rather than fixing them, because fixing them changes the format and
      FR-025 forbids that — but leaving them undocumented while writing a walkthrough that
      steps over them would itself be a silent green.

- [x] **IV. Honest Status** — The architecture document carries a split status by FR-013: roles
      and boundaries bind, unbuilt components are marked proposed. Every tool claim traces to
      the dated survey. Two live violations in the specification were found and **fixed during
      planning**: an unmarked elision in the AGENTS.md citation, and an ellipsis swallowing a
      sentence boundary in the compatibility.md citation. One unlabelled knowledge claim about
      Gatling's `simulation.log` columns was caught in research and dropped — nothing committed
      speaks to it.

- [x] **V. Structure Over Grammar** — This feature adds no format field, no value set and no
      construct requiring custom decoding. Trivially satisfied.

- [x] **Compatibility** — No borrowed OTel name is touched. No published example's field name
      is touched: the two mis-filed tool mappings stay where they are, and the layout publishes
      the mismatch instead of moving them. The conformance levels are unchanged. No construct
      is added, so none can be `assert`-only. The amendment **does** widen the Compatibility
      Constraints section — but through the constitution's own amendment procedure, which is
      the sanctioned route for exactly that.

**Which constitution version this gates against**: **v1.0.0**, deliberately. This feature's own
amendment lands mid-sequence as PR 3, so gating against v1.1.0 would check the plan against
text that does not exist. The constitution already requires the check to run "again after
Phase 1 design"; the re-run above used v1.0.0 for the same reason. The first plan to gate
against v1.1.0 is the one after this feature ships.

**One decision the check cannot clear alone** — the fourth candidate principle. Recorded in
Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-nfr-format-architecture/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output — artifact classes, component roles, vocabulary homes
├── quickstart.md        # Phase 1 output — how to verify this feature landed correctly
├── contracts/           # Phase 1 output — the four component-role contracts
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Repository artifacts (what this feature actually changes)

```text
docs/
├── architecture.md      # NEW — how a requirement becomes an outcome; three worked walkthroughs
├── layout.md            # NEW — one home per artifact class, obligations, non-conformance list
├── GLOSSARY.md          # EDITED — adds § Target to Layer 2; drops the noun `binding`
├── experimental/        # NEW directory
│   └── README.md        # NEW — the parked monitoring direction's status page
├── adr/                 # unchanged — decision records
├── examples/            # unchanged — corpus home; also holds two mis-filed tool mappings
├── semconv/             # unchanged — filed into the normative core by layout.md
├── compatibility.md     # unchanged — named in the non-conformance list (spans three classes)
├── units.md             # unchanged
├── references.md        # unchanged
└── README.md            # EDITED — indexes the two new documents

.specify/
├── memory/constitution.md          # EDITED — v1.0.0 → v1.1.0
└── templates/plan-template.md      # EDITED — stale version pointer; new principle gates

README.md                # EDITED — Documents table gains two rows
```

**Structure Decision**: Keep the existing tree and move nothing. AGENTS.md forbids
opportunistic refactors outside scope, and the two tool mappings in `docs/examples/` are linked
from five other documents — moving them turns `verify.sh` red across the tree, and would
additionally slip them out of the sketch-label check, which is hardcoded to that directory.
The layout document publishes six non-conforming entries under FR-013 instead, each with the
obligation its eventual move carries. `mappings/` is declared as the tool-mapping home and
created empty of content by the first target follow-up spec, not here.

`specs/` is explicitly **not** an artifact class and the layout table says so in one sentence —
a newcomer scanning the tree would otherwise read it as holding format artifacts. Flow is
one-directional: a follow-up spec writes into the homes the layout names; it never becomes one.

## Delivery sequence

Six PRs, each with its own issue on milestone `v0.2.0`. The ordering constraint is real, not
stylistic — see Summary.

| # | PR | Contents | Why here |
|---|---|---|---|
| 1 | spec | `specs/001-*/` only | AGENTS.md spec-first; never folded into implementation |
| 2 | glossary | `docs/GLOSSARY.md`, plus the spec's own uses of the settled words | Settles `target` before the amendment needs the word; drops `binding` before the layout uses it |
| 3 | amendment | `constitution.md` + `plan-template.md`, nothing else | The constitution's own procedure. Must precede any document written against it |
| 4 | architecture | `docs/architecture.md`, `docs/experimental/README.md`, index rows | Needs the amended constitution and the settled words |
| 5 | layout | `docs/layout.md`, index rows | Names homes the architecture document already refers to |
| 6 | follow-up list | the follow-up section appended to `docs/architecture.md` | The decomposition is a separate concern from how it works |

## Preconditions — the check that fails first

`.github/workflows/verify.yml` runs `scripts/check-linkage.sh --pr` on every pull request,
gating on milestone `v0.2.0` **and** a registered closing link to an issue in that milestone.
Three issues exist in this repository; all are closed and none covers this work.

Under AGENTS.md's "1 issue = 1 commit", the six-PR sequence needs **six issues opened before
the first PR**, one per row of the table above. This is task one in `tasks.md`, not a
formality — without it CI rejects PR 1 on its face.

Two questions the plan could not decide were answered on 2026-08-18:

- **Milestone fit.** `v0.1.0` covered only the first cut of the notes, so it was tagged,
  released and closed rather than stretched. `v0.2.0` is cut for this feature and is created
  by T001. No open milestone exists until then, which is why `scripts/check-linkage.sh` exits
  2 on every PR.
- **`.specify/feature.json`** is spec-kit runtime state and is now ignored via `.gitignore`,
  so it no longer rides along in the spec commit. The `.gitignore` change travels in PR 1 as
  the enabling edit for that commit.

## Open decisions carried into tasks

Surfaced by the completeness critic, each blocking a specific requirement rather than the plan
as a whole.

| Requirement | What is undecided | Note |
|---|---|---|
| FR-016 | Which side is authoritative when a tool-native integration in another repository drifts from the format | `grep -r authoritative` over `docs/`, `README.md`, `AGENTS.md` and the constitution returns nothing. No committed text answers it. FR-016's own wording asks only for authority to be *stated*, so the layout document must state it — and every detection mechanism is an executable artifact FR-025 forbids, which leaves detection to the conformance-corpus follow-up |
| FR-017 | Whether the layout document republishes the compatibility-sensitive list or points at the constitution's | Republishing creates a second copy that can drift, which the constitution's supremacy clause makes wrong by definition. Pointing is the only safe form; the layout carries a pointer plus the per-class yes/partly/no column |
| SC-014 | What counts as a "statement" | Settled in [contracts/repository-shapes.md](contracts/repository-shapes.md): the unit is a numbered clause or a table row, the marker is a dedicated column or an explicit tag, and unmarked is a defect rather than an implicit `proposed` |
| SC-012 | The construct set it is verified over | This feature admits no new construct, so the criterion is satisfied over an empty set — which is true but hollow. Read it as a standing obligation on later specs rather than a check this feature passes |

## Complexity Tracking

> Filled because one Constitution Check item cannot be cleared without a decision that changes
> the constitution's content.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| Principle VIII "Experiments Are Parked, Not Merged" as drafted would make two committed artifacts retroactively non-compliant, and its own text contradicts the only constitutional bullet that supports it | The author asked for the monitoring direction to be "parked in some form", and FR-018/SC-011 need a rule above them | Shipping as drafted — rejected: the draft says "Unsettled work is contained, not labelled. A warning notice on something load-bearing is not containment", while the nearest committed grounding, Principle III's "Any artifact nothing validates MUST say so in its own text", blesses labelling. `docs/semconv/loadtest.md` and the `errorSignal` sketch in `mapping-k6.yaml` both practise labelling over containment today. Dropping it entirely — viable and costs nothing mechanically, since FR-018 and SC-011 still bind this feature's own artifacts. **Recommended: narrow it to *new* unsettled work and name the two existing artifacts as grandfathered with a dated note** |
| The three walkthroughs cannot be symmetric: `docs/examples/` has `mapping-k6.yaml` and `mapping-jmeter.yaml` and **no Gatling mapping** | SC-002 names three load generators, and Gatling is the internal consumer's tool | Writing a Gatling mapping here — rejected by FR-025, which forbids this feature from shipping a tool mapping. Dropping Gatling from the three — rejected: it is the tool with the named counterparty. The Gatling walkthrough therefore traces from the dated survey alone and declares every gap, and creating the mapping becomes the first deliverable of the `target-gatling` follow-up spec |
| `monitoring backend` was sent to the architecture document by the 2026-08-18 clarification, but collides with `backend`, already used in the glossary in a different sense | FR-012's collision test is mechanical and says the glossary | Honouring the clarification as given — the clarification predates the discovery of the collision, and FR-012's own test overrides it. **Resolution: define it inside the `Target` glossary entry**, where the collision is visible, and have the architecture document cite rather than redefine it. This reverses a stated answer and is flagged for the author |
