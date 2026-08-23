# Feature Specification: Repository Architecture and Operating Principles

**Feature Branch**: `001-nfr-format-architecture`

**Created**: 2026-08-17

**Status**: Draft

**Input**: User description (translated from Russian; the repository is English-only per
`reference/adr/0001-terminology.md`):

> Source: the `galax-io/ideas` note *An open format for performance requirements*
> (`ideas/observability/open-nfr-format.md`) — what can we take from it? We need a minimal
> requirements format that depends on nothing and is tool-agnostic. Let us think about the
> repository architecture. It seems there should be a single format with interpreters — for
> example a Go parser producing objects, a Gatling interpreter that converts requirements
> into assertions, likewise for k6 — plus formats describing how metrics can be converted
> for observability through Datadog or other APM tools, so that NFR metrics can be monitored
> from the application's APM. In other words, we need metrics bound both to load testing
> tools and to monitoring tools.
>
> Do not try to think through the implementation now — rather just the repository layout and
> how it should all work. Invent principles; the constitution may need amending, but not the
> implementation. The implementation itself should be done in separate specs, each for a
> concrete task.

Scope decisions taken during drafting:

> The core keeps the vocabulary that already exists; "minimal" means adding no new construct
> to it. The monitoring direction is attempted in both directions — query and monitor — but
> as an **experiment that must be parked**, aimed at a markup rich enough to assemble a query
> for Datadog, Prometheus, VictoriaMetrics and InfluxDB. One repository holds everything,
> with support for a target expressed as data.

## Context

This repository is a design notebook ([README](../../README.md)). It has a candidate
vocabulary (`reference/glossary.md`), two proposed ADRs, a verified tool survey
(`reference/compatibility.md`), unvalidated example documents, and a
ratified [constitution](../../.specify/memory/constitution.md) with five principles.

What it does not have is a statement of **how the parts fit together**, **where each part
lives**, and **which rules decide the arguments the architecture is about to create**. Those
three gaps are what this feature closes.

### What this feature is, and is not

| | |
|---|---|
| **Is** | The operating model — one format, several adapters, two classes of target — written down end to end; the repository layout that houses it; the principles that govern it, including an amendment to the constitution; and the list of follow-up specs the implementation must travel through |
| **Is not** | A schema, a validator, a parser, a renderer, a tool mapping, or any change to the format's field-level design. Every one of those belongs to a separate, later spec with its own concrete task |

The boundary is deliberate. Deciding the architecture and the implementation in one pass is
how a design notebook becomes a codebase nobody can argue with: the architecture stops being
reviewable the moment it arrives attached to working code.

### What is taken from the source idea

| From the idea note | Taken as | Why |
|---|---|---|
| Every tool has its own assertion syntax, rewritten on every tool change | The motivation for the architecture | Unchanged and still true |
| Priority tools: JMeter, Gatling, k6 | The three load generators the architecture must be able to serve | They span the whole difficulty range: k6 is the best case, JMeter the worst |
| "One description works on three tools without edits" | SC-002 | The only criterion that actually tests tool-agnosticism |
| "At least one real project migrated" | SC-009, via the internal consumer below | Turns an aspiration into a named counterparty |
| `gatling-picatinny` removes `assertionFromYaml`, recording "replacement decision needed" | A named consumer, and the reason one follow-up spec outranks the others | A real deadline beats a hypothetical user |
| "Is it YAML, JSON or a DSL?" | Already answered by ADR-0002 § D16; restated, not reopened | The decision exists; reopening it costs more than it buys |
| "Who is the target user?" | The Assumptions section | Needed to judge what the architecture may assume of its reader |
| Sibling idea: the three tools disagree on load profile semantics | A reason to keep load profiles out of the format entirely | A construct whose cross-tool meaning is unknown cannot sit in a tool-agnostic format |
| Sibling idea: generating requirements from human-language text | A constraint on the format, not a deliverable | The format must be a good generation target: closed value sets, no free-form strings |

### Candidate principles

The request asks for principles, so here are the ones the architecture actually needs. Each
carries the argument it settles **and a citation that grounds it** — committed text named by
file and section, or a decision already taken here that the principle generalises. A
principle that can produce neither is decoration, and FR-008 drops it.

| Candidate | What it forbids | The argument it settles | Grounding |
|---|---|---|---|
| **Targets Are Data** | Any target — load generator or monitoring backend — requiring code in the format's own implementation before it can be supported | "Let us just special-case JMeter in the reader; it is only one `if`." | `reference/adr/0002-compatibility.md` — "supporting a new tool means adding a YAML file, not forking the Go code" — plus the constitution's Compatibility Constraints, which say it for load testing tools only. The principle generalises both to monitoring backends |
| **Evaluation Is Target-Blind** | The component that turns measurements into verdicts knowing which target produced them, or how | "k6 already computed p95 — let us trust its number." Then the verdict depends on the tool, and one document stops meaning one thing | `reference/compatibility.md` § Requirements for the Go implementation → Layering — "The crucial part: the evaluation layer knows nothing about tools or sources. It operates on canonical names — and that is the only reason the format can promise compatibility with an arbitrary tool." Note: that section is in the document's *proposal* half and says nothing is implemented yet |
| **Experiments Are Parked, Not Merged** | Unsettled work entering the compatibility surface because it is nearly right | "The Datadog mapping mostly works; call it v1." Four query languages and four percentile implementations are not nearly-right material | **Contested — see [research.md](research.md) § D2.** The nearest committed text is constitution Principle III's "Any artifact nothing validates MUST say so in its own text", which grounds *labelling* — the opposite of what the draft says. Two published artifacts already practise labelling over containment. Ships only in a narrowed form, or is dropped |
| **Architecture Before Implementation** | Code arriving without a spec naming the architectural role it fills; a spec changing the architecture implicitly | "Let us write the parser and see what shape falls out." | [AGENTS.md](../../AGENTS.md) § Commits & PRs — "**Spec-first.** `specs/NNN-*/` artifacts → `docs(speckit): add NNN-&lt;feature&gt; spec/plan/tasks` commit BEFORE any `feat`/`fix`. Never folded into implementation." Co-cited with constitution Principle I's ordering rule, because AGENTS.md declares everything below its `---` to be boilerplate reused across projects rather than an argument this repository had |

The amendment is MINOR under the constitution's own versioning policy: the existing
constraint "support for a load testing tool must be expressible as data" is widened rather
than duplicated, and the surviving candidates are new obligations. How many survive is
decided by FR-008's drop test at writing time, not asserted here.

### Decisions carried forward

- **Core = the existing vocabulary, frozen.** "Minimal" is a zero budget for new constructs,
  not a demolition of the glossary. The honest consequence — some core constructs depend on
  an unratified attribute, on stored run history, or on a tool capability — is a fact the
  architecture must expose, not hide.
- **The monitoring direction is experimental and parked.** Both directions are attempted:
  assembling a query, and emitting a native monitor. The target vocabulary must serve
  Datadog, Prometheus, VictoriaMetrics and InfluxDB.
- **One repository.** Core, tool mappings, corpus, experimental area, decision records and the
  eventual reference implementation live here. Tool-native integrations live in the tool's
  own repository and consume this one.

## Clarifications

### Session 2026-08-18

- Q: How much of the four-backend monitoring work is discharged inside this feature, and what does SC-002's "walking each path on paper" produce? → A: Publish three load-generator walkthroughs in full over one named example document; state the monitoring half as an explicitly unverified, dated claim owned by the parked follow-up spec, and narrow SC-002's verified half to three targets.
- Q: Are "monitoring backend" and "data source" one concept or two, and which word does the architecture use for Prometheus? → A: Two concepts, two words — `data source` is inbound (supplies normalised series to evaluation, a parameter per ADR-0002 § D18), `monitoring backend` is outbound (receives an assembled query or a standing monitor). One product may play both roles, and each glossary entry names the other.
- Q: Which of this feature's new words are "terms" under FR-012, and does docs/GLOSSARY.md host them? → A: Split by collision — only words colliding with one already in the glossary (`target`, and `binding` if kept) are settled there, where the collision is visible; the remaining governance words are defined in the layout document, each with its own rejected alternative. The glossary keeps its three-layer structure.
- Q: What counts as "at least one argument already recorded in this repository" for FR-008's drop test? → A: A citation to committed text named by file and section, OR to a decision already taken here with the decision the principle generalises named. An invented utterance is not a citation. Three candidates cite committed text; "Experiments Are Parked" currently cites nothing and is dropped unless it finds a citation.
- Q: What status does the architecture document carry, and what makes FR-023's "amend the architecture first" enforceable? → A: A split status inside one document — component roles, their forbidden dependencies and the follow-up boundaries bind later specs; every description of a component that does not yet exist is marked proposed. The document states its own amendment procedure: an ordinary PR editing it, landing before the diverging spec, with no decision record required.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Someone new understands how the whole thing works (Priority: P1)

A reader who has never seen this project opens one document and can follow a requirement
from the engineer who writes it to the verdict a CI job prints: what reads it, what turns it
into something a load generator understands, what reads the run back, what decides pass or
fail, and where a monitoring backend enters the picture. At every step they can see what that
step is handed, what it returns, and what it is forbidden to know.

**Why this priority**: "how it should all work" is the request, and nothing else in this
feature can be reviewed without it. It delivers value with no code and no format change: an
architecture document is immediately usable as the thing every later spec is checked against.

**Independent Test**: hand the architecture document to someone who has read nothing else and
ask them to trace one example requirement end to end, naming each component. Any step they
cannot name, or any point where they must guess what a component knows, is a defect. The
document must carry that trace worked through for each of k6, Gatling and JMeter over
`docs/examples/checkout-perf.yaml`; a missing or
unfollowable walkthrough is the same defect.

**Acceptance Scenarios**:

1. **Given** the architecture document, **When** a reader traces a requirement from authoring
   to outcome, **Then** every component on the path — including `gate` — is named and no step requires information
   the previous step did not provide.
2. **Given** any named component, **When** a reader asks what it must not depend on, **Then**
   the answer is written down.
3. **Given** the component that decides pass or fail, **When** a reader asks whether it knows
   which tool produced the measurements, **Then** the answer is no, and the reason is recorded.
4. **Given** the two classes of target — load generators and monitoring backends — **When** a
   reader asks how each is supported, **Then** the answer is "by adding data", identically for
   both.
5. **Given** the monitoring direction, **When** a reader opens any part of it, **Then** its own
   text says it is experimental, what would promote it, and what would retire it.
6. **Given** a criterion a target cannot honour, **When** the architecture describes what
   happens, **Then** the answer is a named failure, never a silent substitution.

---

### User Story 2 - The project has principles that end arguments (Priority: P2)

A maintainer facing a recurring design argument — should this tool get a special case, may we
trust a tool's own percentile, is this experiment ready — finds the argument already decided
in writing, with the reasoning and the rejected alternative attached. Where a new principle
extends or contradicts the ratified constitution, the constitution is amended through its own
procedure rather than quietly outvoted by a newer document.

**Why this priority**: the architecture creates exactly the kind of recurring decision that
erodes under deadline pressure, and the constitution as ratified predates it. Principles are
independently valuable — they govern work that has not been specified yet.

**Independent Test**: for each principle, produce its citation — committed text named by file
and section, or a decision already taken here that the principle generalises. A principle that
can produce neither is removed.

**Acceptance Scenarios**:

1. **Given** a proposed principle, **When** it is reviewed, **Then** it names what it forbids,
   the failure it prevents, and at least one real argument it settles.
2. **Given** a principle that extends the constitution, **When** it is adopted, **Then** the
   constitution is amended and its version is bumped under its own policy.
3. **Given** the constitution's amendment procedure, **When** the amendment is proposed,
   **Then** it travels as a change to the constitution and affected templates and nothing
   else.
4. **Given** any later change that contradicts a principle, **When** it is reviewed, **Then**
   it is either rejected or accompanied by an amendment — never silently accepted.

---

### User Story 3 - A contributor can find and change exactly one thing (Priority: P3)

A contributor wants to add support for their load generator, or fix a term, or record a
decision. They open the layout document, find the one place that artifact class lives, learn
who may change it and what changing it obliges, and make a change that touches nothing else.
Adding a target never requires touching the format's normative text.

**Why this priority**: the layout is what makes "support is data, not code" true in practice
rather than in principle. It ranks below the architecture because it is the architecture's
filing system.

**Independent Test**: hand the layout document to someone who has not read the rest and ask
them to list every file they would create to add a new load generator, and every file they
would need permission to touch. Compare against what the architecture actually requires.

**Acceptance Scenarios**:

1. **Given** the layout document, **When** a contributor adds a target, **Then** the normative
   core is untouched.
2. **Given** any artifact in the repository, **When** a contributor asks where its class
   belongs, **Then** exactly one location answers.
3. **Given** a change to a compatibility-sensitive surface, **When** it is proposed, **Then**
   the layout document already told the contributor an ADR is required.
4. **Given** the experimental area, **When** a contributor changes it, **Then** no ADR and no
   core version bump is required, because that area is outside the compatibility surface by
   construction.
5. **Given** the experimental area, **When** it is deleted in one operation, **Then** nothing
   outside it changes.

---

### User Story 4 - The work ahead is cut into separate, non-overlapping specs (Priority: P4)

A maintainer planning the next quarter reads a list of the specs the implementation must
travel through — the schema, the object model, each renderer, the file adapter for file-based
tools, the conformance corpus, the parked monitoring experiment — each with a stated
boundary and a stated dependency on the others. No two overlap, none re-derives the
architecture, and each can be picked up on its own.

**Why this priority**: it is the request's explicit instruction, and it is the mechanism that
keeps this feature from silently becoming an implementation project. It comes last because
the boundaries follow from the architecture.

**Independent Test**: check every named follow-up spec for a boundary, a dependency, and an
architectural role it fills. Check that no individual deliverable appears in two of them.

**Acceptance Scenarios**:

1. **Given** the follow-up list, **When** a maintainer picks any entry, **Then** it states
   what it delivers, what it depends on, and which architectural role it implements.
2. **Given** two follow-up entries, **When** they are compared, **Then** no artifact is
   claimed by both.
3. **Given** a follow-up spec that would change the architecture, **When** it is written,
   **Then** it amends the architecture first rather than diverging from it.
4. **Given** this feature's own output, **When** it is inspected, **Then** it contains no
   schema, no validator and no executable artifact.

---

### Edge Cases

- **A later spec needs something the architecture forbids.** There must be a stated route —
  amend the architecture — and it must be cheaper than the workaround, or people will take
  the workaround.
- **A principle contradicts the ratified constitution.** The constitution wins until amended;
  a newer document silently overriding it is the failure mode the constitution exists to
  prevent.
- **The architecture document goes stale.** It describes components that do not exist yet, so
  drift is guaranteed unless its status is honest about what is described versus what is
  built.
- **A target class needs a role the architecture does not have.** A monitoring backend can
  host a standing monitor that must be reconciled over time; no load generator does anything
  like that. The architecture must either name that role or state that it is out of scope.
- **The experiment is abandoned.** Withdrawing it must cost nothing outside its own area —
  otherwise "parked" was never true.
- **A tool-native integration in another repository drifts from the format.** The architecture
  must say which side is authoritative and how the drift becomes visible.
- **Two artifact classes want the same home**, or an artifact belongs to none. Both make the
  layout unusable for the newcomer it exists to serve.
- **A follow-up spec is completed out of order**, before the one it depends on. The
  dependencies must be stated, not implied by numbering.
- **A core construct's own dependency is unavailable** — no recorded run phase, no stored
  previous run. The architecture must forbid degrading into "evaluate everything instead" or
  "pass by default".

## Requirements *(mandatory)*

### Functional Requirements

#### The operating model

- **FR-001**: The repository MUST publish an architecture document that traces a requirement
  from authoring to outcome — `requirement → criterion → verdict → gate → outcome` — naming
  every component on the path. The trace MUST be worked
  through concretely over one named example document, once per load generator, rather than
  described in the abstract.
- **FR-002**: For each named component the document MUST state its input, its output, and at
  least one thing it is forbidden to depend on.
- **FR-003**: The component that produces verdicts MUST be defined as independent of which
  target produced the measurements and of how they were obtained.
- **FR-004**: The architecture MUST define two classes of target — load generators and
  monitoring backends — and MUST state, for each, that support is added as data. Any claim
  about a monitoring backend that this feature does not work through MUST be published as
  explicitly unverified, carry the date it was made, and name the parked follow-up spec that
  owns verifying it.
- **FR-005**: The data source MUST remain a parameter of evaluation and MUST NOT appear in a
  requirement document, preserving `reference/adr/0002-compatibility.md`.
- **FR-005a**: The architecture MUST keep two distinct concepts with two distinct words for
  the two directions a metrics product can face: the **data source**, inbound, which supplies
  normalised series to evaluation and stays a parameter of it; and the **monitoring backend**,
  outbound, which receives an assembled query or a standing monitor. It MUST state that one
  product — Prometheus is the obvious case — may play both roles in one run, and each
  definition MUST name the other so the two are never read as synonyms.
- **FR-006**: The architecture MUST NOT admit any construct that is checkable only while a run
  is in progress. Anything expressible MUST also be evaluable after the fact.
- **FR-007**: The architecture MUST state what happens when a target cannot honour a
  construct: a named failure, never a substitution, an approximation, or a silent omission.

#### Principles and governance

- **FR-008**: Every principle adopted by this feature MUST state what it forbids, the failure
  it prevents, and a citation that grounds it: either committed text in this repository, named
  by file and section, or a decision already taken here, naming the decision the principle
  generalises. An invented utterance is not a citation. A principle that can produce neither
  MUST be dropped.
- **FR-009**: Principles that extend or contradict the ratified constitution MUST be adopted
  by amending the constitution, with a version bump under its own versioning policy.
- **FR-010**: The constitution amendment MUST travel as its own change, containing the
  constitution and any templates it affects and nothing else, as the constitution's amendment
  procedure requires.
- **FR-011**: Where a new principle widens an existing constitutional constraint, it MUST
  widen that constraint rather than add a parallel one saying nearly the same thing.
- **FR-012**: Every word this feature introduces MUST carry at least one rejected alternative
  before it appears anywhere else, in exactly one of two homes:
  - a word that collides with one already used in `reference/glossary.md` —
    `target` against "target load" in the Requirement entry, and `binding` if that word is
    kept — MUST be settled in the glossary, where the collision is visible;
  - every other governance word — `artifact class`, `component role`,
    `compatibility-sensitive surface`, `experimental area`, `follow-up spec` and the like —
    MUST be defined in the layout document with its own rejected alternative.

  The glossary's three-layer structure MUST NOT gain a fourth layer, and no word may be
  defined in both homes.
- **FR-013**: Every document this feature produces MUST state its own status honestly —
  what is described, what is decided, and what is merely proposed. The architecture document
  MUST carry a **split status**: its component roles, their forbidden dependencies and its
  follow-up boundaries bind later specs, while every description of a component that does not
  yet exist is marked proposed. No statement in it may be left unmarked.

#### Repository layout

- **FR-014**: The repository MUST publish a layout document naming, for each artifact class,
  where it lives, who may change it, and what changing it obliges.
- **FR-015**: Every artifact class MUST have exactly one home. An artifact belonging to no
  class, or to two, MUST be treated as a defect of the layout. One such defect is already
  known and MUST be resolved by the layout document rather than left implicit: the unratified
  `docs/semconv/loadtest.md` is an unsubmitted proposal to an
  external standards body that core constructs already depend on, and none of the artifact
  classes named in Key Entities currently accommodates it.
- **FR-016**: All artifact classes MUST live in this single repository. Tool-native
  integrations MUST live in the tool's own repository and consume this one rather than copy
  it, and the layout document MUST state which side is authoritative.
- **FR-017**: The list of compatibility-sensitive surfaces MUST be published, and every change
  to one MUST require a decision record.
- **FR-018**: The experimental area MUST be excluded from the compatibility-sensitive surface
  by construction, MUST be changeable without a decision record or a core version bump, and
  MUST be removable in one operation without changing anything outside it.
- **FR-019**: Adding support for a target MUST require changing no normative-core artifact and
  no reference-implementation artifact.
- **FR-020**: A published procedure MUST exist for contributing support for a target,
  including what to write, what conformance level it claims, and how that claim is evidenced.

#### Decomposition into follow-up work

- **FR-021**: The architecture MUST name the follow-up specs the implementation travels
  through, each with what it delivers, what it depends on, and the architectural role it
  fills.
- **FR-022**: No two follow-up specs may claim the same deliverable. The unit of claim is an
  individual document or file, not an artifact class: several follow-up specs will
  legitimately add to the normative core, and a class-level test would make the list
  unwritable.
- **FR-023**: A follow-up spec that would change the architecture MUST amend the architecture
  first; diverging from it silently is FORBIDDEN. The architecture document MUST state its own
  amendment procedure: an ordinary pull request editing it, landing before the diverging spec.
  Amending it MUST NOT require a decision record — it is not on the compatibility-sensitive
  surface — so the sanctioned route stays cheaper than the workaround.
- **FR-024**: The follow-up list MUST identify which entry serves the internal consumer whose
  YAML-driven assertion mechanism is being removed, so that its open decision receives a
  concrete answer.
- **FR-025**: This feature MUST produce no schema, no validator, no parser, no renderer, no
  tool mapping and no executable artifact. Its output is documentation and governance only.

### Key Entities

- **Architecture document**: the end-to-end account of how a requirement becomes a verdict,
  and the reference every later spec is checked against.
- **Component role**: a named job in that account, defined by what it is handed, what it
  returns, and what it may not know. Roles are contracts, not modules.
- **Target class**: load generators, which produce traffic and can sometimes assert during a
  run; monitoring backends, which hold telemetry, answer queries and can host standing
  monitors. Different capabilities, identical support mechanism.
- **Data source**: whatever supplies normalised series to evaluation for one run — an OTLP
  stream, a Prometheus instance, a JTL file. Inbound, and a parameter of evaluation rather
  than a property of a requirement. Distinct from a monitoring backend, which faces outbound;
  one product may be both, in which case it is named by the role it is playing.
- **Artifact class**: a kind of thing the repository holds — normative core, decision records,
  tool mappings, conformance corpus, experimental area, reference implementation — each with one
  home and one rule for changing it.
- **Compatibility-sensitive surface**: the published set of things that cannot change without
  a decision record.
- **Experimental area**: the parked part of the repository. Outside that surface,
  self-labelling, and removable in one piece.
- **Follow-up spec**: one concrete implementation task with a stated boundary, a stated
  dependency, and the architectural role it fills.
- **Principle**: a written rule that decides a recurring argument, carrying what it forbids,
  the failure it prevents, and the case it settles.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader who has read nothing else can trace one example requirement from
  authoring to outcome, naming every component, using the architecture document alone.
- **SC-002**: One named requirement document —
  `docs/examples/checkout-perf.yaml` — unchanged in
  every character, is walked end to end for each of the three load generators, and all three
  walkthroughs are published. The four monitoring backends are not walked here: the claim
  that the same document reaches them is published as explicitly unverified and dated, and is
  owned by the parked follow-up spec.
- **SC-003**: Every principle adopted carries a citation to committed text or to a decision
  already taken here, resolvable by file and section without reading git history; principles
  carrying none are zero.
- **SC-004**: The constitution's version reflects the amendment, or the specification states
  explicitly that no amendment was needed — silence about it is a failure.
- **SC-005**: Every artifact class has exactly one home; the number of artifact classes with
  no home or two homes is zero.
- **SC-006**: A newcomer given only the layout document correctly names every file needed to
  add a new target.
- **SC-007**: Deleting the experimental area in one operation changes zero files outside it.
- **SC-008**: Every follow-up spec named has a boundary, a dependency and an architectural
  role; the number of individual deliverables claimed by two of them is zero.
- **SC-009**: The internal consumer's open question about replacing its YAML-driven assertion
  mechanism is answered by a named follow-up spec rather than left pending.
- **SC-010**: This feature adds zero executable artifacts and zero constructs to the
  requirement vocabulary.
- **SC-011**: Every artifact in the experimental area states its own status and its promotion
  and retirement conditions — 100%, verifiable by inspection.
- **SC-012**: No construct the architecture admits is expressible only while a run is in
  progress — verified construct by construct.
- **SC-013**: Every word this feature introduces carries a rejected alternative in exactly one
  home; the number of introduced words with no rejected alternative, or with one in both
  homes, is zero.
- **SC-014**: Every statement in the architecture document is marked either binding or
  proposed; the number of unmarked statements is zero.

## Assumptions

- **Deliverable class.** This feature produces documentation and governance: the architecture
  document including three worked walkthroughs over one named example, the layout document,
  the constitution amendment, glossary entries for any new term, and the follow-up list. No
  schema, no validator, no code, no tool mappings. This is
  the request's explicit instruction and it matches the constitution's ordering, in which a
  term is fixed in the glossary before anything encodes it.
- **Everything already decided stays decided.** The surface syntax (a JSON-compatible subset
  of YAML, strict parsing, camelCase), the borrowing of OpenTelemetry names, the three-layer
  vocabulary and the conformance levels are inputs to this feature, not subjects of it.
- **The core vocabulary is frozen, not audited.** Constructs that depend on an unratified
  attribute, on stored run history, or on a tool capability keep their place; the architecture
  is obliged to expose those dependencies, not to remove them.
- **Target users.** The author is a performance or QA engineer stating requirements; the
  consumers are load testing adapters, CI backends and monitoring integrations. Requirements
  outlive the tests that check them, which is why a requirement document may not name a tool.
- **Priority targets.** k6, Gatling and JMeter for load generation — the three this feature
  actually works through. Datadog, Prometheus, VictoriaMetrics and InfluxDB name the parked
  monitoring experiment's intended scope, chosen to span one commercial sketch-based stack,
  two label-and-bucket stacks and one with a different data model, so the vocabulary is
  stressed rather than fitted to one backend. Naming them here is a statement of intent, not
  a demonstration.
- **Named consumer.** The organisation's Gatling wrapper is removing its YAML-driven assertion
  mechanism and has recorded that a replacement decision is needed. That is why a renderer for
  it ranks first among the follow-up specs.
- **Governance.** The constitution v1.0.0 applies in full; where this specification and the
  constitution disagree, the constitution wins until amended. Work belongs to the active
  milestone `v0.2.0`. (`v0.1.0` was tagged, released and closed on 2026-08-18.)
- **Verification.** `bash scripts/verify.sh` remains the gate: sketches parse, internal links
  resolve, documents stay English, examples announce themselves as unvalidated. Extending it
  is out of scope here, because this feature adds nothing it could validate.

## Dependencies

- **The ratified constitution** ([constitution.md](../../.specify/memory/constitution.md)) —
  amended by this feature, and binding on it in the meantime.
- **The existing vocabulary and decision records** (`reference/glossary.md`,
  `reference/adr/0001-terminology.md`,
  `reference/adr/0002-compatibility.md`) — inputs, not subjects.
- **The verified tool survey** (`reference/compatibility.md`) — what each
  tool actually emits as of August 2026. Any new claim about a tool or a monitoring backend
  must be checked the same way and dated.
- **Four monitoring backends' query semantics** — Datadog, Prometheus, VictoriaMetrics and
  InfluxDB. Outside this project's control, and the reason that direction is parked.
- **The internal Gatling wrapper's pending replacement decision** — the counterparty for
  SC-009. Outside this repository, and its schedule is not controlled here.
