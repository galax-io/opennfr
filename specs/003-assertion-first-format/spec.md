# Feature Specification: An Assertion-First Requirement Format

**Feature Branch**: `003-assertion-first-format`

**Created**: 2026-08-19

**Status**: Draft — thinking material, not a plan of record

> **What is actually built, as of 2026-08-21.** One slice: `displayName` and `examples` on the
> RequirementSet schema. Nothing else here exists — no target description, no rendering, no
> corpus, no amendment to the constitution or the architecture. Read this as the argument for
> where the format could go and what each step would cost, not as a description of the
> repository.

**Input**: User description, translated from the Russian original — ADR-0001 settled on English for
everything published, so it is recorded here in English rather than quoted:

> Rethink the NFR format on top of OpenNFR. Make it a good-looking format, compatible with Gatling,
> for insertion as assertions. Reports and conformance checking are not wanted for now — those should
> be done by the load testing tool itself. The format must also not be tied hard to Gatling: the point
> is a general format that can be reused.

Prior art this supersedes:
`https://github.com/galax-io/gatling-picatinny/blob/main/docs/assertions.md`.

**Scope note.** All work is inside this repository. Nothing here is a deliverable in, or a
prerequisite for, any other project. picatinny's NFR-YAML appears only as evidence — it is the
closest existing thing to what is being designed, and what it got wrong is the cheapest available
source of requirements.

## Context

Two things force a rethink at the same time, and they point the same way.

**The closest existing thing to this format is a dead end, and it is worth reading why.** The
NFR-YAML that Gatling users write today is a format whose keys are Russian-language sentences — the key for the 99th percentile of response time is a
six-word phrase in Russian — over a closed list of six supported requirement kinds, with thresholds as
quoted strings and an `all` key meaning "every request". That format cannot be extended: a new
statistic means a new key in a hardcoded table. It is also unreadable outside one language, which is
what makes the six-kind ceiling permanent rather than temporary. Its six statements are nonetheless
the best evidence available of what people actually want to assert, which is why they reappear below
as a coverage bar rather than as a migration obligation.

**OpenNFR is currently built around a component nobody asked for.** Today's design routes a document
through normalised series → verdicts → gate → outcome → a result document. None of that exists, and
the user's instruction is that none of it is wanted: the load tool already computes the statistics,
already evaluates its own assertions, and already prints its own report. Keeping a parallel evaluation
path means re-deriving percentiles the tool has already derived, and answering "why does OpenNFR say
p95 = 480 ms when Gatling says 502 ms" forever.

So the document's job **ends when it becomes the target's own assertions**. Everything after that
belongs to the target.

This does not make the format a Gatling file. It makes the format the one place a requirement is
written, and rendering the only thing that is per-tool. `ARCHITECTURE.md` already carries the four
roles; this feature keeps **R1 Parse** and **R2 Render** and takes **R3 Ingest** and **R4 Evaluate**
out of scope, along with everything downstream of them.

A useful finding sits behind that decision: the container defined in feature 002 already fits
Gatling's assertion surface almost exactly. A `ratio` with a `bad` selector is
`failedRequests.percent`; with a `good` selector it is `successfulRequests.percent`; `total` is
`allRequests`; `rate` over a distribution is `requestsPerSec`; `avg` is `mean`; `p95` is
`percentile(95)`. Three things do not fit; all three are settled in
[Decisions taken](#decisions-taken-during-specification), and the evidence for them is in
[Appendix A](#appendix-a-what-gatling-can-actually-assert).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A requirement becomes a Gatling assertion, with no tool named in it (Priority: P1)

A performance engineer writes a requirement in the format, and it becomes an assertion Gatling can
run — failing the build on exactly the condition the engineer wrote, without a single tool name
appearing anywhere in the document.

**Why this priority**: this is the whole feature. Every other story is a property of the thing it
produces.

**Independent Test**: take the six statements the existing NFR-YAML could express, express each one
in an OpenNFR document, and show the assertion each becomes. Six for six, or the format is narrower
than the thing it replaces.

**Acceptance Scenarios**:

1. **Given** a requirement on the 95th percentile of response time for one named request, **When** it
   is rendered for Gatling, **Then** it becomes an assertion on that request's 95th percentile, with
   the threshold converted into the unit the tool expects.
2. **Given** a requirement on the percentage of failed requests across all requests, **When** it is
   rendered for Gatling, **Then** it becomes an assertion on the failed-request percentage over the
   whole run.
3. **Given** a document that names no tool anywhere, **When** a reader looks for one, **Then** there
   is none — not in a field name, not in a value, not in a metric name.
4. **Given** the old NFR-YAML and the OpenNFR document for the same requirement, **When** both are
   read by someone who does not read the language the old keys are written in, **Then** only one of
   them is readable.

---

### User Story 2 - The same document is reused for a different tool, unedited (Priority: P2)

The engineer switches from Gatling to k6, or runs both. The requirement document does not change. Only
the choice of target does.

**Why this priority**: this is what makes the format worth having rather than a tidier NFR-YAML. It is
second only because story 1 can ship and be useful before a second target exists — but if story 2 turns
out to be impossible, story 1 was a wasted format.

**Independent Test**: render one unchanged document for two independent targets and compare what each
one asserts. The two lists of assertions differ; the document does not.

**Acceptance Scenarios**:

1. **Given** one requirement document and two targets, **When** each is rendered, **Then** both
   renderings come from the same file with no per-tool section, override, or conditional in it.
2. **Given** a target whose vocabulary differs from the document's, **When** it is rendered, **Then**
   the correspondence lives in that target's own description and not in the requirement.
3. **Given** a new target nobody has integrated, **When** support for it is added, **Then** what is
   added is a description of that target, not a change to the format or to any existing document.

---

### User Story 3 - A requirement the target cannot assert is named, never dropped (Priority: P3)

The engineer writes a requirement their tool cannot check. They are told so, by name, **before the run
starts** — not by a green result at the end.

**Why this priority**: it is the project's founding principle applied to the one component that
survives this rethink. A dropped criterion is a check that never ran and a run that looks clean. It is
P3 only because it is a property of rendering rather than a separate capability.

**Independent Test**: write a document mixing renderable and unrenderable criteria. Every criterion
appears in exactly one of two lists, and the counts add up to the number of criteria in the document.

**Acceptance Scenarios**:

1. **Given** a criterion the target cannot express, **When** the document is rendered, **Then** the
   criterion is named and the reason is given, and no assertion is produced for it.
2. **Given** a criterion the target can express only approximately, **When** it is rendered, **Then**
   it is reported as unrenderable — an approximation is never substituted for it.
3. **Given** a rendering, **When** the rendered and unrenderable criteria are counted, **Then** the sum
   equals the number of criteria in the document. There is no third bucket and no silent remainder.
4. **Given** a target description that fails to declare a gap, **When** rendering hits it, **Then**
   that is a defect in the description, and it surfaces rather than being absorbed.

---

### User Story 4 - A reader can predict the assertions before running anything (Priority: P4)

Someone who has never seen the tooling reads a requirement document and a target's description, and can
say what will be asserted and against what number.

**Why this priority**: this is the "make it good-looking" requirement, stated so it can be tested. A
format whose effect cannot be predicted from reading it is a configuration file, not a specification.
P4 because it constrains how the first three are built rather than adding anything of its own.

**Independent Test**: give a reader a document and a target description, ask them to write down the
assertions; compare with what is actually produced.

**Acceptance Scenarios**:

1. **Given** a requirement, **When** it is read aloud, **Then** it states what is measured, over which
   requests, how it is reduced to a number, how that number is compared, and in what unit — and
   nothing else.
2. **Given** any value in the document, **When** it is read, **Then** it is a plain scalar or a
   structure, never a string that has to be parsed to be understood.
3. **Given** a threshold, **When** it is read, **Then** its unit is written next to it and not implied
   by the tool that will consume it.

---

### User Story 5 - Every rule the format states about itself is checked by machine (Priority: P2)

Someone changes the schema, the corpus, or the gate, and finds out from the build whether they broke
a rule the project had written down — rather than from a reader noticing months later.

**Why this priority**: shares P2 with story 2, and neither blocks the other. It is not P1 because
story 1 is the feature and this is how the feature is known to hold; it is not lower because every
claim the other four stories make is unfalsifiable without it. The project's own gate currently
contains checks that have never once been observed failing, and at least one of them has never run
at all — see [Appendix B](#appendix-b-what-the-gate-does-not-currently-catch).

**Independent Test**: plant, one at a time, each defect the gate exists to catch. The build must go
red every time, and name the case.

**Acceptance Scenarios**:

1. **Given** a document that breaks a rule the format states, **When** the suite runs, **Then** it
   is rejected and the rejection names the place in the document that caused it.
2. **Given** a check the gate performs, **When** the defect that check exists to catch is planted,
   **Then** the build goes red. A check never observed failing is not known to work.
3. **Given** a dependency the suite needs, **When** it is removed, **Then** the build goes red and
   prints no skip — a suite that skips reads exactly like a suite that passes.
4. **Given** a rule checked in two places, **When** it is looked for in the source, **Then** it is
   implemented once and called twice.
5. **Given** the corpus, **When** a reader asks what it proves, **Then** the corpus says in its own
   text what it does **not** establish.

### Edge Cases

- **The document names a measurement the target has no assertion for.** Distinguishable from "the
  target cannot express this comparison", and both are unrenderable for different, named reasons.
- **The document names a comparison the target lacks.** Not every operator exists everywhere; the
  document must not silently get the nearest one.
- **The threshold does not survive the unit conversion.** A target that takes whole milliseconds cannot
  take `0.4995 s`. Rounding a threshold silently moves the bar.
- **Requests are addressed one way and the target addresses them another.** A route the target never
  emits; a name that exists only inside one tool; a grouped path where the document has a flat name.
- **A requirement matches no requests at run time.** The target asserts over nothing. What that means
  is the target's business now — but the format must not make it *look* like a pass at render time.
- **Two criteria in one requirement share an aggregation and neither is named.** Nothing can tell the
  resulting assertions apart in the target's own report.
- **The same document is rendered twice.** The second rendering must be identical, or nothing
  downstream can be diffed or reviewed.
- **A requirement is meaningful only if the run reached its intended load** — the case guards exist
  for, in a world where the target has no way to say "inconclusive".

## Requirements *(mandatory)*

### What a document is

- **FR-001**: A requirement document MUST name no tool — not in a field, a value, a metric name, or an
  example.
- **FR-002**: The format MUST NOT enumerate metric or attribute names. Measuring something new MUST NOT
  require changing the format. *(carried unchanged from feature 002)*
- **FR-003**: A criterion MUST be fully described by: what is measured, over which requests, how it is
  reduced to one number, how that number is compared, to what value, and in what unit. No other kind of
  statement is a criterion.
- **FR-004**: Every value MUST be a scalar or a structure. Strings that must be parsed to be understood
  — expressions, embedded units, operator symbols, composite keys — are forbidden.
- **FR-005**: Every threshold MUST carry its unit. *(carried unchanged from feature 002)*
- **FR-006**: An unknown field MUST be an error. *(carried unchanged from feature 002)*
- **FR-007**: The document, each requirement and each predicate MAY carry a **display name**: free
  human-readable text, in any script, with none of the identifier's constraints. It is **inert** —
  it changes nothing about what is selected, measured, compared or rendered, and two documents
  differing only in their display names MUST render identically. It MUST NOT be confused with the
  identifier: the identifier is what a rendering points at, the display name is what a person reads.
  And it **does not reach the target's own report** — no surveyed target has anywhere to put it
  ([Appendix D](#appendix-d-why-a-precondition-cannot-be-named-in-the-targets-report)); a format that
  let an author believe otherwise would repeat the mistake decision D1 already made once.
- **FR-007a**: A display name MUST NOT restate a value the structured fields already carry — a
  threshold, a unit, an operator, a metric or a selector value. A name saying "99th percentile under
  500 ms" beside `threshold: 500` is a **second source for one number**, and the two diverge the
  first time the threshold moves. A display name says *what is measured, over what*; never *what the
  answer is*.
- **FR-008**: Selecting requests MUST cover: every request; one request identified by route or by
  name; and a request identified inside a group, because targets nest requests in groups. Hierarchical
  identification MUST be more attributes on the same selection, never a second kind of address.
- **FR-009**: A requirement MAY declare preconditions stating that the run happened in the intended
  regime. A precondition MUST render into the same kind of native assertion a criterion does — no
  target has an outcome between pass and fail, and inventing one the target cannot honour would be a
  construct nothing can check. It MUST be **identifiable in the rendering** by the native assertion
  identity the target derives its own report line from, and MUST be flagged there as a precondition,
  so that a reader holding the target's report and the rendering can tell *"the run did not happen as
  intended"* from *"the system did not hold"*. **No target may be required to carry an author-chosen
  name**: neither surveyed target has a field for one — see
  [Appendix D](#appendix-d-why-a-precondition-cannot-be-named-in-the-targets-report).

### What rendering must do

- **FR-010**: Rendering MUST account for every criterion in the document. Each is either rendered or
  reported unrenderable **by name**, and the two lists together MUST cover the document exactly.
- **FR-011**: Rendering MUST NOT approximate. Where a target cannot express a criterion exactly, the
  criterion is unrenderable — never replaced by the nearest thing the target has.
- **FR-012**: Rendering MUST report unrenderable criteria **before the run starts**, not as a result.
- **FR-013**: A criterion whose threshold cannot be represented exactly in the target's own
  representation MUST be treated as unrenderable, not rounded.
- **FR-014**: Unit conversion MUST be declared in the target's description rather than assumed by
  whoever implements rendering.
- **FR-015**: Rendering MUST be deterministic: the same document and the same target description
  produce the same assertions, in the same order.
- **FR-016**: What a target can and cannot assert MUST be expressed as data. Adding a target MUST NOT
  require changing the format, the schema, or any existing document.
- **FR-017**: A target's description MUST declare its gaps. An undeclared gap is a defect of the
  description, not of the format.

### What the format must not contain

- **FR-018**: The format MUST NOT define a result document, a verdict vocabulary, an outcome, a gate
  policy, or a severity. Those belong to whatever evaluates, and nothing in scope evaluates.
- **FR-019**: The format MUST NOT define a load profile. `workload` stays reserved and unused.
- **FR-020**: A construct MUST NOT enter the format unless **at least one surveyed target can assert
  it exactly**. This replaces the inherited rule — *"no construct may appear that is expressible only
  at assertion time"* — which was written when post-run evaluation was the complete path and which now
  protects a path this feature removes. A construct is never admitted on the promise that something
  will be able to check it later. It is a floor and not a licence: one target being able to assert a
  construct is necessary for admission and is not by itself sufficient, so a construct MUST NOT enter
  the format solely to reach one target's feature.
- **FR-021**: The format MUST NOT grow a second way to say something it can already say. No aliases, no
  shorthands, no per-tool spellings.

### What must be replaceable

- **FR-022**: Every statement the existing NFR-YAML could express MUST be expressible: the 50th,
  75th, 95th and 99th percentiles of response time, the maximum response time, and the percentage of
  failed requests — each addressed either at one named request or across all requests. This is a
  coverage bar for the format, not an obligation to any other project.
- **FR-023**: Each of those six statements MUST be published **in this repository** as a worked
  example: the document that expresses it, and the assertion it renders into. A claim of coverage
  that nobody can read is not coverage.
- **FR-024**: The format MUST NOT inherit that format's closed list of supported requirement kinds. A
  statistic the format did not anticipate MUST be writable without changing the format.

### What must stay honest

- **FR-025**: Nothing may report success by omission — at render time as well as at run time. A
  criterion that produced no assertion MUST be visible.
- **FR-026**: Any claim about what a target can assert MUST be checked against that target's own
  documentation or source, and MUST carry the date it was checked.
- **FR-027**: A term MUST reach the glossary with a rejected alternative before it appears in the
  format or an example.

### What must be tested

The repository ships a schema and no code, so "unit test" here means the smallest thing that can be
checked mechanically about the format: one document, one rule, one expected outcome.

- **FR-028**: Every rule this specification states about a document MUST be checked by machine
  rather than by reading. A rule nobody can run is an intention.
- **FR-029**: The corpus MUST contain documents required to be **rejected**, and each rejection MUST
  name the place in the document that caused it. Checking only that valid documents pass leaves
  untested the strictness that is the format's main claim.
- **FR-030**: A rejection case MUST differ from a valid document by **exactly one** change, so that
  exactly one rule can be responsible for the outcome.
- **FR-031**: The expected outcome MUST live beside the case, never inside it. A case file is the
  document exactly as written — an expectation embedded in it would itself be an unknown field, and
  would mask the very finding the case exists to produce.
- **FR-032**: A rendering MUST be testable as data: a triple of *(document, target description,
  expected rendering)* that any implementation, in any language, in any repository, must reproduce.
  The corpus is the oracle. Nothing in this repository renders, and the corpus MUST NOT pretend
  otherwise.
- **FR-033**: The sum rule of FR-010 MUST be checked mechanically on every rendering case: every
  predicate in the document falls into exactly one of the two **buckets**, by identity, with no third
  bucket and no silent remainder. The rule binds *predicate to bucket*, **not predicate to assertion**:
  one criterion may legitimately become more than one native assertion where a target can only express
  it as a conjunction, and a single native assertion may expand into many results at run time. Neither
  is a violation; requiring one assertion per predicate would forbid both and make the rule unusable.
- **FR-034**: The gate MUST be tested against itself. For every check it performs there MUST be a
  case that plants the defect that check exists to catch and requires the build to go red. A check
  never observed failing is not known to work.
- **FR-035**: No part of the suite may skip. When it cannot run — a missing dependency, an empty
  corpus, a case with no expectation — it MUST fail. A suite that skips reads exactly like a suite
  that passes, which is Principle III applied to the project's own tooling.
- **FR-036**: A rule MUST have exactly one implementation. Where the gate and the corpus check the
  same rule, they MUST call the same code — otherwise the corpus asserts against a copy and proves
  nothing about the gate that actually runs.
- **FR-037**: The corpus MUST state, in its own text, what it does **not** establish.

### What must leave the notebook

- **FR-038**: Every note in `docs/` describing something this feature settles — accepts, rejects or
  parks — MUST be deleted in the same change that settles it. This is FORMAT.md's existing rule; it
  is restated here because this feature settles more notes at once than any before it.
- **FR-039**: Where one rule is written in more than one place, **all** copies MUST be removed in a
  single change, and any copy that **binds** — the constitution, `ARCHITECTURE.md` — MUST be amended
  **first, in an earlier pull request**. Deleting the notebook copy alone leaves the repository
  formally requiring what this feature forbids, which is a worse defect than the duplication it was
  meant to cure.
- **FR-040**: A decision record MUST NOT be rewritten to agree with this feature. A superseded ADR
  entry receives a **dated supersession note**; the original argument stays readable. An ADR that
  silently agrees with the present has stopped being a record.
- **FR-041**: A note deleted for a construct that is **parked** rather than rejected MUST arrive in
  the parked area carrying its argument, its rejected alternatives and a date. Deleting it outright
  destroys reasoning that is expensive to reconstruct and cheap to move.
- **FR-042**: Three glossary entries are **owed** before the constructs they name appear in the
  schema or an example: the aggregate-versus-each distinction, the target description, and the
  unrenderable criterion. Each with a rejected alternative, per FR-027.

## Key Entities

- **RequirementSet** — the document. One file, one set of requirements, no tool.
- **Requirement** — one human statement about the system. Declares what is measured and which
  predicates must hold over it.
- **Indicator** — the measured quantity: what metric, over which requests, and of what shape (a
  distribution of values, or a fraction of a total).
- **Criterion** — one machine-checkable predicate over an indicator. The unit that becomes exactly one
  native assertion, or exactly one named gap.
- **Target** — the external tool that will host the assertions and decide the run. It never reads the
  document.
- **Target description** — the data that says how this target names things, what it can assert, what it
  cannot, and how units convert. Adding a target is adding one of these.
- **Rendering** — the act of turning criteria into a target's native assertions, producing both the
  assertions and the named list of criteria it could not produce.
- **Unrenderable criterion** — a criterion the target cannot express exactly, carried by name and
  reason rather than dropped.
- **Corpus** — the cases that check the format mechanically: documents that must be accepted,
  documents that must be rejected and where, renderings any implementation must reproduce, and
  defects the gate must catch. It is the oracle, not an implementation.
- **Precondition** — a statement that the run happened in the intended regime at all. Renders like a
  criterion, because no target has an outcome between pass and fail; carries a name into the target's
  report, so a failure caused by the load generator is not read as a failure of the system.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All six statements the existing NFR-YAML supported are expressible — 6 of 6, each with
  the document that expresses it and the assertion it renders into published in this repository.
- **SC-002**: One unchanged requirement document produces assertions for at least two independent
  targets.
- **SC-003**: For every published example, the number of criteria rendered plus the number reported
  unrenderable equals the number of criteria in the document. Exactly, every time.
- **SC-004**: The number of tool names appearing anywhere in the format or in any validated example is
  zero.
- **SC-005**: The number of metric names enumerated in the format is zero.
- **SC-006**: The number of constructs in the format that no surveyed target can assert **exactly** is
  zero.
- **SC-007**: Every claim in the target descriptions about what a tool can assert carries a source and
  a date.
- **SC-008**: A reader given a document and a target description predicts the assertions correctly,
  including the numbers after unit conversion.
- **SC-009**: Rendering the same document twice produces byte-identical output.
- **SC-010**: After this change, the number of notes in `docs/` describing something this feature
  settles is **zero** — every accepted, rejected or parked idea has had its note deleted in the same
  change, per FORMAT.md.
- **SC-011**: The number of new **concepts** this feature adds to the glossary is at most three, each
  with a rejected alternative: the display name, the target description, and the unrenderable
  criterion. A fourth entry, *rendering*, is owed but is not a fourth concept — it names
  the artifact produced by an act this repository already calls *render*, in the glossary's own layer
  diagram, in `ARCHITECTURE.md`'s R2 role and in this specification's Key Entities. Its glossary entry
  MUST say exactly that, so the judgement is recorded rather than assumed.
- **SC-012**: Every line a target's own report can produce for a rendered predicate resolves to
  exactly one entry in the rendering, and each entry says whether it is a criterion or a precondition
  — for 100% of predicates in every published example. Where two predicates would produce
  indistinguishable report lines, the corpus says so rather than claiming a distinction that does not
  exist.
- **SC-013**: Stripping every display name from a document changes no rendering, on any target —
  byte-identical output, every published case. An inert field that is not provably inert is a field
  that will quietly acquire meaning.
- **SC-014**: Every check the gate performs has a case that plants its defect and requires the build
  to go red — 100% of checks, no exceptions.
- **SC-015**: Running the suite with any required dependency removed turns the build red, and prints
  no line reading `skip`.
- **SC-016**: The number of rules implemented twice — once by the gate, once by the corpus — is zero.
- **SC-017**: For every rendering case, rendered plus unrenderable equals the number of predicates in
  the document. Exactly, every case.
- **SC-018**: The number of notes deleted from `docs/` whose binding twin was not amended first is
  **zero**. Orphaning a rule is worse than duplicating it.
- **SC-019**: The corpus states what it does not establish, in its own text.

## Assumptions

- **Post-run evaluation is parked, not deleted.** Verdicts, gate, outcome and a result document remain
  arguable ideas in the notebook. The user's instruction is that they are not needed *now*; this
  feature takes them out of scope rather than out of existence. They return through the same route any
  other idea does.
- **The evaluation-shaped constructs stay out of the container.** `severity`, `gate`, `baseline` and
  `tolerance` were already ideas rather than fields, so nothing has to be removed to satisfy the
  instruction — only prevented from arriving.
- **Rendering is implemented where the target lives, and that is outside this repository.** This
  repository ships the format, the target descriptions, and the corpus that says what a correct
  rendering produces. A library that builds Gatling assertion objects belongs to whoever integrates
  Gatling — the format cannot hand Gatling a text file, because its assertions are constructed in code
  at set-up time. Nothing in this feature is a commitment that such a library gets written, by anyone,
  on any schedule.
- **`http.route` stays the preferred way to address a request, and a request name stays the honest
  fallback.** Almost no load generator emits a route, so most real documents will use names, and
  documents written against names do not travel between tools. That is a stated cost, not a defect.
- **The first two targets are Gatling and k6.** Gatling because it is the concrete case the format is
  being shaped against; k6 because it is the most capable of the surveyed tools and therefore the best
  test of whether the format is tool-agnostic rather than Gatling-shaped with a coat of paint. Both are
  described as data in this repository; neither integration is built here.
- **"Compatible with Gatling" means renderable into Gatling's assertion DSL**, not "resembles it".
  Gatling's own vocabulary (`global`, `forAll`, `details`, `percentile3`) does not enter the format.
- **`inconclusive` leaves the format with the rest of the outcome vocabulary.** A precondition still
  exists and is still checked; what it cannot do is produce a third outcome, because no target has one
  and FR-020 forbids admitting a construct nothing can check. The distinction it protects moves from an
  outcome into a name in the target's report — which is where a human reads it anyway.

## Decisions taken during specification

Three questions were open when this specification was drafted, because each one changes what the
format contains and none of them could be answered from the rest of the document. Each is recorded
here with the alternative that was rejected, because a rejection outlives the term it protects.

### D1. A precondition renders like a criterion, and carries a name

> **Revised 2026-08-20, against Gatling's source.** As first written, this decision required a
> precondition to carry a name into the target's own report, on the reasoning that "preserving it as
> a name costs the format nothing". **That reasoning was wrong**: it costs a capability neither
> surveyed target has. Gatling derives every printed assertion string from `(path, target,
> condition)` and has no label field; the one author-controlled fragment must match a group or
> request name recorded during the run, and is absent entirely at global scope — which is exactly
> where a throughput precondition lands. The decision below is the repaired one; the evidence is in
> [Appendix D](#appendix-d-why-a-precondition-cannot-be-named-in-the-targets-report).

**Decided**: preconditions stay in the format and render into the same kind of native assertion a
criterion does. The distinction is carried by the **rendering**, which records for each entry the
native assertion identity the target derives its report line from, and flags which entries are
preconditions. → FR-009, SC-012.

**Why**: the distinction a precondition protects — *"the run did not happen as intended"* versus
*"the system did not hold"* — has to survive into something a human reads. It cannot survive into the
target's report, because no target has anywhere to put it. It can survive into the rendering, which
already has to enumerate every predicate by identity, and from which a report line can be resolved
back to its entry. This costs no new concept and requires no capability any target lacks.

**Rejected — a third outcome (`inconclusive`)**: it is a construct no surveyed target can produce, so
FR-020 forbids it. Every rendering would have to lie about it or drop it.
**Rejected — dropping preconditions**: a run at 5 rps shows a green p95 and a false pass. That failure
mode is the reason this project exists; a format that cannot state the precondition cannot catch it.
**Rejected — keeping them as always-unrenderable**: a construct whose only behaviour is to be
reported unsupported.
**Rejected — smuggling a label into the target's request path**: Gatling's `details(...)` parts must
equal a group or request name recorded during the run, so a label would force the adapter to rename
the user's own requests, corrupting the recorded vocabulary — and it is unavailable at global scope
regardless. This is the alternative the first version of this decision assumed would work.

### D2. *(withdrawn)* A criterion says whether it holds over the aggregate or over each request

> **Withdrawn 2026-08-20, on review.** The distinction is not admitted. The argument for it is kept
> below because it was good and will be made again; what it lacked was a second target.

**Was decided**: the format gains one distinction — *the aggregate of the selected requests* versus
*each selected request individually, all of which must hold*.

**Withdrawn because FR-020's second half forbids it, in as many words.** That rule says one target
being able to assert a construct is necessary for admission and *"is not by itself sufficient, so a
construct MUST NOT enter the format solely to reach one target's feature."* The distinction was
admitted on the strength of exactly one target's native scope, which is the case the rule names. It
was written in this specification and then broken by it.

Three further facts, each found after the decision was taken, and each pointing the same way:

- the native scope is hard-wired to **every request observed in the run**, so the distinction renders
  only when the selection is *"every request"* — one combination, on one of two targets;
- the second target has no equivalent at all, and its nearest construct quantifies over samples
  rather than requests, which is a third statement again;
- that single renderable combination is also the one that **exits successfully when it matches
  nothing**. The only place the construct worked was the place it could lie.

**And the ambiguity it was introduced to remove does not exist without it.** A selector matching many
requests is unambiguous while there is only one reading. A spelling is needed to separate two
meanings; with one meaning, the field is a required breaking change that buys nothing.

**What the format loses**: "no endpoint slower than 2 s" as a single statement. It is written as one
requirement per endpoint, which is verbose and silently stops covering an endpoint added later. That
cost is real and is the reason the argument returns — with a second target that can assert it, or
not at all.

**Where it goes**: to the notebook, as an idea, with this argument attached. FORMAT.md's rule about a
knob nobody asked for is the one that applies: it stays an idea until someone asks.

### D3. A construct is admitted only if at least one target can assert it exactly

**Decided**: FR-020. A construct enters the format only if at least one surveyed target can assert it
exactly — a floor, not a licence. → FR-020, SC-006.

**Why**: it is the same rule the project already applies to itself, pointed at the path that now
exists. The inherited rule protected `report` as a complete path; this feature removes that path, so
the rule protects nothing and its inverse is what is needed. Its bite is deliberate: `baseline` /
`tolerance` and phase windows stay out until some target can assert them, which may be never. That is
the honest answer, not a regression — they were already unbuildable, and this only stops the format
promising them.

**Rejected — "expressible regardless, gaps declared"**: it leaves room for post-run evaluation to
return, at the price of a format most of which nothing checks. That is the state the surveyed formats
are in, and the reason this project exists.
**Rejected — "most targets must assert it"**: maximal portability, but it rejects constructs that are
genuinely useful on the one tool a team actually runs, and it makes the format's contents a function
of which tools happen to be in the survey.

### Open — a problem this specification has not solved

**A `ratio` names a metric it does not measure.** Found by a reader on 2026-08-20, while reading a
worked example rather than by any check.

An error-rate requirement reads `metric: http.client.request.duration`, because a histogram's count
is the request count and OpenTelemetry defines no HTTP client request counter — verified against
`model/http/metrics.yaml` on 2026-08-20, where the only `{request}`-unit instrument is
`http.client.active_requests`, an in-flight gauge and not a total. The document is therefore
*correct*, and reads as though it were about latency. That is a direct hit on User Story 4: a
requirement is supposed to state what is measured and nothing else, and this one states a metric that
is not what is measured.

The root cause is not the metric name. It is that `ratio` reuses the `series` shape of
`distribution` without recording that the metric is **counted** there rather than **measured** — one
shape, two meanings, the difference written down nowhere.

| Option | Cost |
|---|---|
| Leave it | The document misleads a competent reader; this one was found exactly that way |
| Let `ratio` omit `metric` and mean "requests" | An implicit default, in a format that rejects unknown fields and demands units |
| Coin `loadtest.requests` | Forbidden by Principle II — an alias for an existing histogram's count |
| Rename the field inside `ratio`, e.g. `counting:` | Reads honestly; costs a term, and SC-011's budget is spent |

The fourth is the strongest and none is free. Principle I requires the naming disagreement to be
argued in an issue **before** any file changes, so this specification records the problem and does
not settle it.

**No convention exists for what a requirement's identifier should say.** Raised 2026-08-20 while
reviewing a worked example, where the identifier `home-latency` turned out to carry two errors at
once: *home* was an interpretation of a request whose recorded name is `GET /`, and *latency* names
a narrower quantity than the metric it stood for — in one surveyed tool's own output, latency is
time-to-first-byte while the metric is the whole duration. Both were invented by the author and
neither is checkable.

Two drift hazards pull in opposite directions and a convention has to price both:

| Putting this in an identifier | Drifts when |
|---|---|
| a **value** — a threshold, a unit | the value changes and the name does not |
| an **interpretation** — "home", "checkout", "critical" | the interpretation turns out to be wrong, and nothing ever re-checks it |
| the **selector's own value** — the request's recorded name | the request is renamed in the test |

The last is the least bad, because renaming the request arguably *does* make it a different
requirement — but that is an argument, not a finding. FR-007a settles the display-name half (a name
never restates a value). The identifier half is open, and Principle I puts it in an issue rather than
in this document.

## What leaves the notebook, and in what order

FORMAT.md says a note is deleted in the same change that accepts, parks or rejects it, and that the
step is not optional. This feature settles more notes at once than any before it, so the sweep was
audited file by file and every proposed deletion was then argued against. **Most proposed deletions
did not survive that argument**, and always for the same reason: the same rule is written in as many
as four places, one of which binds.

That produces the ordering rule now stated as FR-039, and the tiers below.

### Tier 0 — deletable inside this feature

Notes with no binding twin, or notes that duplicate something in their own file.

| Where | What goes |
|---|---|
| `docs/units.md` | rule 1, which restates verbatim a rule stated eleven lines earlier **in the same file**; rule 3 (canonicalise, then compare), which describes evaluation; the "units inside the value" rejection row |
| `docs/semconv/loadtest.md` | the `EvaluationReport.spec.run.attributes` field path in the run-identity heading. The heading, the table and the correlation finding stay — Principle II rests on them |
| `docs/compatibility.md` | `report` as a conformance level; the sentence naming target-blind evaluation as the source of the format's portability claim |
| `docs/GLOSSARY.md` | `severity`; the `gate` clause in the `RequirementSet` entry; the `→ fail` clause in `Criterion` |

### Tier 1 — blocked on a constitution amendment

Everything resting on Principle III's requirement that a run which did not meet its conditions
**must** be reported as `inconclusive`. Decision D1 removes that outcome, so the principle and these
notes have to move together.

`gate`, `Verdict`, `Outcome`, the `inconclusive` half of `Guard`, `docs/examples/checkout-perf.report.yaml`.

### Tier 2 — blocked on `ARCHITECTURE.md` and the constitution's Compatibility Constraints

`Target`, `Adapter`, `MetricMapping`, the conformance ladder, and the old admission rule that FR-020
replaces. The old rule exists in four copies — the constitution, `ARCHITECTURE.md` § 1, this
notebook, and ADR-0002 — and the constitution's Governance section says the constitution wins.
**Deleting the notebook copy first would leave the repository formally forbidding what FR-020
requires.**

### Tier 3 — dated notes on decision records, never rewrites

ADR-0002 § D11, § D12, § D13 and ADR-0001 § D6, § D9, § D10 each receive a dated supersession note.
Per FR-040 the original argument stays readable.

### What the audit found that is not a deletion

- **Three glossary entries are owed**, not removable: the aggregate-versus-each distinction, the
  target description, and the unrenderable criterion (FR-042).
- **`docs/references.md` is untouched** by this feature. Saying so plainly is cheaper than leaving a
  reader to wonder.
- **Appendix A's hierarchical-addressing claim survived a deliberate attempt to break it** — a
  selector carrying a group attribute and a request-name attribute does reconstruct a target's
  request path. But `loadtest.group.name` lives in an unsubmitted upstream proposal that
  Principle VIII grandfathers *with an explicit warning that it may not be cited as precedent for
  admitting new unsettled names*. That is a declared cost of D2's addressing, not a settled question.

## Dependencies and Constraints

These are named because two of them require a change to land **before** this feature does.

| Dependency | Why it matters |
|---|---|
| `ARCHITECTURE.md` § 2, § 4, § 7 | It binds four component roles and a follow-up plan built on post-run evaluation. Taking R3 and R4 out of scope diverges from a binding document, which Principle VII says must be amended in an **earlier** pull request. |
| Constitution Principle VI, *Evaluation Is Target-Blind* | It forbids consuming a statistic a target computed for itself as a verdict. An assertion-first format does exactly that — the whole point is that Gatling computes its own p95 and decides. The principle is not *violated*, because nothing in scope produces a verdict; but the ambiguity must be settled in the constitution before this ships, not discovered afterwards. |
| Constitution Principle III, *No Silent Green* | **Requires an amendment, and this specification previously said it did not.** Its spirit survives intact and does most of the work here — it is why FR-010 through FR-013, FR-025 and FR-034 through FR-036 exist. But its letter mandates that a run which did not meet its conditions "MUST be reported as inconclusive", and decision D1 removes that outcome because no target has it. The principle must be amended in an earlier pull request to say what carries its run-time half under an assertion-first format, before Tier 1 above can be deleted. |
| `docs/compatibility.md` design rule | "No construct may appear in OpenNFR that is expressible only at level `assert`." It protected `report` as a complete path; this feature removes that path, so the rule is void and **FR-020 replaces it** — inverting it, from *"nothing that only asserts"* to *"nothing that nothing can assert"*. The note must be edited in the same change that adopts FR-020, per FORMAT.md's rule that an accepted note is deleted rather than left as a second source. |
| ADR-0002 conformance levels | `report`, `assert` and `abort` are cumulative levels over a path that ended in evaluation. With evaluation out of scope, `report` is no longer a conformance level at all — a tool that cannot assert is a tool this format cannot serve. The level table needs re-deriving, not editing. |
| ADR-0001 | The naming arguments hold. Where this feature adds a term, ADR-0001's rule applies to it unchanged: it reaches the glossary with a rejected alternative first. |

## Appendix A: what Gatling can actually assert

Checked against `gatling/gatling` source on **2026-08-19**:
`gatling-core/src/main/scala/io/gatling/core/assertion/AssertionSupport.scala` and
`AssertionBuilders.scala`. This is evidence for the design, not part of the format.

| Dimension | What exists |
|---|---|
| Scope | the whole run; **every request observed in the run**, individually; one request identified by a path of parts |
| Response time | minimum, maximum, mean, standard deviation, any percentile |
| Request counts | all / failed / successful, each as a count or as a percentage |
| Throughput | mean requests per second |
| Comparisons | less than, at most, greater than, at least, exactly, within a range, one of a set |
| Aborting a run | not available |

**Where the container from feature 002 already fits.** A fraction with a `bad` side is the
failed-request percentage; with a `good` side, the successful one; its total is all requests. Reducing
a distribution by `rate` is mean requests per second. `avg` is mean; `stddev` is standard deviation;
`p95` is the 95th percentile. Response-time thresholds are whole milliseconds, which is exactly the
conversion hazard FR-013 exists for.

**Where it does not fit — the three things this feature must settle.**

1. **Per-request-individually scope.** "Every request, each on its own, must hold" is a native scope in
   Gatling and has no counterpart in selecting series. **Not adopted** — see D2, withdrawn. The scope
   ranges over every request *observed in the run* rather than over a selection, one of two targets
   has it at all, and an assertion in it that matches nothing exits successfully. A capability of the
   target that the format does not reach for.
2. **Hierarchical addressing.** A request is identified by a *path* of parts — group then request —
   whereas the format addresses requests by flat attributes. The old NFR-YAML's `MyGroup / MyRequest`
   key is the same shape, which is why people writing these requirements today will expect it. **Settled without a new term**: a selection
   carrying both a group attribute and a request-name attribute reconstructs the path, and both
   attributes already exist in `docs/semconv/loadtest.md`. → FR-008.
3. **Comparisons with no counterpart in each direction.** The format has "not equal", which Gatling
   lacks; Gatling has "within a range" and "one of a set", which the format lacks. Neither side may be
   approximated into the other. **Settled by D3**: "not equal" now has to justify itself against
   FR-020, and "within a range" is admissible on the strength of Gatling alone but is not admitted
   automatically — FR-020 is a floor, not a licence. → FR-011, FR-020.

Nothing in this appendix argues for adopting Gatling's vocabulary. It argues that the fit is close
enough that three decisions, not a redesign, separate today's container from an assertion-first format.

## Appendix B: four checks that could not fail, and what they cost to find

Found while specifying the test corpus, each read in `scripts/verify.sh` and confirmed by hand on
**2026-08-19**. Evidence for FR-034 and FR-035. **All four were fixed on `main` the same day**, by
`fix(verify): make the English scan run, and fail loudly when a check cannot (#12)`; this appendix is
the record of what they were and how they were found, not a list of open defects.

| Site | Why it could not fail | Fixed by #12 |
|---|---|---|
| *Docs are English* | `grep -P` is a GNU extension; BSD grep exits 2, `2>/dev/null` ate the message and `\|\| true` ate the status. **The Cyrillic scan had never executed on macOS** | replaced with a `python3` scan of the same code-point range |
| *YAML sketches parse* | printed `skip` on a missing interpreter or library and exited 0 | both branches now `FAIL` and exit non-zero |
| *Sketches map one-to-one onto JSON* | iterated a glob with no empty-corpus guard: delete every sketch and the section printed nothing and passed | an explicit empty-corpus `FAIL` |
| *Internal markdown links resolve* | the extraction pipeline's exit status was never examined; a broken pipeline yields zero links, zero failures, and `ok` | counts what it found, and fails when that is zero |

### Why this is the argument for FR-034 rather than a closed matter

**Not one of the four was caught by a test.** All four were found by reading the script while writing
a specification about something else. The gate had been green on every commit, on both platforms, for
the life of the project — and one of its sections had never once executed.

A fix removes four defects; it does not make the fifth visible. What FR-034 requires is different in
kind: for **every** check the gate performs, a case that plants the defect that check exists to catch
and requires the build to go red. A check that has never been observed failing is not known to work,
and that remains true of a freshly repaired one.

The repository already knew the answer before the fix, which is the sharpest part: the schema section
had always exited 1 on a missing library, with the comment *"a gate that skips itself reads exactly
like a passing one"*, and had always guarded its empty corpus. Four sections had simply not copied
it. Consistency is not something a reviewer reliably notices; a mutation case is.

### One that is still open, of the opposite kind

The link checker greps for `](` across every markdown file, so a regular expression written in prose
— a character class followed by a group — reads as a link and is reported as dangling. It cost this
feature a red build twice, on a documentation table. A false **positive**, so a nuisance rather than
a danger, and untouched by #12 because the extraction is unchanged. Recorded because the next person
to write a pattern into a document will hit it.

## Appendix C: what the corpus will not establish

Required by FR-037, and stated here so that planning does not treat the corpus as proof of more than
it is.

- **Nothing in this repository renders.** The rendering corpus is an oracle — a well-formed guess
  until an integration somewhere else runs against it. Its checks are consistency checks between
  files this repository writes.
- **It can be uniformly wrong about a target.** If a target description wrongly claims a tool lacks
  a comparison, and the case agrees, both are wrong and the build is green. Nothing here reads the
  tool. FR-026's dated source is prose a human must check; a machine can verify that a date exists,
  never that it is true.
- **It does not check that the tool accepts the assertion.** The corpus pins the arguments, never
  the API. A statistic name the tool does not have passes every check here.
- **The sum rule closes over the document, not over intent.** It catches a criterion the renderer
  dropped. It cannot catch the requirement nobody thought to write — which is the most common real
  defect in requirement documents.
- **Two targets do not prove the shape is neutral.** Any record designed while looking at Gatling
  and k6 will fit Gatling and k6. The honest next probe is a third target with native assertions of
  a different shape.

## Appendix D: why a precondition cannot be named in the target's report

Checked against `gatling/gatling` source on **2026-08-20**, tag `v3.15.1` where the file is still
open-source and `v3.9.5` for the type that has since moved into a closed artifact. Evidence for the
revision of decision D1 and for FR-009, and a caution about how the first version of that decision
was reached.

**An assertion is three fields and none of them is a name.** The single construction site is
`Assertion(path, target, condition)` in `gatling-core/.../assertion/AssertionBuilders.scala`. The
last open-source definition of the type — `gatling-commons-shared/.../assertion/AssertionModel.scala`
at v3.9.5 — is a three-field case class. No step of the DSL, in any of its four language bindings,
accepts a label, name or description.

**Every printed string is derived from those three fields.** `gatling-app/.../RunResultProcessor.scala`
builds its console line from `AssertionMessage.message(assertionResult.assertion)` — a function of
the assertion alone. The JUnit XML template uses the same derived string as the `testcase` name; the
HTML report renders it as a table row. There is nowhere for per-assertion metadata to enter.

**The one author-controlled fragment is an address, not a label.** Only `AssertionPath.Details(parts)`
carries author strings, and the validator resolves them against paths actually recorded during the
run. A parts list matching nothing does not become a label — the assertion fails with a resolution
error. Using it to smuggle a name would mean renaming the user's own requests and groups.

**And it is absent exactly where it is needed.** A precondition about the run as a whole — "the
generator actually reached 200 rps" — is global in scope. Its path prints as the literal `Global`.
Author-controlled characters available: **zero**. A throughput precondition and a throughput
criterion produce report lines of identical shape, which is precisely the confusion the precondition
exists to prevent.

**One finding in the project's favour.** An unresolvable request path **fails** rather than skipping.
Gatling already honours Principle III at that point, without being asked to.

### The caution worth keeping

The first version of decision D1 chose "carry a name into the report" over three alternatives and
recorded that it "costs the format nothing". It cost a capability that does not exist, and the error
was not visible from the requirement — it was visible only in the tool's source. This is why FR-026
requires every claim about a target to be checked and dated, and why the corpus exists: a decision
that reads well and is unsourced is exactly the failure this repository was started to prevent,
committed by this repository.
