# Feature Specification: The Rules By Which The Reach Tables Are Read

**Feature Branch**: `007-reach-table-rules`

**Created**: 2026-08-24

**Status**: Draft

**Input**: User description: "https://github.com/galax-io/opennfr/milestone/6" — milestone **v0.4.0**, four issues: #64, #60, #56, #55.

**Scope note**: Everything the first OpenNFR renderer found ([galax-io/gatling-picatinny#236](https://github.com/galax-io/gatling-picatinny/issues/236)) is split across milestones v0.4.0–v0.8.0 in the order the work has to happen. This is the first of them, and it comes first because the rest write rows into tables that do not yet hold their own invariant. The contract states that invariant at `specs/004-strip-to-schema/contracts/gatling-reach.md:111` — "The tables partition each axis. A predicate is assertable only if it matches a row **exactly**; anything unlisted is rejected" — and on the selection axis it is not true today: that axis is partitioned by *key set*, while what a renderer emits depends on the *value*. #56 was moved into this milestone from v0.5.0 on 2026-08-24; see Clarifications.

## Clarifications

### Session 2026-08-24

- **Q**: `gatling-reach.md` twice justifies a rule by "the approximation Principle III forbids", and the constitution's Principle III (*No Silent Green*) contains no such clause — it was cut in 3.0.0. Restore the clause, or rewrite the argument? → **A**: Rewrite the argument in the contract. The constitution is not amended. It records why the clause was cut — the obligations governed rendering a document into a target's assertions, which no artifact in this repository does — and that reasoning still holds for the constitution even though a renderer now exists elsewhere.
- **Q**: After the fix, what does `{loadtest.request.name: "*"}` correspond to — a rejection, or Gatling's `ForAll` scope? → **A**: `ForAll`. This is the requirement the value was reached for, and it merges #55 with #56, which asks why no selector reaches that scope. #56 was moved from milestone v0.5.0 to v0.4.0 on the same day, and both milestone descriptions were rewritten to match. Mapping the two onto each other does not wait on the path work in v0.5.0, because `forAll()` takes no path.
- **Q**: `README.md:390-391` and the constitution's Principle II both exclude apdex among quantities "computed by aggregation from metrics that already exist", which is false of apdex — no aggregation this format has produces it. Correct the reason, in both documents or in one? → **A**: Neither. `README.md` stops naming apdex among derived quantities at all, which makes the sentence true as written of the two that remain, and apdex becomes an entry of its own in `docs/ideas.md` — where a construct the format does not have belongs under Principle VIII, carrying what would have to become true before it could enter. The constitution's copy is out of scope for this feature and left as it stands; it is recorded rather than dropped silently.
- **Q**: `forAll()` on a run that observed no requests yields zero assertions and exits successfully. Should a requirement using that selection be obliged to carry a guard that fails on zero observed requests, enforced by the gate? → **A**: No. This repository ships a format and the table saying what converts; it does not ship enforcement. Obliging a document to carry an extra predicate to compensate for one target's behaviour narrows the format to that target, which Principle VI and FR-014 of `specs/004-strip-to-schema` both forbid. The absent-data behaviour is a fact about the target and is recorded as one.

## User Scenarios & Testing *(mandatory)*

The reader throughout is an implementer building a renderer from the published text — the role that found all four defects. What they need from each story is a rule they can follow without guessing, and a gate that agrees with the rule.

### User Story 1 - "Every request" can be said, and means what it says (#55, #56, Priority: P1)

An author writes the ordinary blanket requirement — *the 95th percentile of every business operation must be at most 3 s* — and reaches for the one construct the format hands them for "any value": `selector: {loadtest.request.name: "*"}`. Today that document passes the reach gate, because the gate partitions the selector axis by key set and never looks at the value, and then renders to `details("*")` — an assertion about a request literally named `*`, which matches nothing and fails the run with a resolution error unrelated to what was asserted. After this story, the same document corresponds to Gatling's `forAll()` scope, which expands to one assertion per observed request: what the author meant.

**Why this priority**: the only `severity:critical` issue in the milestone, and the only defect here that silently produces a *wrong verdict* rather than an unanswerable question. It also closes the milestone's stated goal — after it, the selection axis is partitioned by the pair (key set, value) rather than by key set alone. It depends on User Story 2 having made the value part of the row at all.

**Independent Test**: write a document selecting `{loadtest.request.name: "*"}`, confirm the gate accepts it, and confirm the contract names exactly one Gatling scope for it. Write the three neighbouring selections that carry `"*"` on a path attribute in any other position and confirm each is rejected with the reason the contract gives.

**Acceptance Scenarios**:

1. **Given** a requirement whose selector is `{loadtest.request.name: "*"}`, **When** an implementer looks the selection up in the contract, **Then** exactly one row matches it and that row names `forAll()`.
2. **Given** a requirement whose selector is `{loadtest.group.name: Checkout, loadtest.request.name: "*"}`, **When** the gate checks it, **Then** it is rejected, because `forAll()` accepts no path and so "every request inside one group" has no correspondence.
3. **Given** a requirement whose selector is `{loadtest.group.name: "*", loadtest.request.name: POST /checkout}`, **When** the gate checks it, **Then** it is rejected for the same reason.
4. **Given** the contract's closing note that a `ForAll` assertion over zero observed requests exits successfully, **When** an implementer reads it, **Then** it explains a row above it rather than describing a scope no document can select.
5. **Given** a requirement whose selector is `{loadtest.request.name: "POST /checkout"}`, **When** the gate checks it, **Then** it is still accepted and still corresponds to `details("POST /checkout")` — a literal value keeps meaning a literal path part.

---

### User Story 2 - A selection row constrains its value, not only its key (#60, Priority: P2)

`$defs/selector` admits `string`, `number` and `boolean` values, and is right to: an attribute value being a number is ordinary (`server.port: 8080`). A Gatling assertion path is a list of strings. The Selection table constrains only which keys are present and never states what the values may be, so an implementer meeting `loadtest.request.name: 200` — which is what YAML 1.1 makes of an unquoted request called `200`, alongside `1.10`, `on`, `off`, `yes` and `no` — either stringifies it (making `200` and `"200"`, two documents that differ, render identically) or rejects it with no authority in the contract to do so. The rule exists, but only in the gate.

**Why this priority**: it is the general form of User Story 1's defect and the thing that makes that story's rows expressible — a row cannot say "`"*"` means `forAll()`" until rows are allowed to talk about values. It also settles, on the record, whether `200` and `"200"` are the same document.

**Independent Test**: write a document whose path value is a number and one whose value is a boolean; confirm both are rejected and that the reason quoted by the gate is a sentence a reader can find in the contract.

**Acceptance Scenarios**:

1. **Given** a requirement whose selector is `{loadtest.request.name: 200}`, **When** the gate checks it, **Then** it is rejected because an assertion path part is a string.
2. **Given** the same rejection, **When** an implementer looks for its authority, **Then** the contract states it and the gate is the check, rather than the gate being the only place it is written down.
3. **Given** a document with `{loadtest.request.name: "200"}`, **When** the gate checks it, **Then** it is accepted — the quoted form is a different document from the unquoted one, and only one of the two is renderable.

---

### User Story 3 - The percentile row is a row (#64 part 1, Priority: P3)

The Aggregations table writes percentiles as `p50`…`p99.9`. A range written with an ellipsis is not something a predicate can match exactly, which is what the contract's own invariant demands. Both ends already agree on something wider: the gate accepts any percentile the schema's pattern admits, and Gatling takes an arbitrary `percentile(double)`. So `p10`, `p25` and `p1` are valid documents that an implementer reading the contract cannot decide.

**Why this priority**: it is the invariant applied to the table that states it, and it is the smallest of the three sentences in #64. Nothing else in the milestone depends on it, but every later milestone writes rows into these tables and will copy whatever shape it finds.

**Independent Test**: take three percentiles the schema admits and the published table does not name — `p1`, `p10`, `p99.99` — and confirm each matches exactly one row.

**Acceptance Scenarios**:

1. **Given** a predicate with `aggregation: p10`, **When** an implementer looks it up, **Then** exactly one row matches, and the row's wording does not require them to interpolate a range.
2. **Given** the row as rewritten, **When** it is compared against the gate and against Gatling, **Then** all three admit the same set.

---

### User Story 4 - Apdex is an idea, not a derived quantity (#64 part 2, Priority: P4)

`README.md` excludes throughput, error rate and apdex from becoming metrics, with one reason for all three: they are computed by aggregation from metrics that already exist. That is exactly right for the first two — throughput is `aggregation: rate`, an error rate is a `bad` fraction. It is false for apdex, which classifies each request into satisfied, tolerating and frustrated against two thresholds (T and 4T) and takes a half-weighted sum of the first two. That needs a banded classification and a weighted aggregation, and this format has neither: its predicate carries one threshold, and a fraction splits a selection in two by attribute presence. So apdex is not a derived quantity being kept out — it is a construct the format does not have, which is what `docs/` is for.

**Why this priority**: the exclusion is not in dispute and no document changes verdict. What changes is that the sentence stops being citable later as evidence that apdex is reachable by aggregation — a question that gets asked, because `APDEX` is a literal key in the NFR-YAML documents this format is meant to replace — and that the answer moves to where a reader looking for an absent construct will find it, with the condition for its return attached.

**Independent Test**: read the paragraph and ask, of each quantity it still names, whether the stated reason is true of it; all must answer yes. Then ask the ideas area whether the format can express apdex, and confirm it answers, with a condition.

**Acceptance Scenarios**:

1. **Given** the rewritten paragraph, **When** a reader asks which aggregation computes each quantity it names, **Then** each has one, and apdex is not among them.
2. **Given** a reader asking whether apdex can be written today, **When** they look in the ideas area, **Then** it answers no and states what would have to become true first.
3. **Given** the new entry, **When** the gate counts the ideas and the conditions in `docs/ideas.md`, **Then** the two counts are equal, as Principle VIII requires.
4. **Given** the constitution, **When** this feature is complete, **Then** Principle II is unchanged — see FR-015.

---

### User Story 5 - The contract argues from text that exists (#64 part 3, Priority: P5)

`gatling-reach.md` twice justifies a rule by "the approximation Principle III forbids" — for the fraction numerator, and for the whole-number threshold rule. Principle III is *No Silent Green*, and its three surviving obligations are about reporting success on missing or unchecked data; it contains no clause about rendering or approximation. Those clauses were cut in 3.0.0, deliberately and on the record. Both rules are right on their own merits; what is wrong is a NON-NEGOTIABLE principle cited twice, in the one document that is supposed to settle arguments, for a clause it does not contain.

**Why this priority**: it changes no rule and no verdict, and it is the part of #64 that the later milestones lean on — v0.7.0's two issues both turn on how this contract argues a rendering rule.

**Independent Test**: follow every constitution citation in the contract and confirm each resolves to text the constitution currently contains.

**Acceptance Scenarios**:

1. **Given** the rewritten contract, **When** a reader follows each of its citations of the constitution, **Then** each names a clause that is present in `.specify/memory/constitution.md`.
2. **Given** the rewritten contract, **When** the two rules are read, **Then** each still states why it holds, and neither has been weakened to a bare assertion.
3. **Given** the constitution, **When** this feature is complete, **Then** it is unchanged by User Story 5.

### Edge Cases

- **`"*"` on a non-path attribute.** `bad: {error.type: "*"}` is untouched: `error.type` is not an assertion path attribute, and the fraction rows already constrain that value exactly. Only `loadtest.group.name` and `loadtest.request.name` are read as path parts.
- **A request genuinely named `*`.** After this change there is no way to assert about it. That is a loss, and it is the right trade: the value the format hands authors for "any value" cannot also be a literal, and a request named `*` is hypothetical while the blanket requirement is the commonest NFR there is. Recorded, not hidden.
- **`{}` is not affected.** `selector: {}` remains `global` — the pooled reading, as the schema, `README.md` and the contract all already say. `forAll()` is reached only through `"*"`, so the two readings of "every request" stay distinguishable.
- **An empty run.** A `forAll()` assertion over zero observed requests yields zero assertions and the run exits successfully. This is a fact about the target, recorded in the contract's closing section; it is not compensated for by any obligation on the document (see Clarifications).
- **A percentile outside the schema's pattern.** `p100` does not match `^p\d{1,2}(\.\d+)?$` — the integer part is capped at two digits — and needs no row: the quantity it names, the slowest observed request, is `max`, already a **can** row.
- **`loadtest.apdex` in the `loadtest.*` registry list.** That list names `loadtest.apdex` among names deliberately absent from the proposed registry, labelled *composite*. It is about a **name** not entering a namespace; FR-013's entry is about a **construct** not entering the format. Both stay, and the label keeps the word the repository already uses.
- **A boolean path value.** `loadtest.request.name: on` parses as `true` under YAML 1.1 and is rejected on the same rule as a number; the reason must not name only numbers.

## Requirements *(mandatory)*

### Functional Requirements

**The selection axis**

- **FR-001**: Every row of the reach contract's Selection table MUST state what values its attributes may carry, not only which keys are present. A row that constrains a key set while leaving the value free does not partition the axis, because what a renderer emits is decided by the value.
- **FR-002**: The contract MUST state that a value carried by `loadtest.group.name` or `loadtest.request.name` and rendered as an assertion path part is a string. A document whose path value is a number or a boolean MUST be a **cannot**, with the reason stated in the contract rather than only in the gate.
- **FR-003**: `{loadtest.request.name: "*"}` MUST be a **can** row corresponding to Gatling's `forAll()` scope.
- **FR-004**: Every other selection carrying `"*"` on a path attribute MUST be a **cannot** row carrying its reason — specifically `{loadtest.group.name: G, loadtest.request.name: "*"}` and `{loadtest.group.name: "*", loadtest.request.name: X}`, both because `forAll()` accepts no path and a group-restricted "every request" therefore has no correspondence.
- **FR-005**: A path value that is not `"*"` MUST continue to denote a literal path part, and the contract MUST make the literal reading explicit rather than leaving it as the residue of the `"*"` rows.
- **FR-006**: The contract MUST NOT describe the behaviour of an assertion scope no document can select. The closing note on `ForAll` and absent data MUST be attached to the row that reaches it.
- **FR-007**: `scripts/verify.sh` MUST implement FR-002, FR-003, FR-004 and FR-005 — rejecting on the pair (key set, value) rather than on the key set alone — and MUST remain the only implementation of these tables.

**How the new rules are demonstrated**

- **FR-008**: Every **cannot** rule added by FR-002 and FR-004 MUST have a probe document that the gate rejects, so that removing the rule fails the gate rather than passing it. The corpus cannot carry these cases: it holds only documents that validate.
- **FR-009**: The probe set MUST have a floor. A probe section that ran zero probes MUST fail rather than report success, on the same ground as the existing `checked == 0` floor in the reach gate: a scan that checked nothing reads exactly like a scan that passed.
- **FR-010**: `examples/` MUST gain one document exercising the `forAll()` selection, so that the new **can** row is exercised by the gate rather than asserted. It MUST state, as the corpus's other documents do, which human sentence it is the writing of.

**The aggregation axis**

- **FR-011**: The Aggregations table's percentile row MUST name exactly the set of aggregations the schema's pattern admits, without an ellipsis and without implying a restriction that neither the gate nor Gatling imposes.

**Names**

- **FR-012**: `README.md`'s exclusion of derived quantities MUST name only quantities of which the stated reason is true. Apdex MUST leave that sentence: it is not computed by an aggregation this format has. That apdex must not become a metric does not change — only where the format says so, and why.
- **FR-013**: `docs/ideas.md` MUST gain an entry for apdex as a construct rather than as a name, stating what it would buy and what would have to become true before it could enter the format: a classification of each request into bands against two thresholds, and an aggregation that takes a weighted sum of those bands. The entry MUST carry its condition in the form Principle VIII's gate counts, so that ideas and conditions stay one to one.

**Citations**

- **FR-014**: The contract MUST NOT cite a clause of the constitution that the constitution does not contain. Both occurrences MUST be replaced by an argument from text that is actually present, or by the rule's own merits, with no loss of the reason each rule holds.
- **FR-015**: `.specify/memory/constitution.md` MUST NOT change. Two of its clauses are in scope for correction and are knowingly left, so that neither reads as overlooked: Principle III's cut clauses, which FR-014 argues around rather than restores — the cut was deliberate and its reasoning is recorded in the principle itself — and Principle II's copy of the apdex sentence, which FR-012 corrects in `README.md` only.

**Freshness and scope**

- **FR-016**: Any claim this feature adds about Gatling — that `forAll()` takes no path, and that it is reached by no other construct — MUST be checked against the source files the contract already names, and the contract's **Checked** date MUST be updated to the date of that check.
- **FR-017**: `schema/opennfr.io/v1/requirementset.schema.json` MUST NOT change what validates. Every constraint it makes today MUST survive unaltered: every defect here is a defect in what the published text says about the correspondence, not in what the format admits, and narrowing the schema to suit one target is forbidden by Principle VI. Its `$defs/selector` **description** MUST follow the redefinition of `\"*\"` in the same change as `GLOSSARY.md` and `README.md`, because it is one of the three places that value is defined and the schema documents every shape it defines. A description carries no constraint, so no document changes verdict.
- **FR-018**: `bash scripts/verify.sh` MUST exit green, and every document already in `examples/` MUST keep both its validity and its verdict.

### Key Entities

- **The reach contract** (`specs/004-strip-to-schema/contracts/gatling-reach.md`): the source for what Gatling can assert. Tables of **can**/**cannot** rows over five axes, each row a correspondence between an OpenNFR construct and a Gatling one. Every defect in this feature is a row that does not decide, or a sentence that decides wrongly.
- **A selection row**: one row of the Selection table. Today it is keyed by the set of attribute names present. After this feature it is keyed by that set *and* by what the values may be.
- **The gate** (`scripts/verify.sh` § *Examples are assertable by Gatling*): the only implementation of the contract's tables. It reads `examples/` and never the schema.
- **The corpus** (`examples/`): the published documents, and the only place documents are published. It holds documents that validate and are assertable; it cannot hold a counter-example, which is why FR-008 needs probes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every value-bearing row of the Selection table states what its values may be. Today: zero of three do.
- **SC-002**: A document selecting `{loadtest.request.name: "*"}` corresponds to exactly one Gatling scope, and that scope is `forAll()`. Today it corresponds to a literal path part matching a request named `*`, so the run fails for a reason unrelated to the requirement.
- **SC-003**: Every rejection the gate issues on the selection axis quotes a reason a reader can find in the contract. Today one such reason — that a path part is a string — exists only in the gate.
- **SC-004**: Each **cannot** rule added by this feature is demonstrated by a probe that fails when the rule is removed, and the probe count has a floor above zero. Today the reach gate has no probes at all; its only floor is on predicates read from the corpus.
- **SC-005**: Every row of every reach table can be matched by a predicate without interpolating a range. Today one row — percentiles — cannot.
- **SC-006**: Zero citations of the constitution in the contract resolve to text the constitution does not contain. Today: two.
- **SC-007**: Every quantity named in `README.md`'s exclusion of derived quantities is one the stated reason is true of — today two of three — and apdex is findable in the ideas area with a condition attached, where today it appears as a one-word parenthetical inside another entry's list.
- **SC-008**: `bash scripts/verify.sh` is green; the corpus grows from three documents to four; zero existing documents change verdict; `schema/opennfr.io/v1/requirementset.schema.json` is byte-identical to its state at `2f4b15d`.

## Assumptions

- **The milestone's four issues map to three commits, not four.** `AGENTS.md` maps one tracked issue to one semantic commit, and that holds for #64 and #60. #55 and #56 are one change: adding the `forAll()` row is simultaneously what gives `ForAll` a denotation and what stops `"*"` rendering as a literal, and neither issue has a green commit that does not contain the other. One commit closes both, naming both.
- **`forAll()` accepts no path.** Taken from the contract's own list of scopes — `Global`, `ForAll`, `Details(parts)`, where only the third carries parts — and from the form quoted in #56, `forAll().responseTime().percentile(95).lt(3000)`. FR-016 requires this to be re-checked against the named Gatling sources before the row lands rather than carried on this spec's word.
- **The gate keeps reading `examples/` and never the schema.** The probes required by FR-008 are documents the gate is handed, not schema introspection. Extending the reach section to read the schema would narrow the format to one tool.
- **`docs/ideas.md` is the existing authority for derived-versus-composite.** FR-012 aligns `README.md` with a distinction the repository has already drawn rather than introducing one, so Principle I's obligation to argue a new term in an issue first is not engaged.
- **Ordering follows the milestone, not the priorities.** Priorities here rank value: User Story 1 is the `severity:critical` defect. The work order is #64, then #60, then #55 with #56, because each later change writes rows into a table the earlier one repaired.
- **No issue is closed by this spec.** Under `AGENTS.md` an issue closes when the commit that fixes it lands on `main`: #64 with the one commit carrying all three of its parts, #60 with its own, #55 and #56 together with the single commit that answers both.
- **No document currently in `examples/` uses `"*"` on a path attribute.** The three published documents select `{}`, one request name, and a group with a request name, all literal — so FR-003 and FR-004 change no existing verdict, and FR-018 is expected to hold without corpus edits.
