# Feature Specification: What Was Actually Measured

**Feature Branch**: `009-what-was-measured`

**Created**: 2026-08-30

**Status**: Draft — revised 2026-08-30 after adversarial review (see *What the review changed*)

**Input**: User description: "https://github.com/galax-io/opennfr/milestone/8" — milestone **v0.6.0**, five issues: #62, #52, #57, #78, #77. Standing instruction with the request: be rational, add no new construct that is not required, clean up what has come loose, and say at the end what is being built and how.

**Scope note**: Everything the first OpenNFR renderer found ([galax-io/gatling-picatinny#236](https://github.com/galax-io/gatling-picatinny/issues/236)) is split across milestones v0.4.0–v0.8.0. This is the third of them. v0.4.0 (`specs/007-reach-table-rules/`) made the selection axis partition by the pair (key set, value). v0.5.0 (`specs/008-path-denotation/`) settled what a selection row **denotes** — a request's recorded position, its enclosing groups in order then its name. This milestone settles the other half of the same sentence: **what a predicate says was measured**, and what the format does when the honest answer has no name.

Three of the five issues are that question seen from three sides — a span that is not one HTTP request (#62), a scope whose statistic is a different quantity under the same metric name (#52), and a `metric` beside an aggregation that never reads it (#57). Two are the rules v0.5.0 agreed and did not write into the artifact that decides (#78, #77).

**Nothing in this milestone changes what the schema validates, and nothing adds a term.** Two schema *descriptions* gain rules the repository has already agreed; the rest is a gate that stops rendering what the tables reject, and four reach rows that stop deferring. That is a smaller milestone than the first draft of this spec proposed, and § *What the review changed* records why.

## Decisions

### Session 2026-08-30

- **Q**: A business transaction's duration, and every non-HTTP protocol a load generator drives, land in the same assertable statistic and have no admissible metric name (#62). Mint a name, or record the gap? → **A**: **Record it.** No name is minted. #62's own body says so — *"We are not asking for a name to be minted here"* — and #52 pre-authorises the alternative: *"the exclusion becomes a **cannot** row with the reason attached — which would at least be a decision."* Minting would extend a `loadtest.*` debt the repository already records against a namespace nothing emits, on one target's evidence, which the constitution's binding constraints call insufficient grounds.
- **Q**: Then what does the format-side gap actually cover? → **A**: **One case, not two.** Where semantic conventions already name the operation — a database call, a message, a remote call — the general Names rule applies, such a document is valid today, and the format is not missing a name at all; those names are absent from the reach tables because no rendering has been checked and dated and no example uses one, which is the evidence side. What the format genuinely cannot spell is **a duration recorded for a span an author bracketed** — a business transaction across several requests. The published text must say the two halves differently, because saying "no name is true of it" over an upstream convention that exists would be a false statement about an external tool.
- **Q**: `{loadtest.group.name: [G₁, …, Gₙ]}` with no request name is valid, Gatling asserts the corresponding path, and the row is a `cannot` whose reason ends "is open, as #52" (#52). Close it which way? → **A**: **It stays a `cannot`, and stops being open.** The reason is one clause and not two: **no Gatling scope denotes the requests a path encloses.** The scopes are `Global`, `ForAll` and `Details(parts)`, and `Details` on a group's path resolves to the *group*, whose statistics are the group's own — so neither a duration of the enclosed requests nor a count of them is reachable. Separately, the number the group scope does compute is a *cumulated* response time, which no published metric name is true of. The first half is a target limit and is already published, sourced and dated; the second is the format's and is the Metrics axis's business, stated once there.
- **Q**: `{metric: X, aggregation: count}` is schema-valid; the reach tables reject it and the gate renders it while discarding `metric` (#57). Which of the issue's three outcomes? → **A**: **The first — the gate.** The defect is two lines: `TABLE["metric"]` carries `count` and `rate` rows byte-identical to the `requests` rows, so the `metric` key resolves to nothing and is reported nowhere. Deleting them ends the silent drop and makes the gate say `aggregation count over a metric has no equivalent`, in the reach tables' own words. Outcome 2 is barred by Principle III by name — an ignored key is what it forbids. Outcome 3, narrowing the schema, is rejected below.
- **Q**: Why not narrow the schema, which removes the ambiguity at its source? → **A**: **Because the ambiguity is not in the format.** `{metric: X, aggregation: count}` denotes how many observations of `X` the selection carries, which differs from how many requests it carries wherever the metric is not recorded for every request. `README.md` states that at format level, four hundred lines above any target. Narrowing the schema would delete a format-level claim to fit one target's reach, against a binding constraint — *"The published corpus MAY be narrower than the format, and the format MUST NOT be narrowed to match it… The schema keeps what no target reaches"* — and would make this the only reach-`cannot` the schema also rejects, while `sum`, `neq` and `http.route` stay valid with no principle separating them.
- **Q**: `"*"` is not a name — the sentence that stops the anchoring rule swallowing the quantifier — is in `README.md` once and `GLOSSARY.md` twice, and in the schema not at all (#78). Where does it belong? → **A**: **In the schema, and both `GLOSSARY.md` occurrences stay.** #71 moved value meaning onto `$defs/selector`; a consumer following that instruction must find the rule's exception there. The two occurrences in `GLOSSARY.md` do different jobs — one is the anchoring rule's trigger, one is a premise inside the quantifier's derivation — and #78 asks for neither to go. Deduplicating them was proposed in the first draft and is withdrawn.
- **Q**: A `"*"` element of `loadtest.group.name` has two published meanings — a group literally named `*` (schema, `GLOSSARY.md`) and a group at that position with any name (`README.md`) (#77). Which? → **A**: **Presence, as everywhere.** This is the milestone's one genuine judgment call and it is made on cost, not certainty. The presence reading is already published coherently in three places and already implemented by the gate, so it costs one schema sentence, one *Rejected* line and one README cell. The literal reading is a semantics reversal on a compatibility-sensitive attribute, and it does not remove an exception — it relocates one, making `"*"` mean presence in a scalar value and a literal name in a list element, so the token's meaning becomes arity-dependent and one selector can carry both at once.
- **Q**: How is that judgment call kept reversible? → **A**: `GLOSSARY.md` § *selector* records the literal reading as a rejected alternative in its strongest form — *an element of a list is not a value of the attribute* — so a later reversal is a documented flip of one gate test rather than a rediscovery.
- **Q**: Should the reach tables define two kinds of `cannot` — the target's limit and the format's — and mark the rows of the second kind? → **A**: **No.** This was in the first draft and is withdrawn. Every `cannot` row that carries a reason already carries it inline, four of the fifteen do not classify cleanly, and the draft's own contract misfiled `good` as a target limit while the published row says the opposite. A taxonomy that misclassifies a row in the document defining it is worse than no taxonomy. What the milestone owes is a `cannot` **with its reason**, which is what the rows will carry.

### The rule the answers produce

One sentence, and it is not a construct:

> **A metric names what was measured.** Where the format publishes no name that is true of the number a target would compute, the shape is a `cannot` whose row says so, and no name is minted to close it. A name is minted only where something outside this repository already records the quantity under one — semantic conventions where they have it, and otherwise a `loadtest.*` entry that has been submitted and is emitted. One target's feature is never sufficient grounds.

Its durable home is `GLOSSARY.md` § *metric*, as a *Rejected* line, because that is where this repository keeps what a term displaced and what it declined to become. That is the policy milestone v0.8.0 says is set here.

### What the review changed

The design above was read back against the repository by six adversarial reviewers, one per decision, plus three looking for churn and gaps and two building the opposing plans. Their findings were checked by hand before being accepted; the ones that held changed this document. Two decisions were reversed outright.

| Found | Verified how | Where it landed |
|---|---|---|
| Narrowing the schema for #57 deletes a **format-level** claim (`README.md`'s `metric` row lists `count` and `rate` as meaningful) to fit one target's reach — against a binding constraint | read the constitution's Compatibility Constraints verbatim; ran the schema against `{metric, sum}` and `op: neq`, both **valid** today and both `cannot` in the tables | **reversed**: outcome 1 replaces outcome 3. FR-001…FR-007 rewritten; the schema is untouched |
| `{metric, count}` has a referent: how many **observations** of the metric the selection carries, which is not how many requests it carries | `README.md`'s predicate table states it at format level; its own gloss defines the metric-less `rate` as `rate(..._count[…])` in Prometheus | the same reversal; the note the first draft would have deleted survives |
| The gate fix alone closes #57 — the first draft's own research said so and did not draw the conclusion | `research.md` R3: *"such a predicate … falls to `aggregation count over a metric has no equivalent`, which is the reach tables' own verdict"* | FR-001; the four deleted lines are the whole fix |
| The "two kinds of `cannot`" taxonomy misfiles `good` as a target limit; the published row says `successfulRequests` **exists** and no OpenNFR fraction corresponds to it | read `README.md:649` against the first draft's own contract file | **dropped**: the defining paragraph and the row markers go. Every row states its reason and no row states its kind |
| The #52 row's drafted reason is under-inclusive: it governs metric-less predicates too, which `selection_why` rejects on the key set before any metric is looked at | read `scripts/verify.sh` § `selection_why`: `set(sel) not in SELECTIONS` is the first branch | the reason becomes one clause covering every shape the row governs |
| The #62 Metrics row as drafted cannot be matched: the table's left column holds metric **names**, and the row's left cell was a prose class, in a table whose law is *"assertable only if it matches a row exactly"* | read the table | the existing `any other` row gains the reason instead; no row is added |
| Saying "no published name is true of the quantity" is false for the non-HTTP protocol half — semantic conventions name a database call, a message and a remote call, and such a document validates today | ran the published schema against a document carrying such a name: **valid** | the claim is split. The format-side gap narrows to an author-bracketed composite span; the protocol half is stated as an evidence gap, without naming a convention this branch cannot date |
| The `GLOSSARY.md` deduplication's justification was false: `README.md` joins the premise and the consequence in **one** sentence, and its `"*"` cell carries neither *"no hierarchy is claimed"* nor *"at any depth"* | read `README.md:249-258` | **dropped**: both occurrences stay. FR-010 records why |
| The Gatling section has **no probes at all** for the metric, aggregation, operator and unit axes — only selections are probed — so every rule on four of five axes is unexercised | read `scripts/verify.sh`: `SELECTION_PROBES` and `SELECTION_RENDERS` are the only probe lists | **added**: FR-006, the largest gap this milestone found and the thing that makes the #57 fix checkable |
| `$defs/aggregation.description` defines `rate` over a `distribution` and a `ratio` — two terms the schema does not contain — while `GLOSSARY.md` carries the correct wording | `$defs` holds nine definitions and neither is among them | out of scope, recorded: it needs its own issue, per the rule that out-of-scope improvements do not travel in an issue commit |
| The `loadtest.group.name` cell in § `selector` carries a Gatling fact — *"no scope carries a wildcard path part"* — duplicated from the reach row | read both | FR-013: the field description loses it |
| Two new `docs/ideas.md` entries duplicate a condition already published verbatim under § *The `loadtest.*` registry* | read the section, and the isolation gate's entry/`*Would need*` count | FR-019: one clause joins the existing entry; no entry is added |

The mint plan was steelmanned in full and did not survive its own construction: a single name cannot cover both a span's elapsed wall-clock and a group's cumulated response time, so the milestone text's premise — that #62's answer *"also names the quantity a group path measures"* — does not hold. That is recorded in *Out of Scope* as a correction the milestone description itself needs.

## User Scenarios & Testing *(mandatory)*

The reader throughout is an implementer building a renderer from the published text — the role that found every defect in this milestone — and, for two stories, an author whose document has to mean one thing.

### User Story 1 - The gate stops rendering what the tables reject (#57, Priority: P1)

An author writes `{metric: http.client.request.duration, aggregation: count, op: lte, threshold: 20, unit: "{request}"}`. The document is valid, and correctly so: it says *how many observations of that duration the selection carries*. The reach tables refuse it — `count` is not listed under *Over a metric*. And `scripts/verify.sh` renders it to `allRequests.count` and drops the `metric` without a message, byte-identical to the same predicate written without one.

Two documents that differ produce identical assertions, and the field the author wrote did nothing.

After this story the gate refuses the shape in the reach tables' own words, the tables list it explicitly instead of excluding it by omission, and a probe proves the refusal fires. **The schema is not touched**: the shape stays valid, because the format is wider than any target and is not narrowed to match one.

**Why this priority**: it is the only defect in this milestone where the artifact that runs disagrees with the artifact that decides, and where a field silently does nothing. It is also the only one carrying a contestable argument, which is why it lands last as a commit and first as a story — a reviewer who disagrees can revert one commit without touching the other four.

**Independent Test**: put the predicate above through `scripts/verify.sh` in a document under `examples/`, and read every published table that mentions `count` over a metric. The gate must refuse it by name; the tables must refuse it by a row rather than by silence; and the schema must still accept it.

**Acceptance Scenarios**:

1. **Given** the shipped schema, **When** a predicate carries a `metric` and `aggregation: count`, **Then** it **validates** — the format is not narrowed, exactly as `sum`, `neq` and `http.route` are not.
2. **Given** `scripts/verify.sh`, **When** that predicate is reached, **Then** it is refused with `aggregation count over a metric has no equivalent`, and no assertion is produced from it.
3. **Given** `README.md` § *Aggregations* → *Over a metric*, **When** the table is read, **Then** `count` and `rate` appear as **cannot** rows with their reason, so the shape matches a row and is refused rather than being unlisted.
4. **Given** `README.md` § *What a criterion can be about*, **When** the `metric` row is read, **Then** `count` and `rate` are still listed: it is a format-level claim and it remains true.
5. **Given** `GLOSSARY.md` § *aggregation*, **When** the rejected alternatives are read, **Then** the schema-rule outcome is recorded as rejected, with the constraint it would have broken.
6. **Given** the Gatling section, **When** it runs, **Then** a predicate probe fails if the gate ever renders `{metric, count}` again, and the probe floor is what stops the probe being deleted quietly.

---

### User Story 2 - Four of five reach axes stop being unprobed (#57, Priority: P1)

`scripts/verify.sh` says of its own rules: *"a rule nothing probes is a rule nothing checks."* It then probes exactly one axis. `SELECTION_PROBES` and `SELECTION_RENDERS` cover selection; the metric, aggregation, operator and unit partitions have **no probe at all**. The corpus cannot stand in for them: it holds only documents that are assertable, so every rejection rule on those axes is unexercised, and any of them could be deleted green.

That is how `TABLE["metric"]` came to carry `count` and `rate` for five releases without anyone noticing.

After this story the predicate axes have a probe list of their own, with its own floor, in the shape `SELECTION_PROBES` already has.

**Why this priority**: it is the same priority as User Story 1 because it is the same commit and the same defect seen structurally. Fixing the two lines without adding the probe fixes today's instance and leaves the mechanism that produced it.

**Independent Test**: delete the fix from `TABLE["metric"]` and run the gate. It must go red naming the shape. Then delete a probe without lowering the floor; it must go red naming the floor.

**Acceptance Scenarios**:

1. **Given** the Gatling section, **When** it is read, **Then** a predicate probe list exists beside the selection ones, each entry a shape the tables refuse paired with the reason its row gives.
2. **Given** the probe list, **When** `TABLE["metric"]` regains a `count` row, **Then** the section fails and names the shape.
3. **Given** the probe list, **When** a probe is removed, **Then** the floor fails and says a probe that is gone cannot fail.
4. **Given** the corpus, **When** the section runs, **Then** the predicate count it reports is unchanged: the probes exercise rules, not documents.

---

### User Story 3 - The schema decides what the quantified document selects (#78, Priority: P2)

An implementer follows `$defs/requirement`'s instruction — *"What the values mean is on the selector definition this refers to"* — and reads `$defs/selector`. They find the anchoring rule and its trigger: an absent hierarchy means the empty one, *"and it fires only where a request is named"*. They then read `examples/every-request-is-fast.yaml`, whose selector is `{loadtest.request.name: "*"}`, and cannot tell whether that names a request.

Both readings are consistent with what the schema says. Under one, the rule fires and the requirement is quantified over top-level requests only, so every request inside a group is silently outside the bar. Under the other — the intended one, the one the example's own comment states and the one `forAll()` implements — it is quantified over every recorded position at any depth.

The sentence that decides is published in `README.md` and in `GLOSSARY.md`, and is absent from the artifact `README.md` calls the one that decides.

After this story the schema carries the exception beside the rule, and its closing sentence about value types stops being false of the one attribute it names.

**Why this priority**: it is the format's flagship quantified document, undecidable from the artifact that decides. It also has to land before the story after it: a `"*"` element is presence *because* `"*"` is never a name, and stating the consequence before the premise is how the two readings came apart.

**Independent Test**: read `$defs/selector` alone, with no other file open, and answer three questions — does `{loadtest.request.name: "*"}` trigger the anchoring rule, what positions does it range over, and what may the value of `loadtest.group.name` be. All three must be answerable from that description.

**Acceptance Scenarios**:

1. **Given** `$defs/selector`, **When** the anchoring rule is read, **Then** the same description says `"*"` is not a name and therefore does not trigger it.
2. **Given** `$defs/selector`'s closing sentence, **When** it is read against the `properties` entry four sentences above it, **Then** it is true of `loadtest.group.name`, whose only admissible value is an array.
3. **Given** `GLOSSARY.md` § *selector*, **When** its two statements of the carve-out are read, **Then** both are still there: one is the anchoring rule's trigger, the other a premise inside the quantifier's derivation, and removing either leaves a claim unsupported.
4. **Given** the three artifacts that state the rule, **When** they are read side by side, **Then** none contradicts another, and the schema is the one a consumer is told to read for value meaning.

---

### User Story 4 - A `"*"` group element means one thing (#77, Priority: P3)

`{loadtest.group.name: ["*"], loadtest.request.name: POST /checkout}` validates against the published schema with zero errors. The schema and `GLOSSARY.md` say each element is a literal recorded name, which makes it a group actually called `*` and makes the selector render to `details("*" / "POST /checkout")`. `README.md` says, in one table cell, both that each element is a literal recorded name and that `"*"` in an element is presence — a group at that position with any name.

A renderer reading the cell top-to-bottom emits an assertion; reading to the end, it refuses the document. A group literally named `*` is legal in Gatling and unremarkable in a generated scenario, so the three outcomes are not academic.

After this story `"*"` means presence in every position it can occupy, in all three artifacts, and the reading that was withdrawn is recorded with the argument that would revive it.

**Why this priority**: it is the highest-severity ambiguity in the milestone and it is settled by two clauses in three files. It sits after User Story 3 because it is that rule read consistently, not a new one.

**Independent Test**: take the document above, and ask each of the schema, `GLOSSARY.md` and `README.md` what it denotes. All three must give the same answer, and the answer must be the one the gate already enforces.

**Acceptance Scenarios**:

1. **Given** `$defs/selector`, **When** a `"*"` element of `loadtest.group.name` is read, **Then** it is presence — a group at that position with any name — and never a group whose recorded name is `*`.
2. **Given** `GLOSSARY.md` § *selector*, **When** the literal-element sentence is read, **Then** it carries the same exception, and the entry records the literal reading as rejected in its strongest form: an element of a list is not a value of the attribute.
3. **Given** `README.md`'s `loadtest.group.name` cell, **When** it is read from the first sentence to the last, **Then** it states one reading, and it no longer carries a fact about a target — that belongs to the reach row and is already there.
4. **Given** the document above, **When** it is validated, **Then** it still validates, and when it is put through the gate it is still rejected for the reason already published. No probe and no floor moves.
5. **Given** a group whose recorded name is literally `*`, **When** an author tries to select it, **Then** the published text says it is unnameable, which it already says for a request of that name.

---

### User Story 5 - The metric axis says what it does not name (#62, Priority: P4)

A team's most common latency requirement is *"the place-order transaction completes within 3 s at the 95th percentile"* — a business transaction spanning several HTTP requests plus think time. The Metrics table admits exactly `http.client.request.duration` and rejects "any other" with no reason attached. So the two available spellings are a name that renders and is false about what was measured, or a name that is honest and refused without explanation.

The exclusion of the two body-size metrics is recorded with its reason. This class is not recorded at all — the case simply does not appear.

After this story the case appears, with its reason, and the reason distinguishes the half the format genuinely cannot spell from the half where the obstacle is missing evidence rather than a missing name.

**Why this priority**: it changes no schema and no document — it is a decision written down. It sits after the defects that make a valid document render wrongly, because a reader mis-rendering today is worse than a reader with no answer today.

**Independent Test**: ask the published text what a document should say when the thing measured was not one HTTP client request. It must give an answer for each half — a stated position with its reason and the condition under which it changes — and it must not assert anything about an external tool that the repository has not dated.

**Acceptance Scenarios**:

1. **Given** `README.md` § *Names* § *Metrics*, **When** a reader asks what the four names do not cover, **Then** the boundary is stated: a duration recorded for a span an author bracketed, which no convention names.
2. **Given** the same section, **When** a reader asks about an operation on another protocol, **Then** they are told the general Names rule already applies, that such a document is valid, and that these tables list only names whose rendering has been checked and dated — not that no name exists.
3. **Given** the Gatling Metrics table, **When** the `any other` row is read, **Then** it carries its reason, and no row has been added whose left cell names no value a document can carry.
4. **Given** `GLOSSARY.md` § *metric*, **When** the rejected alternatives are read, **Then** the name this milestone declined to mint is recorded, with why.
5. **Given** `docs/`, **When** the parked construct is read, **Then** its condition is stated, in the entry that already carries one for the same namespace rather than in a second entry beside it.
6. **Given** the shipped repository, **When** the format's terms are counted, **Then** no term has been added.

---

### User Story 6 - The group-only selection is decided, not open (#52, Priority: P5)

`selector: {loadtest.group.name: [Checkout]}` with no request name is a valid document, and the deprecated NFR-YAML format this one replaces ships exactly that scope today. The published row refuses it and names a reason — the group scope measures a *cumulated* duration the Metrics table cannot name — and then defers: *"Whether a group-scoped statement should exist at all is open, as #52."*

An open clause in a partitioning table is a shape a consumer cannot plan around. Worse, the reason given is under-inclusive: the row also governs predicates carrying no metric at all, which the gate refuses on the key set before any metric is looked at, and for which a naming gap is not the obstacle.

After this story the row is decided and its reason covers every predicate shape it governs: **no Gatling scope denotes the requests a path encloses.**

**Why this priority**: its verdict does not change, so nothing downstream moves. The value is that a `cannot` a reader can plan against replaces a `cannot` that might be temporary, and that the reason stops being false of half the shapes it governs.

**Independent Test**: read the row and answer whether a renderer should implement the shape. The answer must be no, for a reason that holds for a predicate with a metric and for one without, and that depends on nothing undated.

**Acceptance Scenarios**:

1. **Given** the Selection table's group-only row, **When** it is read, **Then** it carries no open clause and no issue pointer standing in for a decision.
2. **Given** the same row, **When** a predicate carrying no metric is considered, **Then** the reason still holds: no scope denotes the enclosed requests, so neither their durations nor their count is reachable.
3. **Given** the same row, **When** its claims about Gatling are checked, **Then** each is already published in this repository, sourced and dated; none is new.
4. **Given** `scripts/verify.sh`'s comment on the admitted key sets, **When** it is read, **Then** the issue pointer is gone and the sentence that gives the reason stays. No verdict, message, probe or floor changes.

---

### Edge Cases

- **A predicate carrying `bad` and `aggregation: count`.** Unchanged in every artifact. Rule 1 already excludes a `metric` beside `bad`, and the reach tables already list the shape under *Over a fraction*.
- **`aggregation: rate` in a guard with no metric.** The published corpus's only guard. It must validate and render unchanged; the gate's `requests` shape is not touched.
- **`{metric: X, aggregation: count}` written by an author.** Valid, refused by the tables, refused by the gate if it reaches `examples/`, and refused by nothing if it does not. That residual is stated in *Assumptions* rather than hidden: it is the price of not narrowing the format, and it is the same price `sum` and `neq` already carry.
- **`{loadtest.group.name: ["*", "Payment"], loadtest.request.name: X}`.** A `"*"` element that is not the whole hierarchy. Presence at that position, unrenderable, valid — the rule is about a position, not about the list's length.
- **`{loadtest.group.name: ["*"]}` with no request name.** Two refusal reasons at once: a wildcard path part, and a group-only selection. The gate reports the first it reaches; both are published, and neither becomes conditional on the other.
- **A run that records a group and a request under the same full path.** Already published as a precondition on the two `details(...)` rows and unchanged here. It is the same *cumulated versus per-request* ambiguity as #52 seen at render time, and this milestone must not state it a second time.
- **A document using a semantic-convention name for a database or messaging operation.** Valid, absent from the corpus, and absent from the reach tables. The published text must say why in terms of evidence, and must not name a convention this branch cannot date.
- **`http.server.request.duration`.** Already published in § *Names* and already outside the reach tables. It stays refused: Gatling has no server-side statistic, and the vantage-point rule forbids substituting the client-side one.

## Requirements *(mandatory)*

### Functional Requirements

**#57 — the gate stops rendering what the tables reject**

- **FR-001**: `scripts/verify.sh` MUST NOT carry `count` or `rate` under the `metric` shape of its Gatling partition. The existing fall-through then refuses the shape with `aggregation count over a metric has no equivalent`.
- **FR-002**: The schema MUST NOT change. `{metric, count}` and `{metric, rate}` MUST still validate — the format is wider than any target and is not narrowed to match one.
- **FR-003**: `README.md` § *Aggregations* → *Over a metric* MUST gain `count` and `rate` rows marked **cannot**, each with its reason, so the shape is matched by a row and refused rather than excluded by omission.
- **FR-004**: `README.md` § *What a criterion can be about* MUST keep `count` and `rate` in the `metric` row, and § *A predicate* MUST keep the note recording that rule 4 does not cover them. Both are format-level claims and both remain true.
- **FR-005**: `GLOSSARY.md` § *aggregation* MUST record, as a rejected alternative, making `{metric, count}` and `{metric, rate}` invalid in the schema, with the constraint that rejection rests on.
- **FR-006**: The Gatling section MUST gain a predicate probe list with its own floor, in the shape `SELECTION_PROBES` already has: each entry a shape the tables refuse, paired with the reason its row gives. It MUST cover at minimum `{metric, count}`, and a probe that stops being refused MUST fail the section.
- **FR-007**: No document in `examples/` may be added, removed or edited.

**#78 — the schema states the rules it decides**

- **FR-008**: `$defs/selector`'s description MUST state that `"*"` is not a name, positioned so the anchoring rule's trigger is decidable from that description alone.
- **FR-009**: `$defs/selector`'s closing sentence about value types MUST be true of `loadtest.group.name`, whose only admissible value is an array and which the same description names four sentences earlier.
- **FR-010**: Both statements of the carve-out in `GLOSSARY.md` § *selector* MUST survive. Deduplication is explicitly not done: the two do different jobs, and removing the one inside the quantifier's derivation leaves *"reaches every position at any depth"* asserted without its premise.

**#77 — `"*"` means presence wherever it appears**

- **FR-011**: `$defs/selector` MUST state that a `"*"` element of `loadtest.group.name` is presence — a group at that position with any name — and never a group whose recorded name is `*`.
- **FR-012**: `GLOSSARY.md` § *selector* MUST carry the same exception, and MUST record the literal reading as a rejected alternative in its strongest form — an element of a list is not a value of the attribute — so a reversal is a documented flip and not a rediscovery.
- **FR-013**: `README.md`'s `loadtest.group.name` cell MUST state one reading, and MUST lose the clause *"no scope carries a wildcard path part"*: that is a fact about a target, it belongs to the reach row, and it is already there.
- **FR-014**: The document `{loadtest.group.name: ["*"], loadtest.request.name: X}` MUST still validate and MUST still be refused by the gate for the reason already published. No probe, message or floor changes.

**#62 — the metric axis says what it does not name**

- **FR-015**: `README.md` § *Names* § *Metrics* MUST state the boundary the format genuinely cannot spell: a duration recorded for a span an author bracketed across several requests.
- **FR-016**: The same section MUST state the other half differently and truthfully: where semantic conventions name the operation, the general Names rule applies and such a document is valid today. It MUST NOT claim no name exists, and MUST NOT name a specific convention unless that name is checked and dated in the same change.
- **FR-017**: The Gatling Metrics table's existing `any other` row MUST gain its reason. No row may be added whose left cell names no value a document can carry.
- **FR-018**: No name is minted. `GLOSSARY.md` § *metric* MUST record the declined name as a rejected alternative, with the reason, which is where this repository keeps what a term declined to become.
- **FR-019**: `docs/ideas.md`'s existing entry for the `loadtest.*` registry MUST gain one clause naming the composite-span case. No entry may be added: the isolation gate requires the count of entries to equal the count of *Would need* lines, and the condition for this case is already published there.

**#52 — the group-only selection is decided**

- **FR-020**: The Selection table's group-only row MUST carry no open clause and no issue pointer standing in for a decision.
- **FR-021**: The row's reason MUST hold for every predicate shape it governs, including one carrying no metric: no Gatling scope denotes the requests a path encloses.
- **FR-022**: The row MUST reuse only claims already published in this repository with their source and date. It MUST introduce no new claim about an external tool.
- **FR-023**: `scripts/verify.sh`'s comment on the admitted key sets MUST lose its `(#52)` pointer and keep the sentence that gives the reason. It MUST NOT gain a copy of the row: `README.md` is the only place the tables are stated.

**Across the milestone**

- **FR-024**: No term is added, no schema validation behaviour changes, and no example is edited. `GLOSSARY.md` gains three *Rejected* lines and no entry.
- **FR-025**: Every `cannot` row this milestone touches MUST state its reason. No row is classified by kind, and no taxonomy of reasons is defined.
- **FR-026**: `bash scripts/verify.sh` MUST pass at every commit. Each issue is one commit, and #57 MUST be the last so it can be reverted without touching the other four.
- **FR-027**: Every issue MUST be closed by the commit that lands its fix, and every pull request MUST carry milestone **v0.6.0** before merging.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `{metric: X, aggregation: count}` still validates against the published schema — the same verdict as before this milestone, for `sum`, `neq` and `http.route` alike.
- **SC-002**: The same predicate is refused by `scripts/verify.sh` in the reach tables' own words, and a probe fails if that refusal ever stops firing.
- **SC-003**: Three artifacts agree about `count` over a metric: `README.md`'s predicate table says it means something, its Aggregations table says Gatling cannot compute it, and the gate refuses it. No artifact contradicts another.
- **SC-004**: The corpus is byte-identical before and after, and the schema's validation behaviour is unchanged on every probe the gate already carries.
- **SC-005**: The Gatling section's probe lists cover more than one axis, and its floors rise with the probes added.
- **SC-006**: `$defs/selector` answers, from its own description with no other file open, what `{loadtest.request.name: "*"}` selects, what a `"*"` element of `loadtest.group.name` means, and what values each key admits.
- **SC-007**: Every `"*"` position a document can write has one published meaning, and a reader arrives at the same meaning from any of the three artifacts.
- **SC-008**: The Selection and Metrics tables contain no clause deferring a verdict, and no issue number stands in place of a reason.
- **SC-009**: Every `cannot` row this milestone touches states its reason, and no row states a category of reason.
- **SC-010**: `GLOSSARY.md`'s term count is unchanged at fifteen, and three entries gain a *Rejected* line: § *aggregation*, § *selector* and § *metric*.
- **SC-011**: No claim about an external tool is added that is not already dated in this repository.
- **SC-012**: `bash scripts/verify.sh` passes at every commit, all five issues are closed, and every pull request carries milestone v0.6.0.

## Assumptions

- **Gatling remains the only surveyed target.** Every refusal marked as the format's is stated so that a second target's evidence would reopen it rather than contradict it.
- **The residual in #57 is accepted, not solved.** After this milestone an author can still write `{metric, count}` and receive no error anywhere: the schema accepts it, the gate reads only `examples/`, and no renderer exists. That is the price of not narrowing the format, and it is the price `sum` and `neq` already carry. The reach rows and the probe are what stand in for a schema rule, and they are weaker than one.
- **Nobody has checked whether a target computes a per-metric observation count.** Neither side of the #57 argument did. If no surveyed target computes it and the format cannot say what `{metric, count}` denotes independently of the request count, the field has no referent and the schema rule becomes correct. That check — against dated documentation, as Principle IV requires — is the condition that reopens this decision, and it is cheap to act on later because #57 ships as four deleted lines.
- **The evidence in #62 and #52 is taken as reported.** This milestone's decisions do not depend on it: #62's row asserts nothing about Gatling, and #52's reuses only what `README.md` already publishes with its date.
- **`specs/` stays history.** The contracts under `specs/004-strip-to-schema/` and `specs/007-reach-table-rules/` are not edited; `README.md` is the only place a reach rule is stated.

## Out of Scope

- **Minting any metric name.** The condition under which one could be minted is written into `GLOSSARY.md`; meeting it is not this milestone's work.
- **Widening the reach tables' metric axis** to conventions naming database, messaging or remote-call operations. No example uses one and no rendering has been checked and dated.
- **A group denotation for `selector`.** #52 is decided as a `cannot`; giving the format a way to say it is a construct, not a correction.
- **Narrowing the schema for `{metric, count}`.** Recorded as rejected in `GLOSSARY.md` with the condition that would reopen it.
- **`$defs/aggregation.description`'s stale terms.** It defines `rate` over a `distribution` and a `ratio`, neither of which the schema contains, while `GLOSSARY.md` carries the correct wording. A real defect, found here, and out of scope: it needs its own issue and its own commit, because out-of-scope improvements do not travel inside an issue commit.
- **Correcting the milestone description.** It says #62's answer *"also names the quantity a group path measures"* and that #52 *"adds its Selection row"*. Neither is what is delivered, and under Principle IV a published artifact must not read as differently settled than the work. Proposed, not done: editing the milestone is the maintainer's call.
- **#61 and #63** (milestone v0.8.0), **#59 and #58** (milestone v0.7.0).
- **The v0.6.0 release itself.** Cutting `release/0.6.0` and tagging follows `AGENTS.md` once every issue here is closed on `main`.
