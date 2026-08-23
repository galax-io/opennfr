# Feature Specification: Strip the repository to the schema, the examples and the fields

**Feature Branch**: `004-strip-to-schema`

**Created**: 2026-08-22

**Last updated**: 2026-08-23

**Status**: Ready for planning

**Input**: User description: "I do not understand what layout / architecture are for. They read as a thousand characters of nothing, carry no load, and only confuse. Cut to the root: the repository should hold a schema, examples, and a description of the fields. I am also not sure how the project will develop from here, which is why I already asked to cut everything down to a minimum and keep minimal examples that are currently compatible with Gatling only."

## Why this is being done

The repository's only artifact is one JSON Schema of 12.7 KB. Around it sit 196 KB of prose,
of which **66.6 KB describes no field of the format at all**: `ARCHITECTURE.md` (19.3 KB) on
components that do not exist, `LAYOUT.md` (13.9 KB) on artifact classes that are mostly empty
directories, the constitution (26.1 KB) and `AGENTS.md` (7.2 KB).

Two of those documents already say, in their own text, that they are wrong:

- `ARCHITECTURE.md` § 1 clause 3 carries a **superseded** marker and instructs the reader not to
  apply it. Its § 4 walkthroughs are written against `indicator`, `gate`, `onViolation`,
  `window`, `baseline` and `indicatorRef` — six constructs the schema rejects. Issue #35 has been
  open against §§ 1–7 since the constitution changed under it.
- `LAYOUT.md` § 1 lists nine artifact classes, three of which (`mappings/`, `conformance/`, a
  reference implementation) do not exist. Its § 2 defines eleven governance words for a
  repository holding one schema.

### What a comparable project actually carries

Checked against `github.com/OpenSLO/OpenSLO` on **2026-08-22**, because this repository's own
survey names OpenSLO as its nearest relative:

```
README.md               30.5 KB   the specification itself: 7 object types, field by field,
                                  each with a Notes subsection
glossary/README.md       3.1 KB   terms, definitions only
enhancements/v2alpha.md  9.3 KB   proposals not yet in the format
examples/               ~15 KB    three cases, each a directory with YAML and its own README
CONTRIBUTING.md          2.0 KB
CODE_OF_CONDUCT.md       5.3 KB
```

There is **no JSON Schema in that repository at all** — validation lives in a separate SDK. There
is no architecture document, no layout document, no constitution, no governance vocabulary.

| | OpenSLO | OpenNFR today |
|---|---|---|
| Object types specified | 7 | 1 |
| Prose | ~57 KB | **196 KB** |
| Prose describing no field of the format | 0 | **66.6 KB** |

Four files in this repository outweigh the whole of OpenSLO, for one seventh of the surface.

**The finding that matters is not "less prose".** OpenSLO's README alone is larger than this
repository's. A specification *is* prose, and a field deserves paragraphs. The difference is that
every byte of OpenSLO's prose describes something that exists. That is the bar this feature
adopts.

## The target shape

```
README.md          the specification: what the format is, every field, examples inline
schema/            the JSON Schema — kept, and the one place this project is ahead
examples/          two or three cases, only what Gatling can assert
GLOSSARY.md        terms, definitions and rejected alternatives — small
docs/ideas.md      one file: what was considered and did not go in
CONTRIBUTING.md    how to propose a change
```

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Someone lands on the repository and finds the format (Priority: P1)

A performance engineer opens the repository for the first time. They want to know what a
requirement document looks like, what every field means, and whether a document of their own is
valid. They should reach all three from the entry document, without opening a second directory,
and without reading a sentence about machinery that does not exist.

**Why this priority**: This is the only reason the repository is public. At present the
supporting material outweighs the format by eight to one, and a quarter of it describes nothing
in the format.

**Independent Test**: Hand the repository to a reader who has never seen it, ask them to write a
valid document, and observe which files they open. Delivers value alone: removing the documents
that mislead makes the remainder correct even if nothing else is done.

**Acceptance Scenarios**:

1. **Given** a reader at the repository root, **When** they look for what the format is, **Then**
   one document describes it and describes its fields, with no second document restating either.
2. **Given** a reader following any link from that document, **When** they arrive, **Then** the
   page describes something that exists — never a component, directory, construct or conformance
   level that is proposed, superseded or empty.
3. **Given** a document written by that reader, **When** they run the repository's single check
   command, **Then** they learn whether it is valid, with a message naming the field.

---

### User Story 2 - The examples are only what a real tool can assert (Priority: P1)

The published examples address endpoints by `http.route`. No load generator emits a route, and
Gatling — the only target with a named counterparty waiting — cannot address one: its assertion
scope is a path of recorded group and request names and nothing else. A newcomer copying the
published example writes a document no available tool can run.

**Why this priority**: An example nothing can execute is worse than no example. It teaches a
shape, and the shape is unusable.

**Independent Test**: Check every predicate in the corpus, one by one, against the dated record
of what Gatling's assertion DSL exposes.

**Acceptance Scenarios**:

1. **Given** any example in the corpus, **When** each predicate is compared against Gatling's
   assertion capabilities, **Then** every one maps to a native assertion, with none left over.
2. **Given** an example that addresses requests, **When** its selector is read, **Then** it uses
   only a selection Gatling can express: the whole run, one request name, or a group name with a
   request name.
3. **Given** the corpus, **When** a reader reads it, **Then** each document answers a question
   the others do not — a case, not a catalogue of fields.

---

### User Story 3 - The repository is small enough to restart from (Priority: P2)

The project's direction is not settled. Whatever it becomes, the next decision is easier against
a repository whose content can be held in mind than against one whose governance outweighs its
artifact.

**Why this priority**: Real, but it follows from the first two. A reader is served by P1 and P2;
this serves the author.

**Independent Test**: Count the files that must be edited to change what one field means.

**Acceptance Scenarios**:

1. **Given** a change to one field of the schema, **When** the author looks for every place
   describing it, **Then** there is exactly one place besides the schema.
2. **Given** the repository, **When** its prose is read end to end, **Then** every page describes
   the format, the terms it uses, or an idea explicitly marked as not in it.

---

### Edge Cases

- **A deleted document is cited by one that stays.** `ARCHITECTURE.md` is named five times by the
  constitution, including by Principle VII, which requires every change adding a component to name
  the architectural role it fills. Deleting it leaves that principle binding against nothing —
  exactly as Principle I pointed at a moved glossary one change ago.
- **A deleted document is the only home of a live rule.** `LAYOUT.md` alone carries the rule that
  a note is deleted once it becomes a rule, the route from an idea into the schema, and the
  procedure for adding a target. Each either moves or is dropped deliberately.
- **The corpus loses the case it was the only record of.** `examples/six-statements.yaml` exists
  to prove the format can say everything the previous per-tool format could. Reducing it must not
  quietly drop the statement that was its point.
- **A name the corpus depends on loses its definition.** `loadtest.request.name` and
  `loadtest.group.name` are not OpenTelemetry names, and after this feature they are the *only*
  way the corpus can address a request. Their definition cannot be deleted along with the registry
  that proposed them.
- **The gate references a file that no longer exists.** `scripts/verify.sh` checks links, sketch
  labels and the isolation of the ideas area. After the cut each section must still be checking
  something, or fail loudly — never report success on an empty scan.
- **A published issue is orphaned.** Issues #35, #36, #39, #43 and #46 are argued against
  documents or scripts this feature changes or deletes. Deleting a document does not close the
  argument it carried.

## Requirements *(mandatory)*

### What is removed

- **FR-001**: The repository MUST NOT contain `ARCHITECTURE.md`.
- **FR-002**: The repository MUST NOT contain `LAYOUT.md`.
- **FR-003**: No surviving file may reference a removed document — not as a link, not as a path
  in prose, and not as an obligation that depends on it existing.
- **FR-004**: Any rule that exists **only** in a removed document MUST be either carried into a
  surviving document or dropped by an explicit decision recorded in the change. A rule MUST NOT
  disappear as a side effect.

### What remains

- **FR-005**: The repository MUST contain the schema, a corpus of valid example documents, and a
  description of every field. These three are the deliverable; everything else is justified
  against them or removed.
- **FR-006**: Exactly **one** document MUST describe the fields. The two that currently do —
  `README.md` and `schema/README.md` — MUST be merged into one rather than cross-referenced.
- **FR-007**: That document MUST cover every field the schema defines, every enumerated value it
  permits, and every combination it rejects.
- **FR-008**: The repository MUST retain a single command that validates the corpus against the
  schema and fails when a document stops validating.
- **FR-009**: Every check in that command MUST still be checking something after the cut, or MUST
  fail rather than report success on an empty scan.

### The corpus

- **FR-010**: Every predicate in every published example MUST be assertable by Gatling, judged
  against a dated record of what Gatling's assertion DSL exposes.
- **FR-011**: A selector in a published example MUST address only the whole run, one request
  name, or a group name with a request name. `http.route` and every other attribute Gatling
  cannot reach MUST NOT appear in the corpus.
- **FR-012**: A published example MUST NOT use `sum`, `neq`, or a metric other than request
  duration, none of which Gatling's assertion DSL can express.
- **FR-013**: The corpus MUST be two or three documents, each presenting a **case** — a question a
  reader might actually have — rather than a catalogue of available fields.
- **FR-014**: The format itself MUST NOT be narrowed to what Gatling can assert. The schema
  continues to permit `http.route`, `sum` and `neq`; only the **published corpus** is restricted,
  and the field description MUST state which parts of the format no available target can run.

### What the removed documents leave behind

- **FR-015**: `GLOSSARY.md` MUST hold the terms, their definitions, and the rejected alternative
  for each. It MUST NOT restate what the field description says. Target size is the order of
  OpenSLO's glossary — a few kilobytes, not the current 12.9 KB.
- **FR-016**: `docs/ideas.md` MUST be a single file naming every construct considered and left
  out, with a sentence of reasoning and what would have to become true first. It replaces the four
  files currently under `docs/` and the sketches beside them.
- **FR-017**: The material now under `reference/` MUST be disposed of as follows, with nothing
  left in a directory of its own:
  - the unit list and its conversions, and the OpenTelemetry names a document should write,
    MOVE INTO the field description;
  - the vocabulary MOVES INTO `GLOSSARY.md`, reduced per FR-015;
  - the arguments in the three decision records that justify a **live** field — no string DSL, a
    mandatory unit, a closed unit enumeration, borrowed names, selection written once — MOVE INTO
    the field description as per-field notes, in the manner OpenSLO uses. The rest is dropped.
  - the dated finding that **no load generator publishes semantic convention names**, and the
    dated record of what Gatling can assert, MOVE INTO the field description, since FR-010 and
    FR-014 both depend on the second one being stated somewhere;
  - the prior-art survey is dropped, apart from the paragraph in the entry document explaining why
    none of the surveyed formats was adopted.
- **FR-018**: `loadtest.request.name` and `loadtest.group.name` MUST be defined in the field
  description, together with the statement that they are not OpenTelemetry names and that the
  corpus depends on them. The rest of the proposed `loadtest.*` registry moves to `docs/ideas.md`.
- **FR-019**: The published governance layer MUST be reduced to a `CONTRIBUTING.md` of roughly
  two kilobytes saying how to propose a change. The constitution MUST lose Principle VII, which
  binds against the architecture document being deleted, and MUST lose every clause naming a
  document, directory or artifact class that no longer exists.
- **FR-020**: The change MUST record what each removed document was for and why it is gone, so
  that a later decision to rebuild any of it starts from the argument rather than from the git
  history.
- **FR-021**: Every open issue argued against a removed document MUST be closed with a reason or
  restated against what remains.

### Key Entities

- **The schema**: one JSON Schema file defining `RequirementSet`. The single artifact, and the one
  thing OpenSLO does not have. Unchanged by this feature — no field added, removed or narrowed.
- **The field description**: one document explaining every field, its permitted values, the
  combinations the schema rejects, and — per field, where it earns it — why the field is shaped
  that way. The entry point and the specification, in the shape OpenSLO's README uses.
- **The corpus**: two or three case documents that validate against the schema on every commit and
  map one-to-one onto assertions Gatling can run.
- **The gate**: one command that validates the corpus and fails loudly when it cannot run.
- **A Gatling assertion**: a scope (whole run, request name, or group and request name), a
  statistic (response time, request counts, requests per second), a reduction, a comparison and a
  value. The boundary of what the corpus may contain.

## Success Criteria *(mandatory)*

- **SC-001**: A reader who has never seen the format can write a valid document and confirm it is
  valid, having opened at most three files.
- **SC-002**: Every published example maps entirely onto Gatling assertions — zero predicates left
  over, checked predicate by predicate against a dated capability record.
- **SC-003**: Changing what one field means requires editing exactly two files: the schema and the
  field description.
- **SC-004**: **Every page of prose in the repository describes the format, a term it uses, or an
  idea explicitly marked as not in it.** No page describes a component, directory, construct or
  conformance level that does not exist. This replaces a byte-count target: OpenSLO's own README
  is larger than this repository's entry document, and a specification is allowed to be long — it
  is not allowed to be about nothing.
- **SC-005**: The prose that describes no field of the format goes from 66.6 KB to the size of one
  `CONTRIBUTING.md`.
- **SC-006**: Every link in every surviving document resolves, and every check in the gate reports
  what it scanned rather than reporting success on nothing.
- **SC-007**: Every rule that lived only in a removed document is accounted for — carried forward
  or explicitly dropped — with none unaccounted for.
- **SC-008**: The repository top level lists at most six entries a reader has to consider, and each
  one is either the format, the schema, the examples, the terms, the ideas, or how to contribute.

## Assumptions

- **The schema is not touched.** The user asked to cut documentation, not to change the format. No
  field is added, removed or narrowed, and no document already valid becomes invalid.
- **"Gatling-compatible" means assertable by Gatling's native assertion DSL**, judged against the
  capability record dated 2026-08-20 and sourced from Gatling v3.15.1: assertion scope is `Global`,
  `ForAll` or `Details(parts)`; response time offers min, max, mean, stdDev and percentile;
  `allRequests`, `failedRequests` and `successfulRequests` offer count and percent;
  `requestsPerSec` is a target; conditions are lt, lte, gt, gte, between, around, deviatesAround,
  is and in — with no negation, no sum, and no abort.
- **Restricting the corpus is not restricting the format.** Gatling being the only target with a
  waiting counterparty makes it the right bar for what the repository *publishes*.
- **The spec-kit tooling under `.specify/` and the agent instruction files stay**, reduced to match
  the repository they describe. They are working files in active use, not published documentation,
  and deleting them would break the workflow this specification was written with. If they should go
  too, say so — it is a one-line change to FR-019.
- **The gate stays.** Without it the corpus silently stops validating, which is the one failure the
  whole format argues against.
- **`LICENSE` stays**, being neither documentation nor governance.
- **Deleting a document does not settle the argument it carried.** Issues opened against a removed
  document are closed with a reason, not left pointing at nothing.

## Dependencies

- **Constitution amendment**, required by FR-019 and larger than the last one: Principle VII goes,
  and every clause naming `ARCHITECTURE.md`, `LAYOUT.md`, `reference/` or an artifact class goes
  with it. The constitution is cited five times by the documents being removed and cites them back.
- **Open issues #35 and #36** are argued against `ARCHITECTURE.md`, `LAYOUT.md` and the glossary;
  **#39** against a claim in `reference/units.md`; **#43** against a workaround in
  `schema/README.md`; **#46** against `.copier-answers.yml` regenerating `AGENTS.md`. Each is
  closed with a reason or restated (FR-021).
- **The Gatling capability record** that FR-010 judges against is not currently a committed file.
  It exists in this repository's git history, dated and sourced. Planning must decide whether it is
  restored as data or restated as a paragraph in the field description.
