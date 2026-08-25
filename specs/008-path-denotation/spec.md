# Feature Specification: The Denotation Of A Path

**Feature Branch**: `008-path-denotation`

**Created**: 2026-08-25

**Status**: Draft

**Input**: User description: "https://github.com/galax-io/opennfr/milestone/7" — milestone **v0.5.0**, six issues: #68, #53, #54, #70, #71, #69. Standing instruction with the request: be rational, add no invented or superstructural constructs, fix only what needs fixing.

**Scope note**: Everything the first OpenNFR renderer found ([galax-io/gatling-picatinny#236](https://github.com/galax-io/gatling-picatinny/issues/236)) is split across milestones v0.4.0–v0.8.0 in the order the work has to happen. This is the second of them. v0.4.0 (`specs/007-reach-table-rules/`) made the selection axis partition by the pair (key set, value) instead of by key set alone. This milestone answers the question that partition raised and did not settle: **what a selection row denotes**. Today a row states a key set and a value and stops there, while the target resolves the same row against a request's full recorded position — its enclosing groups, in order, then its name. Four of the six issues are that gap seen from four sides; one is the schema node the previous release meant to edit and missed; one is a second copy of the whole contract that never received the previous release's fixes at all.

## Clarifications

### Session 2026-08-25

- **Q**: `README.md` and `specs/004-strip-to-schema/contracts/gatling-reach.md` are two copies of one contract and have drifted. Where does the surviving copy live? → **A**: `README.md`. The contract's tables move onto the page that already claims to explain the format, and the copy under `specs/004-strip-to-schema/contracts/` stops being a source. That file was never history — it was edited in three of the last four releases, and `scripts/verify.sh` names it as the source it implements. A maintained document living in the history directory is what let the two copies drift unnoticed.
- **Q**: A path nesting more than one group is expressible in Gatling and in the format being replaced, and in no OpenNFR construct. Make it expressible now, or record it as a known unexpressible? → **A**: Make it expressible. `loadtest.group.name` in a selector takes an **array of strings** — the request's enclosing groups, outermost first. It is not an additional key and not a rename: the attribute keeps its name, and gains the arity Gatling and the replaced format both have. The scalar form is withdrawn, so each hierarchy has exactly one spelling.
- **Q**: `"*"` on a requirement's selector quantifies. Over what — each distinct value the attribute takes, which is what all three definitions say today, or each request the selector admits, which is what `forAll()` does? → **A**: Each request the target records, stated that way in every place the rule lives. Bring the four homes to one form rather than record the disagreement as a fact about the target: this format is experimental and nothing downstream is pinned to the old wording, so the right move is the definition that is true, not a note explaining why the definition is not.
- **Correction, same session**: a first draft held that omitting `loadtest.group.name` leaves the hierarchy **unconstrained**, so that a request at the root had to be spelled `loadtest.group.name: []` and a bare `{loadtest.request.name: X}` became unrenderable. That was rejected: *if the group key is not given, the hierarchy is empty, and the request is expressible*. The rejection is right and the draft was paying a cost for nothing. The rule below replaces it, the empty-array spelling is withdrawn along with the scalar one, and three of the four published documents need no edit at all.
- **Decision taken during the same session, from a review of the design against the repository** (see *What the review changed*, below): the schema names `loadtest.group.name` in order to constrain its value shape. This is the only way the **schema** can reject a scalar; leaving the schema name-blind would demote that rejection to the gate and make an array valid under every attribute. `README.md`'s claim that attribute names are *"not enumerated by the schema and never will be"* is about which keys are **admitted**, which does not change: any string is still a key. The sentence gains that qualifier rather than becoming false.

### The rule the answers produce

`loadtest.group.name` is **the ordered list of a request's enclosing groups, outermost first**. It is a value like any other, and a selector matches it the way it matches every other entry — by equality. `{loadtest.group.name: [Checkout, Payment]}` selects requests whose hierarchy is exactly those two groups in that order. Nothing about the conjunction reading changes, inside `bad` or anywhere else.

**One rule is added, and no other**:

> Where a selector names a request, an absent `loadtest.group.name` means the **empty** hierarchy — the request has no enclosing group.

Where no request is named, or where `"*"` stands in place of a name, nothing is said about the hierarchy. That is why `{}` stays every request pooled and `{loadtest.request.name: "*"}` reaches every request at any depth: neither names a request, so neither triggers the rule. No carve-out is needed for either.

Every row that renders becomes an **exact** correspondence rather than a narrowing:

| OpenNFR selector | Gatling | |
|---|---|---|
| `{}` | `global` | **can** — no request named, every request pooled |
| `{loadtest.request.name: X}` | `details("X")` | **can** — `X` with no enclosing group, which is what a one-part path resolves against |
| `{loadtest.group.name: [G₁, …, Gₙ], loadtest.request.name: X}` | `details("G₁" / … / "Gₙ" / "X")` | **can** — any depth |
| `{loadtest.request.name: "*"}` | `forAll()` | **can** — once of each request position the run records |

subject to the precondition FR-021 records: the rendered path must not also be the full hierarchy of a recorded group, which the target itself does not resolve.

Three consequences worth naming before planning starts:

- **The quantifier instantiates, with one exception.** #70's second half — *"the quantified row does not instantiate to the singular row"* — was true because the rows could name a request only at depth 0. With the hierarchy unbounded, every request position `forAll()` enumerates is nameable by a row of the same table, and expanding the quantifier by hand yields the same statements. The exception is unnameable rather than unrendered: a request recorded literally as `*`, or one under a group recorded as `*`, since `"*"` is reserved as presence everywhere it appears.
- **The corpus barely moves.** Only `examples/fast-and-reliable.yaml` changes, and only its group value: `Checkout` becomes `[Checkout]`. The other three documents are already correct under the rule.
- **The conjunction survives.** The alternative formulation — *"these two keys do not filter, they spell a position"* — would have carved the addressing pair out of the rule that every entry must match, including inside `bad` and `good`. It is not needed: equality against an ordered list already means exact-hierarchy matching, and one omission rule covers the rest.

### What the review changed

The design above was read back against the repository by five independent reviewers, one per surface. Their concrete findings were checked by hand before being accepted; the ones that held changed this document:

| Found | Verified how | Where it landed |
|---|---|---|
| Deleting the contract dangles **six real markdown links** in `specs/004-strip-to-schema/` (`plan.md` ×2, `quickstart.md` ×1, `tasks.md` ×3) and turns the gate red | reproduced: remove the file, `bash scripts/verify.sh` → 6 FAILs under *Internal markdown links resolve* | FR-003, FR-004 — the file becomes a dated redirect instead of being deleted |
| An array value is rejected by the schema **today**, for every attribute | `['A','B'] is not of type 'string', 'number', 'boolean'` | the edge case that claimed otherwise is corrected; FR-008 states the exact edit |
| The schema cannot reject a **scalar** `loadtest.group.name` without naming the attribute | `$defs/selector` carries `additionalProperties` and no `properties` | the fifth clarification above; FR-008, FR-013 |
| The provenance note cites `mappings/gatling.yaml @ cb7cb58`, and `mappings/` **does not exist** | `ls mappings` → no such file | FR-007 — the dead citation is dropped rather than carried over |
| `{loadtest.group.name: [G]}` with no request name has **no defined meaning** under the design | read back against #52 | FR-019 — it is defined and stays a **cannot** row |
| "Once of each request the selector admits" counts **occurrences**, a third granularity after the two being replaced | `forAll()` maps `allRequestPaths()` to one `Details` per path | FR-022 — the quantifier ranges over recorded request **positions** |
| Rows 2 and 3 are not provably exact: `findPathByParts` has a **Group** branch as well as a Request one, so a group sharing a request's full path is unaccounted for | the branch is recorded in #52; the resolution order is not | FR-021 — evidence required and dated before exactness is claimed; SC-003 carries the exception until then |
| `$defs/selector` is shared by `bad` and `good`, so the omission rule lands inside a numerator unaddressed | read the schema | FR-020 |
| FR-006 as first written would have obliged edits to `specs/007-reach-table-rules/contracts/reach-selection.md`, a completed feature's delta document | read the file: it is framed as a delta, not a copy | FR-006 is scoped to outside `specs/` |

Sixty-three findings were raised, ten were carried to an adversarial refutation round, and none of those ten survived it — the refutation prompt was written to default to *refuted*, so its output is not evidence of soundness. What is in the table above was verified by hand against the repository, not taken from the refuters.

## User Scenarios & Testing *(mandatory)*

The reader throughout is an implementer building a renderer from the published text — the role that found every defect in this milestone. What they need from each story is a rule they can follow without guessing, one place to read it, and a gate that agrees with the rule.

### User Story 1 - The reach contract has one home (#68, Priority: P1)

An implementer opens `README.md`, the page that says it explains the format, and reads § *What any tool can actually run*. They find a two-column table with the same axes, the same rows and the same dated provenance note as the contract under `specs/004-strip-to-schema/contracts/`, and nothing on the page saying which of the two decides. They build from the one in front of them and emit `details("*")` for `examples/every-request-is-fast.yaml` — the defect #55 closed a release ago, in the copy that never received the fix.

After this story there is one copy, in `README.md`, and it is the full contract rather than a summary of one.

**Why this priority**: it is the only defect in this milestone that hands a reader a rule the repository has already retracted, and it does so on the page most readers meet. Four closed issues — #55, #56, #60, #64 — are live again in that table. It is also first for a mechanical reason: every row the rest of this milestone edits would otherwise have to be edited in two places, which is how this happened.

**Independent Test**: read the shipped repository and count the places a selection, metric, aggregation, operator, unit or threshold rule is stated outside `specs/`. Exactly one document may state each; no other may restate it. Then check the four rules #55, #56, #60 and #64 settled: each appears once, in its post-fix form, and nowhere outside `specs/` in the form its issue retracted.

**Acceptance Scenarios**:

1. **Given** the shipped repository, **When** a reader looks for what Gatling can assert, **Then** they arrive at `README.md`, and no document outside `specs/` restates a row of it.
2. **Given** `examples/every-request-is-fast.yaml`, **When** an implementer follows the published text to a Gatling scope, **Then** the text says `forAll()`, and no text outside `specs/` says `details("*")`.
3. **Given** the surviving tables, **When** their provenance is read, **Then** they carry the source files that still exist and the dates they were checked, in one note rather than two.
4. **Given** the old path, **When** a reader or a link follows it, **Then** they reach a dated line saying the contract moved to `README.md` and nothing else — no table, no rule, no second source.
5. **Given** the change, **When** `bash scripts/verify.sh` runs, **Then** no markdown link dangles, and the gate names `README.md` as the source it implements.

---

### User Story 2 - A path of any depth can be written (#53, Priority: P2)

The requirement *"the 99th percentile of `GET /test/id`, inside group `Payment`, inside group `Checkout`, must stay under 1500 ms"* is ordinary in Gatling — `details("Checkout" / "Payment" / "GET /test/id")` — and ordinary in the NFR-YAML path this format replaces, which splits its scope key on `" / "` with no depth bound. It is unwritable here: a `selector` is an object, so `loadtest.group.name` appears once and carries one scalar, and `$defs/selector` rejects an array for every attribute.

Every workaround is closed by the format's own rules, which is why it is reported rather than worked around. `loadtest.group.name: "Checkout / Payment"` denotes a group whose recorded name is those eighteen characters, because selector values are literal. An invented second key is unrenderable and rejected by the gate. `annotations` and `displayName` are inert.

After this story `loadtest.group.name` carries the enclosing groups as an ordered list, outermost first, at any depth.

**Why this priority**: it is the construct the two stories after it rest on. An unbounded hierarchy is what lets User Story 4's quantifier instantiate into rows of the same table, and what makes User Story 3's rows exact at every depth rather than only at depth 0 and 1. It also stands alone: it is a hard parity stop for a consumer today.

**Independent Test**: write the three-level requirement above as an OpenNFR document, validate it against the published schema, and run it through `scripts/verify.sh`. It must validate, must be accepted as assertable, and the published text must say which Gatling path it renders to without the reader inferring anything.

**Acceptance Scenarios**:

1. **Given** the shipped schema, **When** a document selects `{loadtest.group.name: [Checkout, Payment], loadtest.request.name: GET /test/id}`, **Then** it validates, and the published rows say it renders to `details("Checkout" / "Payment" / "GET /test/id")`.
2. **Given** the shipped schema, **When** a document writes `loadtest.group.name` as a scalar, **Then** the **schema** rejects it — not the gate alone: a hierarchy has one spelling, and a scalar would be a second one for the depth-one case.
3. **Given** the shipped schema, **When** a document writes `loadtest.group.name: []`, **Then** it is rejected: "no enclosing group" is said by omitting the key, and the empty list would be a second spelling of it.
4. **Given** a group whose recorded name literally contains `" / "`, **When** it is written as one element of the list, **Then** the text states it denotes that name and not a nesting — the exact spelling the replaced format used for nesting.
5. **Given** any attribute other than `loadtest.group.name`, **When** a document gives it an array value, **Then** it is rejected exactly as it is today: the arity is added to one named attribute, not to selector values in general.

---

### User Story 3 - A selection row says which requests it denotes (#54, Priority: P3)

An author writes `selector: {loadtest.request.name: POST /checkout}`. By the format's definition of a selector — a conjunction of attribute equalities, where a missing key constrains nothing — that means every request recorded under that name, wherever it sits. The contract maps the row to `details("POST /checkout")`, which Gatling resolves against the request's **full** recorded hierarchy: a one-part path matches only a request with no enclosing group. The row narrows the statement at render time and nothing said so.

The corpus already carries both readings of one name — `examples/one-request-is-fast.yaml` selects `POST /checkout` with no group, `examples/fast-and-reliable.yaml` puts a request of that name inside group `Checkout` — and nothing in either document distinguishes them.

After this story the narrowing is gone because the definition matches the render: naming a request without naming groups **means** the request has none. The two corpus documents become distinguishable from the documents alone, and neither needs a new key to say it.

**Why this priority**: it is the milestone's stated first concern and the reason the milestone exists — *"a one-part path's anchor has to be stated before depth can be discussed"*. It sits below User Story 2 only because the hierarchy is unbounded once that story lands, and stating the rule at depth 1 and then again at depth n would be stating it twice. The two-part row carries the same unstated narrowing today: `{loadtest.group.name: G, loadtest.request.name: X}` resolves only where `G` is the request's **only** group, which is a stronger claim than "X is inside a group called G".

**Independent Test**: hand an implementer the shipped rows and the two corpus documents that share the name `POST /checkout`, and ask which Gatling scope each renders to and why they differ. Both answers must come from the text.

**Acceptance Scenarios**:

1. **Given** the published text, **When** an implementer reads the rule, **Then** it says that where a selector names a request, an absent `loadtest.group.name` means the empty hierarchy — one rule, stated once.
2. **Given** the published text, **When** a reader asks whether this breaks "every entry must match", **Then** the answer is no and the text says why: the entry is matched by equality like any other, and the rule governs only what an *absent* entry means beside a named request.
3. **Given** `{}` and `{loadtest.request.name: "*"}`, **When** they are read under the rule, **Then** neither names a request, so neither is anchored — stated, not left to be inferred.
4. **Given** `examples/one-request-is-fast.yaml` and `examples/fast-and-reliable.yaml`, **When** they are read after this story, **Then** each states its request's position, the two are distinguishable from the documents alone, and neither needed a new key.
5. **Given** each row of the selection table, **When** it is read, **Then** it names the set of recorded requests it denotes, and every rendering row is an exact correspondence rather than a narrowing recorded as a note.

---

### User Story 4 - The quantifier enumerates what the target enumerates (#70, Priority: P4)

`{loadtest.request.name: "*"}` is the blanket requirement and the reason `"*"` was given a quantified reading in v0.4.0. All three definitions of the value say the quantifier ranges over **attribute values** — "each distinct value is a statement of its own". Gatling's `forAll()` ranges over recorded **request positions**, keyed by group path and name. A simulation with `group("Checkout"){ http("GET /") }` and `group("Search"){ http("GET /") }` records one value and produces two assertions; where the two positions have p95 of 2 s and 4 s, the document as defined states one bar over a pooled value that could pass, and the run states two, one of which fails.

The prose that accompanies the rule does not agree with the rule: the contract's row already reads "one assertion per observed request", while `GLOSSARY.md` and `README.md` read "one bar per named request" and the definition above them reads "each distinct value". Three granularities across four documents, and only one of them is what runs.

After this story one definition — *stated once of each request position the run records* — reads the same in all four homes, and it is the set the target enumerates.

**Why this priority**: it produces a wrong verdict rather than an unanswerable question, which puts it above everything below it. It sits under User Stories 2 and 3 because its second half — that the quantified row does not instantiate into the singular rows — stops being true once the hierarchy is unbounded, so settling those first turns an exception into nothing at all.

**Independent Test**: state the rule from each of its four homes for a simulation in which one request name is recorded under two different hierarchies, and check that all four enumerate the same statements, and that expanding the quantifier by hand into rows of the same table yields those same statements.

**Acceptance Scenarios**:

1. **Given** a simulation recording one request name under two different hierarchies, **When** the quantified selector is read from `GLOSSARY.md`, `README.md`, the schema or the selection row, **Then** every home says the same number of statements, and it is the number the target produces.
2. **Given** the definition, **When** it is read against a single request position observed many times in a run, **Then** it makes one statement about it and not one per occurrence — the granularity is the position, which is what a singular row names.
3. **Given** the quantified row, **When** an implementer expands it by hand into the singular rows of the same table, **Then** the expansion is the same set of statements, at every depth.
4. **Given** the published text, **When** it explains why `"*"` reaches a scope that carries no path, **Then** the reason is that `"*"` is not a name, so the anchoring rule does not fire — one rule, not a special case for one row.
5. **Given** `GLOSSARY.md`'s `selector` entry, **When** it is read after this story, **Then** it records what the previous wording got wrong, as Principle I requires of a redefinition, and the prose gloss beside the definition says what the definition says.

---

### User Story 5 - The schema carries the definition on the node that defines it (#71, Priority: P5)

v0.4.0 set out to redefine `"*"` in the three places it is defined and reached two. The schema edit landed on `$defs/requirement.properties.selector` — an annotation sitting beside a `$ref` — while `$defs/selector`, the node `bad` and `good` inherit and the node a reader opening the schema at the definition of a selector finds, still carries the pre-#55 wording byte for byte: presence, full stop. Sibling keywords next to `$ref` were ignored entirely before draft 2019-09 and are annotation-only now, so a schema-driven consumer or documentation generator can still be shown the narrower meaning.

After this story the value semantics sit on the node that defines a selector, no second node restates them, and they carry what User Stories 2, 3 and 4 settled.

**Why this priority**: it is the schema half of everything above it and has to carry whatever those stories settle, so it follows them. On its own it is a two-node correction with no argument left in it.

**Independent Test**: read `$defs/selector.description` alone, with no other file open, and check it states the same rule `GLOSSARY.md` states — the list form of a hierarchy, what an absent hierarchy means beside a named request, and that `"*"` does not quantify inside `bad` or `good`. Then check no other node in the schema states those a second time.

**Acceptance Scenarios**:

1. **Given** the shipped schema, **When** `$defs/selector` is read on its own, **Then** its description carries the settled meaning of `"*"` and of a list value.
2. **Given** a consumer that drops annotations sibling to `$ref`, **When** it renders the schema's account of a requirement's selector, **Then** what it shows is not narrower than what `GLOSSARY.md` says.
3. **Given** the sibling annotation on `$defs/requirement.properties.selector`, **When** it is read after this story, **Then** it says only what is true of a requirement's selector and of no other selector — that it is written once and binds every criterion and guard beneath it — and restates none of the value semantics.

---

### User Story 6 - A guard under a quantified selector is quantified too (#69, Priority: P6)

A selector is written once and binds a requirement's guards as well as its criteria. So the guard that says *the run happened at all* — `aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"`, character for character the one in `examples/the-run-held-up.yaml` — renders `global.requestsPerSec.gte(200)` under `selector: {}` and `forAll().requestsPerSec.gte(200)` under `{loadtest.request.name: "*"}`. The second means *each request position reached 200 rps*, which nobody wants, and on a run that recorded nothing it expands to zero assertions and passes: vacuous in exactly the case it exists to catch.

`examples/every-request-is-fast.yaml` admits the empty-run hazard and points the reader at `the-run-held-up.yaml` for the remedy. The remedy works there **because that document says `{}`**. Under the selector that creates the hazard it does not, and the escape — a second, guard-only requirement scoped `{}` — does not validate, because `requirement.required` is `["name", "selector", "criteria"]` and `criteria` is `minItems: 1`. That is #61, open in v0.8.0.

After this story the example says where the guard has to sit, and says that today it cannot sit alone.

**Why this priority**: nothing else depends on it, and the correction is a sentence in one example plus a line in the tables. It is last because it is smallest, not because it is optional — the pointer it fixes is one this repository added a release ago and which currently resolves to nothing in both directions.

**Independent Test**: follow the note in `examples/every-request-is-fast.yaml` to its remedy and check that the remedy, as written, applies to the document that sent you there.

**Acceptance Scenarios**:

1. **Given** `examples/every-request-is-fast.yaml`, **When** a reader follows its note about a run that recorded nothing, **Then** the text says the guard has to sit on a `{}` requirement, and that a guard-only requirement is not valid today.
2. **Given** the published tables, **When** the quantified selection row is read, **Then** it states that a requirement's guards are quantified with its criteria, because the selector is written once for both.
3. **Given** the corpus, **When** the gate runs, **Then** no published document carries a guard whose meaning depends on being read as unquantified while its selector quantifies.

---

### Edge Cases

- A request name occurring both with no group and inside a group. After this milestone these are two hierarchies and both are writable — the bare name and `[G]` — so a document says which one it means without a new key.
- A group and a request sharing a full path — a simulation with `group("X"){ … }` beside a root-level `http("X")`. Gatling resolves a path against group hierarchies and request hierarchies out of one hash map, first key wins, so which one `details("X")` denotes is not decided by Gatling and can flip when an unrelated request is added. Where the group wins, the assertion silently measures the group's cumulated response time. FR-021 makes this a dated precondition on the rows rather than something a format-side construct pretends to fix.
- A `"*"` element inside a hierarchy — `{loadtest.group.name: ["*"], loadtest.request.name: X}`. Admitted by the schema the moment the array form is, and unrenderable: a hierarchy is matched by equality and an element that is not a name leaves the path unwritten. FR-011 states it and FR-035 probes it — the probe it replaces, which rejects the scalar `loadtest.group.name: "*"`, stops describing anything writable once the scalar form is withdrawn.
- A run that recorded no requests at all. `forAll()` yields zero assertions and exits successfully; a `details(...)` path that matches nothing fails with a resolution error. Both stay recorded as facts about the target; User Story 6 adds only where the guard that catches the first has to sit.
- A group whose recorded name literally contains `" / "`. A legal group name and a legal element of the list, denoting that name and not a nesting.
- A selector carrying `loadtest.group.name` and no request name, at any depth. It has a meaning — the requests whose hierarchy is exactly those groups — and no row, because a group-scoped Gatling assertion measures a cumulated duration the format cannot name. That is #52 in v0.6.0 and is not settled here.
- An array value under any other attribute — `{http.route: [a, b]}`. Rejected by the schema, exactly as it is today. The arity is added to one named attribute, not to selector values in general.
- A quantified selector on an attribute that is not a request address — `{http.route: "*"}`. Unassertable against Gatling in any reading, and the format is not narrowed to Gatling, so the settled definition of the quantifier has to stay readable for it.
- `bad` and `good` share the node the list form and the anchoring rule land on. Both apply there too, and both are inert there in practice, because the only renderable numerator is `{error.type: "*"}`.

## Requirements *(mandatory)*

### Functional Requirements

**One home for the contract (#68)**

- **FR-001**: The correspondence between OpenNFR constructs and what Gatling can assert MUST be stated in exactly one document outside `specs/`, and that document is `README.md`.
- **FR-002**: `README.md` MUST carry the full tables — selection, metric, aggregation, operator, unit, threshold — with the reasons each row records, not a summary of them.
- **FR-003**: `specs/004-strip-to-schema/contracts/gatling-reach.md` MUST stop being a source. It MUST be reduced to a dated line saying the contract moved to `README.md`, rather than deleted outright, because six markdown links in three files of the same completed spec resolve to it and the gate fails on a dangling link.
- **FR-004**: No markdown link anywhere in the repository may dangle after the change, and no file under `specs/` other than the one named in FR-003 may be edited to achieve that.
- **FR-005**: `scripts/verify.sh` MUST name `README.md` as the source it implements, and MUST remain the only implementation of the tables.
- **FR-006**: The rules settled by #55, #56, #60 and #64 MUST appear in `README.md` in their post-fix form, and MUST NOT appear anywhere **outside `specs/`** in the form each of those issues retracted. Documents under `specs/` are the working record of the features that made those decisions and are left as written.
- **FR-007**: The provenance note MUST carry the Gatling source files it cites, the dates they were checked, and a date for the rows this milestone writes. It MUST NOT carry over the citation of `mappings/gatling.yaml @ cb7cb58`, which names a file the repository no longer contains.

**A hierarchy of any depth (#53)**

- **FR-008**: `$defs/selector` MUST constrain `loadtest.group.name` by name to an array of strings with at least one element. Naming the attribute is what lets the **schema** reject a scalar and an empty list; `additionalProperties` MUST be left as it is, so an array under any other attribute stays rejected.
- **FR-009**: The array MUST denote the request's enclosing groups in order, outermost first, with no bound on depth in the schema, the tables or the gate.
- **FR-010**: The scalar form MUST be withdrawn and the empty array MUST be rejected, so that each hierarchy has exactly one spelling: a list of at least one name, or the key omitted.
- **FR-011**: The published text MUST state that an element of the list is a literal recorded name, so a group named with `" / "` in it denotes that name and not a nesting. It MUST also say what a `"*"` **element** means — `{loadtest.group.name: ["*"], loadtest.request.name: X}` is admitted by the schema the moment the array form is — and why it has no correspondence: a hierarchy is matched by equality, and an element that is not a name leaves the path unwritten.
- **FR-012**: `GLOSSARY.md` MUST record the change and at least one rejected alternative, as Principle I requires — the alternatives on the table being a separate `loadtest.group.path` key, a scalar-or-array union, and an empty-array spelling of "no groups", each rejected as a second spelling of something already sayable.
- **FR-013**: `README.md`'s statement that attribute names are *"not enumerated by the schema and never will be"* (`README.md:244`) MUST be qualified rather than left false: any string is still admitted as a key, and the schema constrains the value shape of the one name the format defines for a hierarchy. The sibling claim at `README.md:188-189` — that `selector`'s *"keys are attribute names and cannot be enumerated in advance"* — stays true unchanged and MUST be checked and left alone rather than edited by reflex: naming one key to constrain its value does not enumerate which keys are admitted.

**What a selection row denotes (#54)**

- **FR-014**: The published text MUST state the anchoring rule once: where a selector names a request, an absent `loadtest.group.name` means the empty hierarchy.
- **FR-015**: The text MUST state that this is the only rule added, and that a selector remains a conjunction matched by equality — including inside `bad` and `good`.
- **FR-016**: `{}` and `{loadtest.request.name: "*"}` MUST be shown to follow from the rule without a carve-out: neither names a request, so neither is anchored.
- **FR-017**: Each selection row that renders MUST name the set of recorded requests it denotes.
- **FR-018**: No published document may need a new key to state its request's position. `examples/one-request-is-fast.yaml`, `examples/every-request-is-fast.yaml` and `examples/the-run-held-up.yaml` MUST be correct as they stand; only the group value in `examples/fast-and-reliable.yaml` changes.
- **FR-019**: A selector carrying `loadtest.group.name` and no request name MUST be given a meaning — the requests whose hierarchy is exactly those groups — and MUST stay a **cannot** row, with #52 named as the open question about whether a group-scoped statement should exist at all.
- **FR-020**: The text MUST say how the list form and the anchoring rule read inside `bad` and `good`, since both share the node they land on.
- **FR-021**: Rows 2 and 3 MUST carry, as a dated statement about the target, the precondition that makes them exact: **the rendered path must not also be the full hierarchy of a recorded group.** Where it is, Gatling's own resolution is unspecified — `findPathByParts` is a `collectFirst` over the keys of a `mutable.HashMap` holding request and group paths together, so which one matches depends on hash order and can change when an unrelated request is added — and where the group wins, the assertion measures that group's *cumulated* response time instead of the request's. The rows MUST NOT claim to denote one or the other, because the target does not.

**The quantifier (#70)**

- **FR-022**: `"*"` on a requirement's selector MUST be defined as stating the requirement once of each **request position** the run records — not once per distinct attribute value, and not once per occurrence.
- **FR-023**: The text MUST derive the quantified row from the anchoring rule rather than exempt it: `"*"` is not a name, so the rule does not fire and no hierarchy is claimed.
- **FR-024**: That definition MUST read the same in `GLOSSARY.md`, in `README.md`, in the schema and in the selection row, and the prose gloss beside it MUST say what it says. This is a **milestone-end** requirement, satisfied at #71: the schema's only statement of `"*"` sits on the node #71 exists to correct, so satisfying it earlier would mean writing the new definition onto the wrong node and deleting it a commit later.
- **FR-025**: The quantified row MUST instantiate into the singular rows of the same table at every depth. Where it does not, the failure is a defect in the rows and not an exception to be recorded.
- **FR-026**: `"*"` MUST NOT quantify inside `bad` or `good`, which narrow a numerator and produce one number. This is unchanged and MUST survive the rewording.
- **FR-027**: `GLOSSARY.md`'s `selector` entry MUST record what the previous wording got wrong.

**The schema node (#71)**

- **FR-028**: `$defs/selector.description` MUST carry the settled meaning of `"*"`, of a list value, and of an absent hierarchy beside a named request, including that `"*"` does not quantify inside `bad` or `good`.
- **FR-029**: The annotation beside `$ref` on `$defs/requirement.properties.selector` MUST restate none of that. It MUST keep only what is true of a requirement's selector and of no other — that it is written once and binds every criterion and guard beneath it, which is also what FR-032 needs stated.
- **FR-030**: Apart from the constraint FR-008 adds, the schema MUST keep every constraint it has.

**The guard under a quantifier (#69)**

- **FR-031**: `examples/every-request-is-fast.yaml` MUST state that the guard it points the reader at has to sit on a `{}` requirement, and that a guard-only requirement does not validate today.
- **FR-032**: The published tables MUST state that a requirement's guards are quantified with its criteria, because the selector is written once for both.
- **FR-033**: This milestone MUST NOT add a per-guard selector or relax `requirement.required`. Whether guards carry their own selection is #61, in v0.8.0.

**Constraints on the whole change**

- **FR-034**: The only construct entering the format is the list form of `loadtest.group.name`, admitted because Gatling asserts it exactly, as the constitution's floor requires. No other field, key or value may enter.
- **FR-035**: Every rule the tables carry MUST be backed by a probe in `scripts/verify.sh` that fails if the rule is deleted, including the rejections in FR-010 and the depth admitted by FR-009.
- **FR-036**: `scripts/verify.sh` and `README.md` MUST agree row for row after every commit of this milestone.
- **FR-037**: Every document in `examples/` MUST pass `bash scripts/verify.sh` under the settled rules.
- **FR-038**: Nothing here narrows the format to Gatling. A row saying a shape does not render is a statement about the target; the shape stays valid under the schema unless the schema rejects it for a reason of its own — as FR-010 does, because two spellings of one statement is a format defect and not a target's limitation.
- **FR-039**: #52, #57, #62, #58, #59, #72, #73, #74, #75, #61 and #63 MUST NOT be settled by implication. Where a change here touches their premises, it MUST say so rather than close them silently.

### Key Entities

- **Group hierarchy**: the value of `loadtest.group.name` in a selector — an ordered list of at least one recorded group name, outermost first. Matched by equality like any other entry. Beside a named request, its absence means the hierarchy is empty.
- **Request position**: a request's place as the target records it — its hierarchy, then its name. What a singular row names and what the quantifier ranges over.
- **Selection row**: one line of the correspondence — an OpenNFR selector shape, the Gatling scope it renders to, and whether it renders at all. This milestone gives each row a denotation: the set of recorded requests it picks out.
- **Quantified selection**: a requirement's selector carrying `"*"` in place of a request name, stating the requirement once of each request position the run records. It names no request, which is why the anchoring rule does not fire and why it reaches a scope that carries no path.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An implementer following the published text from `README.md` to a Gatling scope for every document in `examples/` arrives at one answer per document, and each is what the gate accepts. Today `examples/every-request-is-fast.yaml` has two published answers, `forAll()` and `details("*")`, and one of them fails the run.
- **SC-002**: Every rule of the correspondence is stated exactly once in the repository outside `specs/`. Counted by reading, not asserted.
- **SC-003**: Every selection row in the **can** column is an exact correspondence: the set of recorded requests the row denotes and the set the Gatling scope resolves to are the same set, for a simulation of any group depth — under the one precondition FR-021 names, which is stated on the rows it affects with its date and its source, and which no format-side construct can close because the target's own resolution is unspecified there. No row in that column is a narrowing recorded as a note.
- **SC-004**: The three-level requirement from #53 — a request inside `Payment` inside `Checkout` — is written as an OpenNFR document, validates against the published schema, and is accepted by the gate. It cannot be written at all today.
- **SC-005**: A scalar `loadtest.group.name`, an empty list, and an array under any other attribute are each rejected by the **schema**, checked with the one-liner `README.md` publishes. Two of the three validate today.
- **SC-006**: Three of the four published documents are unchanged by this milestone, and the fourth changes one value. A rule that made the corpus rewrite itself would be a rule the corpus was already disagreeing with.
- **SC-007**: For a simulation in which one request name is recorded under two different hierarchies, the number of statements `{loadtest.request.name: "*"}` makes is the same read from `GLOSSARY.md`, from `README.md`, from the schema and from the selection row, and equals the number of assertions the target produces.
- **SC-008**: Expanding `{loadtest.request.name: "*"}` by hand into singular rows of the same table yields the same set of statements as the quantified row, for a simulation of any group depth.
- **SC-009**: `$defs/selector.description` read alone states the same rule as `GLOSSARY.md`, and neither that rule nor any part of it appears a second time in the schema.
- **SC-010**: `bash scripts/verify.sh` passes at every commit of the milestone, and deleting any one selection rule from it fails the gate — proven by a probe per rule, including the rules this milestone adds.
- **SC-011**: The six issues #68, #53, #54, #70, #71 and #69 are closed by the commits that land on `main`, each as one semantic commit green on its own, each assigned to milestone v0.5.0.
- **SC-012**: Exactly one construct enters the format — the list form of `loadtest.group.name` — argued in #53 before it is written, with its rejected alternatives recorded in `GLOSSARY.md`.

## Assumptions

- The Gatling evidence in #70, #54, #53 and #52 — `AssertionValidator.resolvePath` on `ForAll` mapping `allRequestPaths()` to one `Details` per path, `LogFileData.findPathByParts` comparing `group.hierarchy ::: List(request)` by equality, and `AssertionPathParts` being an unbounded `List[String]` — was re-read from primary source on 2026-08-25, at `gatling/gatling` tags `v3.15.1` and `v3.13.5`, where the four methods are identical. It holds, and it settles two things the issues left open. `allRequestPaths()` `collect`s only the request keys of a map, so `forAll()` enumerates each recorded **position** exactly once — never a group, never once per occurrence — which is what FR-022 is written from. And the request/group collision is not an order question at all: both key kinds live in one `mutable.HashMap` and `collectFirst` takes whichever the hash reaches first, so FR-021 states a precondition rather than a resolution order.
- One part of that evidence is a **replication, not a reading**: the demonstration that the collision's outcome flips when unrelated requests are added was produced by re-implementing the three case classes on the Scala version `build.sbt` pins, not by running Gatling. The source reading is verified; the instability is shown by replication and is labelled that way wherever it is stated, as Principle IV requires.
- **Making `README.md` the sole home of the contract sits against constitution Principle VI**, which says the correspondence between the document's vocabulary and a target's own must live in that target's description, and that *"adding a target MUST NOT change the format, the schema, or any existing document"*. After this change, adding a second target changes `README.md`. The departure is taken deliberately and recorded here rather than discovered later: the repository has no target-description artifact — the constitution's own Compatibility Constraints removed that surface, noting *"nothing in this repository describes a target"* — and `README.md` has carried a Gatling section since `6d3a882`, so the choice is between one home and two, not between one home and none. A `targets/gatling.md` would honour the principle literally and is the alternative if a second target ever arrives.
- Reducing `specs/004-strip-to-schema/contracts/gatling-reach.md` to a redirect is a departure from reading `specs/` as history, taken because that file was maintained rather than historical. It is the only file under `specs/` this milestone touches; FR-004 makes that a requirement rather than an intention.
- `specs/007-reach-table-rules/` carries a contradiction of its own, reported in #71: SC-008 there requires the schema to be byte-identical to `2f4b15d` while FR-017 in the same document requires a schema edit, and `quickstart.md` was rewritten instead of the criterion. It is not repaired retroactively. What it caused — the wrong schema node — is User Story 5, and this specification's criteria are written so that no two of them can both be met only by editing the other.
- The format is experimental and nothing downstream is pinned to the current wording of `"*"` or to the scalar form of `loadtest.group.name`. That is what makes correcting the definitions cheaper than recording why they are wrong, and it is the instruction this milestone was given.
- The reader of the format is an implementer building a renderer, not an author writing a document. Both are served, but where the two conflict this milestone is written for the first, because every defect in it was found by one.
