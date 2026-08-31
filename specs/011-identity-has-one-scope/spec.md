# Feature Specification: Identity Has One Scope

**Feature Branch**: `011-identity-has-one-scope`

**Created**: 2026-08-30

**Status**: Draft

**Input**: User description: "https://github.com/galax-io/opennfr/milestone/10" — milestone **v0.8.0**, three open issues: #58, #72 and #82, in that order.

**Scope note**: One question runs through all three: *what tells two statements in one document apart?* Identity is the answer the format gives — the `name` if set and the `aggregation` otherwise — and the repository currently says incompatible things about what it must be unique within (#58), checks it with a branch nothing reaches (#72), and never says what becomes of it when a predicate is rendered (#82).

Nothing here is about a report, a verdict or anything a consumer displays. A renderer turns a requirement document into a target's assertions, which is what the constitution defines one to be, and this milestone stays inside that.

No term is added and no term is renamed. `examples/` does not change; every published document is already valid under the answer this milestone settles on, and stays valid. Four files change: `README.md`, `GLOSSARY.md`, `schema/opennfr.io/v1/requirementset.schema.json` and `scripts/verify.sh`.

#58 comes first because the other two are written from its answer: a probe has to encode a scope, and a reach row has to describe an identity that means one thing.

## Decisions

### Session 2026-08-30

- **Q**: Identity is scoped to the **requirement** by the schema and to the **section** — `criteria` and `guards` counted apart — by `README.md`, `scripts/verify.sh` and the corpus. Which is right? → **A**: **The section.** `rate` over the requests themselves and `rate` over a `bad` fraction are different quantities that share a word, and `README.md` § *A predicate* already says the predicate's own shape is what distinguishes the three readings of `rate`. Forcing a name on a collision that is purely lexical is the noise `GLOSSARY.md`'s own *Rejected* line was written against. The schema's sentence is the one that was not updated when guards arrived, and it is the one that changes.

- **Q**: The milestone calls this "one scope, in four places". Do the four places each get a corrected copy, or does the rule get one home and the others point at it? → **A**: **One home, and pointers.** `README.md` § *A predicate* is where the scope is stated. The schema's `name` description and `GLOSSARY.md` § *criterionId* stop carrying a second statement of it; `scripts/verify.sh` implements it and does not restate it. Four agreeing copies is the state #58 describes — nothing makes copies converge, and this one drifted the moment guards were added.

- **Q**: What shape does the `name` row take in the reach section — a table row, a third bullet under *Two things Gatling cannot do at all*, or a rewritten partition claim? → **A**: **A new `#### Identity` subsection with a third verdict.** The fact a renderer needs is not "you cannot assert this" — the predicate is perfectly assertable — but "the identity you carry does not reach the report". **can** and **cannot** cannot both say that, so the axis needs a verdict of its own. This is the only option that makes the partition claim true rather than narrowing it.

### What "four places" actually counts

The milestone counts coarsely — schema, `README.md`, gate, corpus. Read at `7cf314a`, the scope is stated or depended on at seven sites, and two documents contradict themselves:

| Site | What it says today |
|---|---|
| `schema/…/requirementset.schema.json:130` | "two predicates **in one requirement** may not then share an aggregation" |
| `README.md:357` | "Needed only when two predicates **of one requirement** would otherwise be indistinguishable" |
| `README.md:360-364` | a worked example whose collision is a **guard against a criterion** — "one of them must be named" |
| `README.md:366-367` | "`criteria` and `guards` are **checked separately**: a guard and a criterion may both be `rate`" |
| `README.md:546` | "That two predicates have distinct identities. The gate checks it; the schema cannot" — silent on scope, and false in the sense #72 is about |
| `GLOSSARY.md:202-204` | "The identity of a predicate **within one requirement** … Two predicates **in the same list** may not share one" |
| `scripts/verify.sh:157-166`, `:341-350` | `for section in ("criteria", "guards")`, `seen` reset per section |
| `examples/the-run-held-up.yaml` | two unnamed `rate` predicates in `whole-run` — valid only under the section reading |

`README.md` states the requirement scope in its prose and its worked example, then exempts the guard/criterion pair from it one paragraph later. `GLOSSARY.md` names the requirement in its scope phrase and the list in its rule. Neither document is wrong about the *answer* so much as it is two documents.

### What review added

Two things this specification listed under *Out of Scope* were brought in after the first three issues had landed, on the maintainer's call. Both were parked for the same reason — no issue in the milestone reached them — and both now have one: **#91** and **#92**, filed against v0.8.0 **before** any file changed, which is what Principle I requires of a naming disagreement.

They belong here rather than in v0.9.0 because each is a defect this milestone's own work created or exposed:

- **#91** — `criterionId` names the identity of a guard as well as a criterion. #58 settled that identity is unique within one **list**, which is precisely what makes a guard a first-class carrier of identity, and #72 shipped a probe whose whole subject is a guard's identity. The release that promoted the guard left the term saying `criterion`.
- **#92** — `GLOSSARY.md` § *name* justifies its character restriction with *"a report line, a CI annotation, a URL fragment"*. FR-006a removed that framing from the schema and #82's row stops at the assertion; § *name* is what is left of it. And #82 makes the reason false for the one target described: the identity is **not carried** into a Gatling assertion, so nothing downstream of a run points at a `name`.

The milestone still changes six files: both issues land inside `GLOSSARY.md`, `scripts/verify.sh` and `scripts/identity.py`, which were already among them.

### What `/speckit-analyze` changed

One requirement, and it was a premise rather than a wording.

**FR-008 was written for a gate that keeps the rule inline.** It required `scripts/verify.sh`'s existing comment — *"criterionId is the name if set, otherwise the aggregation. The schema cannot express that fallback, so uniqueness is checked here"* — to survive unchanged. Once #72 moves the rule into `scripts/identity.py`, that comment becomes two defects at once: a second copy of the derivation the module's own docstring carries, and a false sentence, because uniqueness is no longer checked *here*. Keeping it would reproduce #58 one directory over, in the commit whose whole purpose is to stop that. The reason now travels with the implementation, and the call site names what it calls.

The cross-artifact check also found the instruction that would have done the damage: the contract and T012 said to replace `scripts/verify.sh:156-166`, and the comment occupies **155–156**. Following it literally would have deleted half a sentence and left the other half standing. Both now say **157–166**.

### What Phase 0 changed

Three requirements, all in the direction of claiming less.

**FR-026 named a version nobody read.** It required the Identity row be checked at Gatling **3.15.1**, the version § *Gatling* is sourced to. 3.15.1 is not on this machine and nothing in this repository fetches it. What is here is `gatling-shared-model` 0.0.6 and 0.0.11 — the releases Gatling 3.11.5 and 3.13.5 pin — and [research.md](./research.md) R1 read both: `Assertion` carries `path`, `target` and `condition`, no field is a label, and `Assertion.class` is **byte-identical** across the two. The row now says 3.13.5, which is what was read. Dating a claim at a version nobody opened is the Principle IV defect the row exists to fix, one line further down the same page.

**FR-034 undercounted the files, by two.** The two identity checks live in two separate `python3` heredocs — separate processes — so one implementation reachable from both has to be a module on disk. That pattern already exists here: `scripts/mdlinks.py`, whose own comment gives this milestone's reason for it, that the two sections sharing it *"cannot drift into disagreeing about the same text"*. `scripts/identity.py` joins it, and `AGENTS.md` § *Structure* — which names what the gate shares — names it too, in one clause.

**SC-008 asked for less than the row now owes.** A reader must be able to see that the row's version is not the section header's, because it is not, and a target description that quietly mixes two source versions is the thing § *Gatling* dates its sources to prevent.

## User Scenarios & Testing *(mandatory)*

The reader throughout is the author of the first OpenNFR renderer — someone turning a requirement document into a target's assertions, which is all a renderer does. The four stories are the four things that reader currently cannot learn from the repository: what identity is unique within, where that is decided, whether anything enforces it, and what becomes of the key when the predicate is rendered.

### User Story 1 - Identity is unique within one thing (#58, Priority: P1)

A renderer author needs to know when a document holds two statements it cannot tell apart, because that is the one thing about identity that constrains what they may be handed. The schema tells them the unit is the requirement — and under that reading `examples/the-run-held-up.yaml`, the document the repository holds up to explain guards, is malformed. `README.md`, the gate and the corpus tell them the unit is the list, under which it is correct. Both readings are sourced, and the two sources are the schema, which decides, and `README.md`, which explains.

After this story the answer is one answer: an identity is unique within one list, and `criteria` and `guards` are two lists. The flagship example is correct under the only reading there is, and the worked example in `README.md` teaches a collision the rule actually forbids.

**Why this priority**: the other two issues are written from its answer. A probe has to encode a scope (#72) and a reach row has to describe an identity that means one thing (#82). It is also the only one of the three that a consumer can get wrong today without noticing.

**Independent Test**: read the schema's `name` description, `README.md` § *A predicate* and `GLOSSARY.md` § *criterionId* in any order, then apply each reading to `examples/`. No two of the three disagree about which documents are well-formed, and every published document is well-formed under all of them.

**Acceptance Scenarios**:

1. **Given** the corrected documents, **When** a renderer author asks what an identity must be unique within, **Then** the answer is one list, `criteria` and `guards` counted apart, and no document in the repository says otherwise.
2. **Given** `examples/the-run-held-up.yaml` unchanged, **When** it is checked against the schema's `name` description, **Then** it is valid — the reading under which it was malformed no longer exists.
3. **Given** `README.md` § *A predicate*, **When** a reader reaches the worked example, **Then** its collision is one the rule stated below it forbids, and the exemption sentence does not contradict the example it follows.
4. **Given** a document with two unnamed `rate` criteria in one requirement, **When** the gate reads it, **Then** it fails, and the message names the requirement and the list.
5. **Given** a document with an unnamed `rate` guard and an unnamed `rate` criterion in one requirement, **When** the gate reads it, **Then** it passes, and that is what the flagship example relies on.

---

### User Story 2 - The scope is stated once (#58 part 2, Priority: P2)

The same author now wants to know where the rule lives, because they will have to re-read it when the format moves. They find it in the schema, in `README.md` twice, in `GLOSSARY.md` and in the gate — five statements of one rule, which is how it came to be two rules. Nothing in the repository makes those copies converge, and guards arriving is all it took to split them.

After this story `README.md` § *A predicate* is where the scope is written. The schema's description says what identity *is* and points at where its uniqueness is decided and what checks it; `GLOSSARY.md` defines the term and does the same; the gate implements the rule and restates nothing.

**Why this priority**: second because it is the durable half of #58 — correcting five copies fixes today's contradiction and leaves the mechanism that produced it in place. It ships in the same commit as Story 1 because a corrected copy and a deleted copy are the same edit to the same sentence.

**Independent Test**: delete `README.md` § *A predicate*'s `name` paragraph and no other document still states what an identity is unique within. Nothing else in the repository is a second copy of that sentence.

**Acceptance Scenarios**:

1. **Given** the four documents, **When** a reader searches for a statement of what identity is unique within, **Then** exactly one is normative and the others name it rather than repeating it.
2. **Given** the schema's `name` description, **When** an editor surfaces it to an author writing a predicate, **Then** it says what identity is and what happens without a `name`, and defers the scope to the document that states it — as `$defs/unit`'s description already defers its enumeration.
3. **Given** `GLOSSARY.md` § *criterionId*, **When** a reader looks up the term, **Then** it defines the identity, records the requirement scope as the alternative that was rejected and why, and states no scope of its own.
4. **Given** a future change to the scope, **When** a contributor makes it, **Then** one sentence and one gate change, and no document is left behind.

---

### User Story 3 - The check that is claimed is a check that runs (#72, Priority: P3)

`README.md` § *What the schema does not check* tells the reader the gate checks that two predicates have distinct identities. Both branches that do so can be replaced with `if False:` and the gate still prints **PASS**. All ten predicates in `examples/*.yaml` carry `name = None`, the schema's one root example likewise, so no colliding pair exists anywhere and the `name` arm of the fallback has never been observed at all — only the aggregation arm has, and only where it did not collide.

`scripts/verify.sh` states its own standard, *"a rule nothing probes is a rule nothing checks"*, and this rule fails it. Its two neighbours failed it too and were fixed in v0.6.0; this one was left.

After this story the rule gets what they got: probes that fire, in both directions, and a floor that stops them being deleted quietly.

**Why this priority**: third because it enforces the answer Stories 1 and 2 settle — a probe encodes a scope, so it cannot be written first. It is not last because a claim in `README.md` that nothing backs is the failure mode Principle III exists for, and it is currently being made.

**Independent Test**: replace either uniqueness branch with `if False:` and run the gate. It fails, and it names which rule stopped holding.

**Acceptance Scenarios**:

1. **Given** the identity check over `examples/`, **When** it is neutered, **Then** the gate fails.
2. **Given** the identity check over the schema's root examples, **When** it is neutered, **Then** the gate fails — separately, and for its own reason.
3. **Given** a probe of two predicates in one list sharing an aggregation and carrying no `name`, **When** the gate runs, **Then** the collision is reported.
4. **Given** a probe of two predicates in one list whose `name`s collide while their aggregations differ, **When** the gate runs, **Then** the collision is reported — the `name` arm of the fallback is exercised for the first time.
5. **Given** a probe of two predicates in one list whose aggregations collide while their `name`s differ, **When** the gate runs, **Then** nothing is reported, so a check hardened into "always duplicate" cannot pass the section.
6. **Given** the section scope, **When** the per-section reset is removed, **Then** something fails — the guard-and-criterion exemption is exercised, not merely assumed.
7. **Given** a contributor deleting a probe, **When** the gate runs, **Then** the floor beside them fails with a count.

---

### User Story 4 - A renderer is told what happens to the identity (#82, Priority: P4)

The reach tables claim to partition every axis and to admit a predicate only on an exact row match. A predicate has nine keys. `name` has no row anywhere, so a renderer meeting one has no instruction at all — while Gatling's `Assertion` is `(path, target, condition)` and has no field that holds a label. The predicate renders; the key does not travel with it, and two requirements that select the same requests and state the same criterion render to equal `Assertion` values.

`displayName` needs no such row because it is declared inert: a target that drops it loses nothing the format claims. `name` is not inert — it is what makes two statements in one list distinguishable, and the format restricts its character set precisely so that something can point at it.

After this story the section carries an Identity axis, the row says what a renderer must know, and the partition claim is true for all nine keys.

**Why this priority**: last because it changes no rule and blocks no author — it records a fact about a target. It is in the milestone because a renderer meeting a `name` has no instruction at all, and because a claim to partition every axis that is false for two of nine keys is the honesty defect Principle IV names, in the section that is a target's description.

**Independent Test**: list the nine predicate keys against the reach section. Every one is addressed by a row, and each row's verdict says either whether the predicate is assertable or what becomes of the key.

**Acceptance Scenarios**:

1. **Given** the reach section, **When** a reader enumerates the nine predicate keys, **Then** each is covered by a row, and none is covered only by silence.
2. **Given** the Identity row, **When** a renderer author reads it, **Then** it says the predicate is assertable and the key is not carried into what it renders to, and it does not read as a rejection.
3. **Given** the Identity row, **When** a reader asks why, **Then** the reason names `Assertion`'s three fields and the absence of a fourth, and carries the Gatling version it was read at and the date it was checked.
4. **Given** the `displayName` row, **When** a reader asks why its loss costs nothing, **Then** the reason is the one already stated: the key is inert.
5. **Given** § *How these tables are applied*, **When** a reader asks whether the Identity axis rejects anything, **Then** the text says it does not, and says the gate therefore implements no rejection from it.
6. **Given** a predicate carrying a `name`, **When** the gate judges it against the reach tables, **Then** it is rendered and not rejected, and a probe says so.

---

### Edge Cases

- **A guard and a criterion collide inside one requirement.** The exemption is the whole of #58's answer and is what `examples/the-run-held-up.yaml` relies on. It must be stated where the rule is stated, and it must be exercised by something — today only a published example stands behind it.
- **Two guards collide.** Guards are a list like criteria, and nothing exempts a list from itself. The rule reaches guards on their own terms, and the corpus has no case: `the-run-held-up.yaml` carries exactly one guard.
- **A predicate carries a `name` that equals another's `aggregation`.** `name: rate` beside an unnamed `rate` in one list is a collision, because the identity is one value and both predicates produce it. This falls out of the definition and needs no extra rule, but the probe set should not accidentally assume the two arms are separate namespaces.
- **A `name` on a predicate nothing collides with.** Permitted and unaffected. `name` stays optional, and no document is obliged to carry one; the reach row says what happens to it when it is there.
- **The corpus after the fix.** No published document gains or loses a `name`. The `name` arm of the fallback is exercised by probes only, and that is a deliberate limit: the corpus is what a target can run, not a place to install coverage.
- **The schema's root example.** It is one document and carries no colliding identity, so the second check site has nothing in the corpus to prove it fires. It needs a probe of its own, or the two sites need to share what a probe can reach.
- **The Identity axis and the gate.** It decides nothing about assertability, so it adds no rejection. The published-row standard still applies — a row nothing probes is a row nothing checks — and the only thing there is to probe is that the axis rejects nothing.
- **`displayName` and the third verdict.** It is inert and is dropped, which is not the same fact as `name` being dropped. Both belong on the axis; only one of them costs a renderer anything.
- **The subsection count.** § *Two things Gatling cannot do at all* keeps its name. Identity is not a third thing Gatling cannot do — the assertion runs — which is exactly why it is an axis and not a bullet there.
- **A term that does not fit.** `criterionId` names the identity of a guard as well as a criterion. That read badly, and it *became* this milestone's argument: #91, filed after the first three issues landed and precisely because #58 and #72 made the guard first-class.

## Requirements *(mandatory)*

### Functional Requirements

**#58 — one scope, and one place that states it**

- **FR-001**: The identity of a predicate MUST be unique within one list. `criteria` and `guards` are two lists, and a guard and a criterion in one requirement MAY share an identity. This is the reading `README.md`, `scripts/verify.sh` and `examples/` already hold, and it is the reading every artifact touched here is brought to.
- **FR-002**: `README.md` § *A predicate* MUST be the one place the scope is stated. The paragraph MUST say what identity is, what a missing `name` falls back to, what the identity must be unique within, and that `criteria` and `guards` are counted apart.
- **FR-003**: `README.md:357`'s *"two predicates of one requirement"* MUST stop naming the requirement as the scope, and `README.md:360-364`'s worked example MUST show a collision the rule forbids. Its present collision is a guard against a criterion, which the sentence three lines below it permits — the example teaches the rule the milestone is removing.
- **FR-004**: The replacement worked example MUST be renderable by Gatling under § *What any tool can actually run*. It is prose rather than a published document and the reach tables do not gate it, but an illustration of a legal shape that no target can run teaches a second wrong thing while correcting the first.
- **FR-005**: `README.md` § *A predicate* MUST name `examples/the-run-held-up.yaml` as the case the exemption exists for. The exemption is the one part of the rule a reader is most likely to think is an oversight, and the corpus is where it is already load-bearing.
- **FR-006**: The schema's `$defs/predicate.name` description MUST stop stating the scope. It MUST keep saying that the key is optional and that the aggregation is the identifier without it, and it MUST defer the uniqueness rule to `README.md` and name `scripts/verify.sh` as what checks it, in the manner `$defs/unit`'s description already defers its enumeration to `README.md`.
- **FR-006a**: The same description MUST stop saying that the key identifies the predicate *"in a report"*. What `name` does is distinguish a predicate from the ones beside it in the document; a report is downstream of the assertions a renderer produces, and this format describes neither. The phrase is the sentence #58 is already rewriting, so it goes in the same edit rather than being left as the last downstream claim in the schema.
- **FR-007**: `GLOSSARY.md` § *criterionId* MUST define the term and MUST NOT carry a second statement of the scope. The entry MUST record the requirement scope as a rejected alternative and why it was rejected — a name forced onto a collision that is purely lexical, where the predicate's own shape already distinguishes the two quantities — alongside the rejection it already carries.
- **FR-008**: `scripts/verify.sh` MUST keep implementing the rule and MUST NOT restate it. The reason the rule exists — that identity falls back to the aggregation, and that JSON Schema cannot express the fallback — travels **with** the implementation into `scripts/identity.py`. The call site names what it calls and does not repeat the derivation, because a comment restating what the module says is the second copy this milestone exists to remove, and the existing one ends *"uniqueness is checked here"*, which the extraction makes false.
- **FR-009**: `examples/` MUST NOT change. Every published document is valid under FR-001 today and is valid after it. `the-run-held-up.yaml` in particular keeps both unnamed `rate` predicates.
- **FR-010**: `README.md:546` — *"That two predicates have distinct identities. The gate checks it; the schema cannot"* — MUST NOT be edited by this issue. It states which artifact checks the rule, not what the rule is, and it becomes true rather than merely stated once #72 lands.
- **FR-011**: No term is **added**, and no `GLOSSARY.md` entry is created. The entry edited by FR-007 changes what `criterionId` is scoped to, which is why it MUST land in the same commit as the schema and `README.md` edits. One term is **renamed**, under #91 and in its own commit — see FR-038.

**#72 — the branch fires, and stays fired**

- **FR-012**: The identity check over `examples/` MUST be exercised by a probe that fails the gate when the check is removed. Replacing `scripts/verify.sh:162`'s branch with `if False:` MUST make the gate exit non-zero.
- **FR-013**: The identity check over the schema's root examples MUST be exercised the same way and separately. Replacing `scripts/verify.sh:346`'s branch with `if False:` MUST make the gate exit non-zero, and MUST NOT be caught only because the other site's probe caught something.
- **FR-014**: A colliding-identity probe MUST exist: two predicates in one list, sharing an aggregation, neither carrying a `name`. It MUST be reported as a duplicate.
- **FR-015**: A `name`-arm probe MUST exist: two predicates in one list whose `name`s collide while their aggregations differ. It MUST be reported as a duplicate. This arm of the fallback has never been observed by anything in the repository.
- **FR-016**: A non-colliding probe MUST exist in the other direction: two predicates in one list whose aggregations collide while their `name`s differ, reported as no duplicate. Without it a check hardened to report every pair passes every rejection probe, which is the hole `SELECTION_RENDERS` and `PREDICATE_RENDERS` were added to close on their own axes.
- **FR-017**: The guard-and-criterion exemption MUST be exercised by something that fails when the per-section reset is removed. If the corpus already provides that — `the-run-held-up.yaml` fails a requirement-scoped check — the plan MUST say so and MUST say why a probe is or is not additionally required, rather than leaving the coverage implicit.
- **FR-018**: A floor MUST sit beside the identity probes, in the manner of `FLOORS`, failing with a count and the existing sentence *"a rule nothing probes is a rule nothing checks"* when a probe is deleted. The floor MUST be exact, and the plan MUST state what each probe is the sole catcher of, as the four existing floors do.
- **FR-019**: Probes MUST exercise the same code the corpus is judged by, never a copy of it. Where that requires the two check sites to share a function, the extraction is part of this issue; a second implementation written for the probes to call is not acceptable and would recreate #58 one file over.
- **FR-020**: The gate's summary line MUST report the identity probes it ran, as the Gatling section reports its four probe counts. A section that ran nothing must not read like a section that passed.
- **FR-021**: `examples/` MUST NOT change to provide coverage. The corpus is restricted to what a real target can run and is not a probe table; the `name` arm is exercised by probes.

**#82 — the identity axis gets a row**

- **FR-022**: `README.md` § *What any tool can actually run* → § *Gatling* MUST gain a `#### Identity` subsection, placed with the other axes: after § *Units* and before § *Two things Gatling cannot do at all*.
- **FR-023**: The subsection MUST carry a row for `name` — and for the `aggregation` fallback, since an unnamed predicate still has an identity — stating that the predicate is assertable and that the key is not carried into the assertion it renders to. It MUST NOT state anything about a target's report, a verdict, or what a consumer does with a failure: a target description says what a renderer reads to produce assertions, and stops there.
- **FR-024**: That row's verdict MUST NOT be **can** or **cannot**. Neither says what a renderer needs: the assertion runs, and the key does not survive it. A third verdict MUST be introduced for the axis, and § *How these tables are applied* MUST say what it means.
- **FR-025**: The row's reason MUST name the evidence and no more of it than the claim needs: `io.gatling.commons.stats.assertion.Assertion` is `(path, target, condition)`, no field of it holds a label, and two requirements selecting the same requests with the same criterion therefore render to equal `Assertion` values. What Gatling then does with an assertion is outside what this format describes and MUST NOT enter the row.
- **FR-026**: The reason MUST carry the Gatling version it was read at and the date it was checked, as Principle IV requires and as the section header already does for its four sources. It MUST name **3.13.5**, which is what was read, and MUST NOT claim 3.15.1, which was not. It MUST also record that `Assertion` is unchanged between the `gatling-shared-model` releases Gatling 3.11.5 and 3.13.5 pin, because a shape that held across two minors is the only evidence available here about a third. This claim cannot be checked inside this repository, which makes the version and the date the whole of what a later reader has to go on.
- **FR-027**: The subsection MUST carry a row for `displayName` stating that it is inert and that a target dropping it loses nothing the format claims. It is the second of the two keys the partition claim was false for, and its reason is not `name`'s reason.
- **FR-028**: § *How these tables are applied* MUST stop being false. *"The tables partition each axis"* MUST hold for all nine predicate keys, and the text MUST say that the Identity axis decides nothing about assertability, rejects nothing, and therefore adds no rule for the gate to implement.
- **FR-029**: `scripts/verify.sh` MUST gain a rendering probe carrying a `name`, confirming the Identity axis rejects nothing. No corpus document carries a `name` and no existing probe does, so a rejection added on that key today would be caught by nothing — which is the standard § *Examples are assertable by Gatling* already holds every published row to.
- **FR-030**: The floor beside `PREDICATE_RENDERS` MUST be raised by one with FR-029's probe. Adding a probe means raising the number beside it; that cost is stated in the file and is not waived here.
- **FR-031**: The gate MUST gain no rejection from this issue. `predicate_why` decides assertability, the Identity axis decides none of it, and a gate that started refusing a `name` would narrow the format to what a target happens to carry.
- **FR-032**: `GLOSSARY.md` MUST NOT change for this issue. The row records what a target does with an existing term; it introduces none.

**#91 — the term covers what it names**

- **FR-038**: `criterionId` MUST be renamed to `predicateId`. The value it names is the identity of a *predicate*, and `criteria` and `guards` hold the same shape — which #58 made load-bearing by scoping uniqueness to the list, and #72 exercised with a probe whose subject is a guard's identity.
- **FR-039**: The rename MUST update `GLOSSARY.md` in the same change, and the entry MUST record what the old term got wrong, as Principle I requires of every rename. The existing *Rejected* lines MUST survive: they protect decisions the rename does not reopen.
- **FR-040**: Every site MUST move together — `GLOSSARY.md` § *criterionId*, both failure messages and the one comment in `scripts/verify.sh`, and the docstring in `scripts/identity.py`. After the commit no artifact outside `specs/` may still **use** `criterionId` as the term. The exception is `GLOSSARY.md`'s own *Rejected* line, which names it as the spelling that was replaced — Principle I requires the entry to record what the old term got wrong, so that occurrence is the rename working rather than a site it missed. `README.md` does not use the term and MUST NOT gain it.
- **FR-041**: No compatibility-sensitive surface moves. `criterionId` is a derived value with a name, never a field: it appears in no published example, in no schema property and in no OpenTelemetry name.

**#92 — the restriction is justified by something the format has**

- **FR-042**: `GLOSSARY.md` § *name* MUST stop justifying its character restriction with consumers this format does not describe. *"a report line, a CI annotation, a URL fragment"* names three things, two of which are downstream of the assertions a renderer produces, and the third of which #82 shows is unreachable for the one target described — the identity is **not carried** into a Gatling assertion.
- **FR-043**: The replacement reason MUST rest on what the repository has. Both of these are available and true: an identity is compared for **equality** by the gate, so a closed character set is what makes two identities that look alike to a reader be alike to the check; and `$defs/name` is shared by `metadata.name`, a requirement's `name` and a predicate's `name`, so one spelling rule serves three places. The `*Rejected*` line — *"free-form strings — nothing could point at one reliably"* — rests on the same absent consumer and MUST be replaced on the same grounds, keeping the alternative it rejects.

**Across the milestone**

- **FR-033**: `bash scripts/verify.sh` MUST exit green at every commit, and every document in `examples/` MUST keep both its validity and its Gatling verdict.
- **FR-034**: Six files change and no others, beside this feature's own directory under `specs/`. #91 and #92 add no file to the list — both land inside files already on it: `README.md`, `GLOSSARY.md`, `schema/opennfr.io/v1/requirementset.schema.json`, `scripts/verify.sh`, a new `scripts/identity.py`, and one clause of `AGENTS.md` § *Structure*, which names what the gate shares and would otherwise name only half of it.
- **FR-035**: The milestone lands as one pull request carrying milestone **v0.8.0**: the spec commit first, then one commit per issue in the order #58, #72, #82, #91, #92, with a `Closes` line for each. #91 follows #82 because its argument rests on both — #58 made the guard first-class and #72 probed it; #92 follows #91 because both edit `GLOSSARY.md` and the second reads better against the renamed entry.
- **FR-036**: No compatibility-sensitive surface changes. No OpenTelemetry name the format borrows is touched, and no field name appearing in a published example is added, removed or renamed — `name` is an existing optional key whose description changes and whose published usage does not.
- **FR-037**: No constitutional amendment is required or made. `.specify/memory/constitution.md` stays at 4.0.0.

### Key Entities

- **Identity (`criterionId`)**: what tells one predicate from the others in its list — its `name` if set, its `aggregation` otherwise. Unique within one list after FR-001. Defined in `GLOSSARY.md`, scoped in `README.md` § *A predicate*, checked by `scripts/verify.sh`, and — per #82 — not carried into the assertion a predicate renders to.
- **A list**: `criteria` or `guards` on one requirement. The unit identity is unique within, and the reason the flagship example is legal.
- **A reach row**: one line of a target's description, matched exactly, carrying a verdict and a reason. Gains a third verdict for an axis that decides nothing about assertability.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Exactly one sentence in the repository states what a predicate identity must be unique within. Deleting it leaves no other document making the claim, and every other mention names it rather than repeating it.
- **SC-002**: The schema, `README.md`, `GLOSSARY.md`, `scripts/verify.sh` and `examples/` admit exactly one reading of identity scope, and it is the list. No document contradicts another, and neither `README.md` nor `GLOSSARY.md` contradicts itself.
- **SC-003**: `examples/` is byte-identical before and after the milestone, and `the-run-held-up.yaml` is valid under the schema's own `name` description for the first time.
- **SC-004**: Replacing either identity branch in `scripts/verify.sh` with `if False:` makes the gate exit non-zero, and each does so for its own reason. Both are currently replaceable with the gate still printing **PASS**.
- **SC-005**: The `name` arm of the identity fallback is exercised by at least one probe that fails when it stops working. Nothing exercises it today.
- **SC-006**: Deleting any identity probe fails the gate on a count, and the failure names the probe class that shrank.
- **SC-007**: All nine predicate keys are addressed by a reach row, and § *How these tables are applied* claims a partition that holds. Two keys are unaddressed today.
- **SC-008**: A renderer author reading the Identity subsection can say what a target does with an identity without opening Gatling's source, and can say which Gatling version and which date that answer was checked at — and can tell that it is not the version the section header names.
- **SC-009**: A rejection added to `predicate_why` on the `name` key fails the gate. Nothing catches it today.
- **SC-010**: `bash scripts/verify.sh` exits green at every commit of the pull request, and the probe counts in its summary lines are higher than at `7cf314a` for every table that gained one.
- **SC-011**: All five issues are closed by the commits that land their fixes, and the pull request carries milestone **v0.8.0** before it merges.
- **SC-012**: `criterionId` survives outside `specs/` in exactly one place — the *Rejected* line of `GLOSSARY.md` § *predicateId*, where Principle I requires it. Nowhere else, and in particular not in the gate's failure message on a colliding guard, which now names a term that is true of a guard.
- **SC-013**: Every reason `GLOSSARY.md` § *name* gives for restricting the character set is checkable inside this repository. None of them names a report, a CI annotation or anything downstream of the assertions a renderer produces.

## Assumptions

- **The section reading wins on its merits, not by count.** Three sources against one is how the milestone describes it, but `README.md` and `GLOSSARY.md` each carry both readings, so the count is closer than it looks. The argument that decides it is that `rate` over requests and `rate` over a fraction are different quantities sharing a word — `README.md` § *A predicate* says the shape distinguishes them — and forcing a name on that collision is the noise `GLOSSARY.md`'s existing *Rejected* line refuses.
- **The two lists are already two statements about different things.** A violated guard says the run did not happen; a violated criterion says the system did not hold. Two predicates that share a word across that line are not an ambiguous document, and requiring a name there buys nothing the shape has not already bought.
- **Identity is a property of the document.** It is what makes two statements in one list distinguishable, and the rule is well-formedness, checkable by the gate without reference to anything downstream. Nothing in this milestone rests on what a consumer builds out of a failure.
- **`criterionId` does not keep its name.** It read badly of a guard, and #91 renames it to `predicateId`. Principle I requires the argument to be in an issue before files change, and it is: #91 was filed against v0.8.0 first. This assumption held until review moved the rename into scope — see § *What review added*.
- **Nothing about `name`'s syntax changes.** The pattern, the length bound and the optionality are untouched.
- **The Gatling claim is verified before the row is written, at the version that could be read.** `Assertion`'s field list is the one claim in this milestone that cannot be checked from this repository — there is no Scala here and no build. It was read during planning from the `gatling-shared-model` jars already on the machine, and the row carries that version and that date. § *Gatling*'s header stays at 3.15.1 and the row says 3.13.5, and the text says why rather than letting a reader assume one number covers both.
- **The third verdict is a cost, and a smaller one than the alternatives.** A new word in a target's description is a permanent cost under Principle I's reasoning. It is paid because the two existing verdicts answer a question this axis does not ask, and because the alternatives — a bullet under *Two things Gatling cannot do at all*, or narrowing the partition claim — either misfile a fact the assertion does not fail on, or fix the claim by making it promise less.
- **The gate stays the only implementation of the tables.** `scripts/verify.sh` implements the reach section and never restates it, which is what Principle VI requires of a gate. FR-029's probe checks a row without copying one.
- **Three commits, one per issue**, as `AGENTS.md` requires, with the spec commit preceding all three and folded into none.

## Out of Scope

- ~~**Renaming `criterionId`.**~~ **Moved into scope** as **#91** — see § *What review added*. The issue was filed before any file changed, which is what Principle I asks of a naming disagreement.
- ~~**`GLOSSARY.md` § *name*.**~~ **Moved into scope** as **#92** — see § *What review added*.
- **Requiring `name` on every predicate.** Already rejected in `GLOSSARY.md`, and this milestone reaffirms the rejection rather than reopening it.
- **A second target.** The Identity row is a fact about Gatling. Whether another target carries an identity is that target's description's problem, and there is no second description.
- **Anything downstream of the assertion.** How a target reports, what a consumer displays, how a failure might be traced back to the document that stated it — none of it is described here, and the Identity row must not drift into describing it. A renderer turns a requirement into assertions; that is the whole surface. Compensating for what a target does afterwards is the thing § *Two things Gatling cannot do at all* explicitly declines to do.
- **A check on the reach section's dates.** Principle IV requires a claim about an external tool to carry the date it was checked; nothing verifies that the dates are current, here or for the four sources already in the section. That is a defect of the same family as #72 one document over, and it needs its own issue and its own argument about what such a check could decide.
- **`README.md:546`'s wording.** It stays as it is. #72 makes it true; nothing about it is wrong to begin with.
- **Anything under `docs/`.** No construct is proposed or parked by this milestone.
