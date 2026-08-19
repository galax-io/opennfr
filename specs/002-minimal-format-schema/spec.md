# Feature Specification: A Minimal Format, Defined by Schema

**Feature Branch**: `001-nfr-format-architecture` (shared with 001; the change is in PR #10)

**Created**: 2026-08-19

**Status**: Implemented — written after the change, to record what it decided

**Input**: "Spec what has just changed in the branch."

> This is a **retrospective** specification. The work is done and green; this records the
> decisions it took so a later reader does not have to reconstruct them from a diff.

## Context

Feature 001 published an architecture and a layout, but left two things wrong.

**`docs/` was holding things that are not ideas.** The architecture and layout documents
describe the project; they are not notes about it. `docs/` is a notebook.

**The format was prose with a list of metrics.** That is backwards. The format is a
*container*; metrics are what you write into it. Worse, prose cannot be checked — so the notes
had been carrying a wrong rule and an invalid example for the life of the project without
anyone noticing.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Someone writes a requirement and finds out immediately if it is wrong (Priority: P1)

An engineer writes a performance requirement, runs one command, and learns whether it is a
valid document — not whether it looks like the examples.

**Why this priority**: it is the difference between a format and a description of a format.
Everything else in this change exists to make this possible.

**Independent Test**: write a document with a misspelled field; the check fails and names the
field. Write a valid one; it passes.

**Acceptance Scenarios**:

1. **Given** a requirement document, **When** the check runs, **Then** it either passes or
   names the exact path of what is wrong.
2. **Given** a document with an unknown field, **When** the check runs, **Then** it fails —
   a typo is never a silently skipped criterion.
3. **Given** a document with a number and no unit, **When** the check runs, **Then** it fails.

---

### User Story 2 - A reader can tell a rule from an opinion (Priority: P2)

Someone opening the repository can tell, without asking, which files bind and which are one
person's thinking.

**Why this priority**: the repository is a notebook that is becoming a project. A reader who
cannot tell the two apart will either build on an opinion or ignore a rule.

**Independent Test**: open any file under `docs/`; it says it is a note. Open anything at the
root; it does not.

**Acceptance Scenarios**:

1. **Given** any file in the notebook, **When** it is opened, **Then** its first lines say it
   is a note and point at the format.
2. **Given** the project's own documents, **When** a reader looks for them, **Then** they are
   at the repository root, not in the notebook.
3. **Given** an idea that has been accepted, parked or rejected, **When** that lands, **Then**
   the note about it is deleted in the same change.

---

### User Story 3 - The format cannot drift away from its own example (Priority: P3)

A change to the format that breaks a published example fails the build.

**Why this priority**: examples are how everyone learns the format. An example that no longer
matches the format teaches the wrong thing, silently.

**Independent Test**: remove a required field from the schema's example; the build goes red.

**Acceptance Scenarios**:

1. **Given** the validated example, **When** the format changes incompatibly, **Then** the
   build fails.
2. **Given** a document kind with no schema yet, **When** the check runs, **Then** it says so
   out loud rather than passing over it.

### Edge Cases

- **The validator is missing.** The check would skip, and a skipped gate reads exactly like a
  passing one. This must fail instead.
- **A value has no JSON equivalent.** An unquoted timestamp becomes a date object in YAML,
  which cannot round-trip through JSON — and the format requires that it can.
- **An older sketch uses constructs the format does not have.** It is an idea, and must not be
  judged as if it were a document.

## Requirements *(mandatory)*

### The container

- **FR-001**: The format MUST be defined by a schema, not by prose. Prose may explain it; the
  schema decides.
- **FR-002**: The schema MUST NOT enumerate metric or attribute names. Measuring something new
  MUST NOT require changing the format.
- **FR-003**: The container MUST be minimal. A construct that adds a dependency the format
  cannot honour, or a knob nobody has asked for, MUST stay an idea until asked for.
- **FR-004**: Unknown fields MUST be rejected everywhere.
- **FR-005**: A number MUST carry a unit.
- **FR-006**: The format MUST NOT define a document kind that nothing produces yet. A result
  document, and a document binding the format to a tool, arrive when something needs them —
  a guess written into a schema is harder to withdraw than a guess written in a note.

### The notebook

- **FR-007**: Every file in the notebook MUST say, in its own text, that it is a note and not a
  rule.
- **FR-008**: The project's own documents MUST NOT live in the notebook.
- **FR-009**: A note MUST be deleted in the same change that accepts, parks or rejects the idea
  it records.

### The gate

- **FR-010**: Published examples MUST be validated against the schema on every commit.
- **FR-011**: A document kind with no schema MUST be reported as such, not passed over.
- **FR-012**: The gate MUST fail rather than skip when its validator is unavailable.
- **FR-013**: Every value in a published document MUST have a JSON equivalent.

## Key Entities

- **Container** — the shape a document is written in. Fixes structure, borrows vocabulary.
- **Note** — an idea in the notebook. May contradict the format; that is what notes are for.
- **Validated example** — a document that must satisfy the schema, so the format cannot drift
  away from what it teaches.
- **Sketch** — an older illustration that uses constructs the format does not have. An idea.

## Success Criteria *(mandatory)*

- **SC-001**: A misspelled field in a requirement document is caught, and the report names its
  path.
- **SC-002**: The number of metric names enumerated in the schema is zero.
- **SC-003**: The whole container is one file, under 6 KB.
- **SC-004**: Every file in the notebook carries a note marker — 100%, verifiable by grep.
- **SC-005**: Every validated example passes on every commit; a format change that breaks one
  turns the build red.
- **SC-006**: A document kind without a schema produces a visible line rather than silence.
- **SC-007**: Removing the validator turns the build red rather than green.
- **SC-008**: The number of constructs in the container that no tool can satisfy is zero.
- **SC-009**: The number of document kinds defined that nothing yet produces is zero.

## What this change decided

Recorded because the reasoning is not recoverable from the diff.

| Decision | Why |
|---|---|
| The container carries an envelope, a requirement, an indicator, a predicate and guards — nothing else | Everything cut was either a dependency nothing can honour or a knob nobody asked for |
| `window`, `baseline`/`tolerance`, `severity`/`gate`, `enforcement`/`onViolation`, `defaults`, `indicatorRef` are ideas, not fields | Two rest on things that do not exist; the rest are sugar or policy |
| Guards stay | Without them the format is a wrapper over thresholds. A run that under-delivered its load shows a green percentile and a false verdict, and nothing else in the container catches that |
| Validated examples live apart from sketches | A sketch may exceed the format; an example may not. Judging both by one rule makes one of them useless |
| A result document and a tool binding are **not** defined | Nothing produces either yet. Inventing a container for output before anything computes output is guessing, and a guess in a schema costs more to withdraw than a guess in a note |

### Three defects the schema found that prose had hidden

1. **The unit rule was wrong.** The notes said a unit is always mandatory. When the bar is a
   baseline plus a tolerance, the tolerance carries the unit and the predicate needs none — and
   the published example had none. The rule was fixed, not the example.
2. **A published example was not valid.** Its timestamps were unquoted, so they parse as dates
   rather than strings, which cannot survive a round trip through JSON — a rule the project had
   written down and never enforced.
3. **A gate that skips itself is not a gate.** Validation is skipped when its validator is
   missing, which in a fresh environment means always.

## Assumptions

- The cut constructs remain wanted. They are argued in the notebook and return through the
  schema when someone needs them, not before.
- Existing sketches keep constructs the container lacks. They are ideas; that is allowed.
- A vocabulary of units stays an idea until ratified; until then any non-empty unit parses.
- This specification is written after the fact and changes nothing. Its value is the record of
  what was decided and why.
