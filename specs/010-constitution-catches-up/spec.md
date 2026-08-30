# Feature Specification: The Constitution Catches Up

**Feature Branch**: `010-constitution-catches-up`

**Created**: 2026-08-30

**Status**: Draft

**Input**: User description: "https://github.com/galax-io/opennfr/milestone/9" — milestone **v0.7.0**, two open issues: #83 and #75. A third, #84, is closed as *not planned* and is not in scope.

**Scope note**: This milestone touches no format. Nothing in `schema/`, `examples/` or `scripts/` changes, no term is added or renamed, and `GLOSSARY.md` does not move. What changes is `.specify/memory/constitution.md`, and the three files that quote it or that it contradicts: `AGENTS.md`, `.specify/templates/plan-template.md` and `docs/ideas.md`.

Both issues are the same failure seen twice. A correction was argued, agreed and shipped into the documents a reader meets — `README.md` for #75, `AGENTS.md` for #83 — and did not reach the one document that says it wins wherever the two disagree. The repository therefore ships two normative statements about the same thing, with the false one in the higher-authority file, twice. It comes first in the release order because every milestone after it writes another target fact into the document Principle VI forbids changing.

## Decisions

### Session 2026-08-30

- **Q**: The constitution's governance clause offers two routes when another document conflicts with it — fix the other document, or amend the principle. #83 is the conflict. Which route? → **A**: **Amend Principle VI.** #83 says outright that it is not an argument that the one-home decision was wrong: #68 was argued, `README.md` has carried the Gatling section since `6d3a882`, and consolidating the tables is what the repository chose and shipped. Fixing `AGENTS.md` back to a separate target file would undo a decision on the strength of a rule the decision showed to be wrong. The other route is the one the amendment procedure exists for.
- **Q**: What does the amended clause say instead of *"Adding a target MUST NOT change the format, the schema, or any existing document"*? → **A**: It keeps every prohibition still true — not the format, not the schema, not the published corpus — and permits exactly one exception: the document that holds the target descriptions. **One**, not one-or-more. The property #68 bought was not "target facts live in a separate file"; it was "target facts live in exactly one place", and the drift it fixed was two copies of the tables disagreeing. Written that way the rule keeps its bite and stops forbidding what the repository does.
- **Q**: Does the amended clause name `README.md`? → **A**: **No.** #83's own Complexity Tracking row records that if a second target ever arrives, `targets/gatling.md` is where both go. A rule that hardcodes today's filename has to be amended again on a move that changes nothing it governs; a rule that says *the one document that holds the target descriptions* survives it. The constitution names files elsewhere, so this is a departure from its own habit and is made deliberately, for that reason.
- **Q**: The old sentence was a structural containment — a separate file cannot leak into the format's description because it is a different file. One home inside `README.md` loses that. What replaces it? → **A**: **A definition, and a singularity on top of it.** A target's description is *what a renderer reads to turn a document into that target's assertions*; there is exactly one per target, and a gate implementing a description is not a second one. The first draft of this decision was broader — *no fact about a target is stated outside a target's description* — and Phase 0 found it false of the repository at four sites, two of them kept on purpose: `README.md:478` names three tools' request-name spellings as the argument for why `loadtest.request.name` exists at all, and v0.6.0's FR-023 **required** `scripts/verify.sh` to keep the sentence giving a row's reason. See [research.md](./research.md) R1. The narrowed rule is what v0.6.0 was already enforcing: its FR-013 stripped *"no scope carries a wildcard path part"* out of the `loadtest.group.name` field description — a reach claim in a field description — while leaving the survey sentences alone.
- **Q**: Principle II lists apdex among derived quantities *"computed by aggregation from metrics that already exist"*. #64 removed it from `README.md` because that reason is false of apdex. Does the constitution mirror the deletion, or delete and replace with a true reason? → **A**: **Delete and replace.** apdex leaves the derived list, and the clause gains a second limb for the class it actually belongs to: a **composite** quantity reduces to no construct the format has, and does not become a metric either. Mirroring the deletion alone was the alternative and was rejected: it makes the two documents agree by making the higher-authority one silent, and Principle II is the only place the constitution says what may not become a metric name.
- **Q**: Does the new limb restate the apdex argument? → **A**: **No.** It states the rule and the reason true of the class, and names apdex as the case on the record. Why apdex specifically reduces to nothing — that it needs a banded classification carrying a second threshold and an aggregation weighting the bands, and the format has neither — stays in `docs/ideas.md`, which is where this repository argues about constructs it does not have. A rule has one home and its argument has another; copying the argument into the constitution is the mechanism that produced both issues in this milestone.
- **Q**: What was already stopping `loadtest.apdex` before this limb existed? → **A**: `GLOSSARY.md` § *metric* carries the bar v0.6.0 set — *"a name is minted only where something outside this repository already records the quantity under one"* — made binding by the Development Workflow's *"A PR that contradicts a decision recorded in `GLOSSARY.md` MUST amend that entry instead"*; the reach tables' Metrics axis refuses `any other` name; `docs/ideas.md` parks apdex with the two constructs it would need. The new limb is therefore not the only thing holding the line, which is why it can be one sentence rather than a policy.
- **Q**: `docs/ideas.md` argues the apdex case from a closed enumeration — *"no aggregation the format has — `p*`, `max`, `min`, `avg`, `stddev`, `count`, `rate` — takes a weighted sum of counts"* — and the schema's enum carries `sum`. Fix which way? → **A**: **Add `sum` and make the sentence survive it.** The conclusion holds: `sum` sums the values a metric carries, and nothing in the format classifies requests into bands or gives a band a weight, so there is no weighted sum of counts for it to take. The defect is that the argument was checkable and failed its check, in the one document the repository keeps for arguing about constructs the format does not have.
- **Q**: The Compatibility Constraints paragraph says *"The third surface, what a target's description may declare, is removed — nothing in this repository describes a target."* `README.md` § *What any tool can actually run* describes one. Is that in scope? → **A**: **Yes** — it is the same statement made false by the same change, in the file being amended, and leaving it means knowingly shipping a false sentence in the document whose whole claim is that it wins. **Correct the sentence, and do not restore the surface.** Bringing back *"what a target's description may declare"* as compatibility-sensitive would make every edit to a reach row require an argued issue and a *Rejected* entry in `GLOSSARY.md` — and `GLOSSARY.md` is the vocabulary document, where a rejected table row does not belong. v0.6.0 changed four reach rows through ordinary issues, and nothing about that went wrong. The rejected alternative is recorded so a later reversal is a decision rather than a rediscovery.

### What the amendment says

> A target's description is what a renderer reads to turn a document into that target's assertions. It is permitted to exist, and permitted to be a section of an existing document, provided there is exactly one per target — and a gate implementing one is not a second one.

Everything else Principle VI says is unchanged: a requirement document still names no target, adding a target still changes neither the format nor the schema nor the corpus, and the vantage-point and derivation clauses stand as written.

Principle II's correction is one clause and reads alongside it:

> A **derived** quantity is not a metric: an aggregation over metrics that already exist computes it. A **composite** quantity is not a metric either, for the opposite reason: it reduces to no construct the format has.

apdex moves from the first sentence, where the reason is false of it, to the second, where it is true.

### What Phase 0 changed

One requirement. FR-005 first read *a fact about a target MUST NOT be stated outside a target's description*, and [research.md](./research.md) R1 enumerated every target mention in the repository and found the rule false at four sites — two of which are load-bearing and one of which v0.6.0 explicitly required. Shipping it would have put a violated MUST into the document whose whole claim is that it wins, which is #83 recreated by the commit that fixes #83.

The rule is now about **descriptions** rather than facts, and the amendment has to define one before it constrains one. R1 also found that `README.md:478` violates the **unamended** Principle VI — it states a correspondence between the format's vocabulary and three targets' own, outside any target description. The definition resolves it; the alternative was to delete the sentence, which removes the evidence for a debt `README.md` records on purpose.

## User Scenarios & Testing *(mandatory)*

The reader throughout is a contributor deciding what they are allowed to do, and — for the last story — the reviewer holding them to it. Both currently get contradictory answers depending on which file they open.

### User Story 1 - Two normative documents stop contradicting each other (#83, Priority: P1)

A contributor wants to add a second target. `AGENTS.md` § *Architecture* tells them a second target is a second section in `README.md`. `.specify/memory/constitution.md` Principle VI tells them adding a target must not change any existing document — and, in Governance, that where the two disagree the constitution wins and `AGENTS.md` is wrong and must be fixed. The reconciliation exists, in `specs/008-path-denotation/plan.md` § *Complexity Tracking*, under a directory `AGENTS.md` itself says is read as history.

There is no reading of the shipped documents under which the contributor is right.

After this story Principle VI permits what the repository does and forbids what it should: adding a target may change the one document that holds target descriptions, and nothing else. `AGENTS.md` states the rule without declaring a departure, and stops citing a plan for authority it no longer needs.

**Why this priority**: it is the conflict the milestone exists for, and the one every later milestone widens — each release that writes a reach row into `README.md` is another act the unamended principle forbids.

**Independent Test**: read `AGENTS.md` § *Architecture* and Principle VI back to back. Neither states something the other prohibits, and neither needs a third file to be reconciled.

**Acceptance Scenarios**:

1. **Given** the amended Principle VI, **When** a contributor asks whether adding a second target may change an existing document, **Then** the answer is yes for exactly one document and no for every other, and the answer is in the principle rather than in a plan.
2. **Given** `AGENTS.md` § *Architecture*, **When** a reader looks for what makes its rule legitimate, **Then** it is legitimate under the constitution as shipped, and the sentence carries no parenthetical pointing into `specs/`.
3. **Given** the amended principle, **When** a reader asks where a target's reach tables may live, **Then** the text names no path, and a later move to `targets/gatling.md` would satisfy it without another amendment.
4. **Given** a contributor writing a second table of what Gatling can assert into `README.md` § *Every field*, **When** they check Principle VI, **Then** it refuses — there is one description per target — while the survey sentence at `README.md:478` and the gate's own comments stay permitted, because neither is a description a renderer reads.

---

### User Story 2 - Principle II stops giving a false reason (#75, Priority: P2)

Someone with an NFR-YAML document in hand — where `APDEX` is a literal key — reads Principle II to find out whether apdex is reachable. It tells them apdex is a derived quantity *"computed by aggregation from metrics that already exist"*. It is not: apdex needs a banded classification carrying a second threshold and an aggregation that weights the bands, and the format has neither. `README.md` was corrected by #64 a release ago; the constitution was not, and it is the document that wins.

After this story every quantity the derived clause names has an aggregation a reader can point to, and apdex is named one clause down, under the reason that is true of it.

**Why this priority**: second because it misleads rather than blocks — no contributor is currently unable to act on it, they are only told something false on the way. It rides the same amendment and the same version bump, so it costs nothing extra to fix here and would need its own amendment later.

**Independent Test**: name the aggregation that computes each quantity the clause lists. Every one has one, and apdex is not among them.

**Acceptance Scenarios**:

1. **Given** the amended Principle II, **When** a reader asks which aggregation computes each derived quantity it names, **Then** each has exactly one — `rate` for throughput, a `bad` fraction for error rate — and apdex is not among them.
2. **Given** the amended Principle II, **When** a reader asks why apdex is not a metric, **Then** the answer is in the principle, is true of apdex, and is a different reason from the one given for throughput.
3. **Given** the amended Principle II and `README.md` § *Names*, **When** the two are read side by side, **Then** they say the same thing about every name they both mention, and neither asserts what the other denies.
4. **Given** a contributor proposing `loadtest.apdex` as a metric name, **When** they look for what refuses it, **Then** Principle II does, and so do `GLOSSARY.md` § *metric* and the reach tables' Metrics axis, which refused it before this clause existed.

---

### User Story 3 - The parked argument passes its own check (#75 part 2, Priority: P3)

`docs/ideas.md` argues that apdex cannot be written today from a closed enumeration of what the format has: `p*`, `max`, `min`, `avg`, `stddev`, `count`, `rate`. The schema's aggregation enum carries `sum`, `README.md`'s predicate table lists it, and a reach row refuses it by name — so `sum` is not a name the repository has forgotten, it is a name this one sentence omits.

The conclusion is right and the argument is checkable and fails. In the one document the repository keeps for arguing about constructs it does not have, that is the wrong thing to be wrong about.

**Why this priority**: third because nothing downstream depends on it — it is an argument, not a rule. It is fixed here because it is the second half of #75 and because an enumeration that a reader can check against the schema in ten seconds should survive being checked.

**Independent Test**: compare the enumeration against the schema's `$defs/aggregation` enum. The two agree, and the sentence they support is still true.

**Acceptance Scenarios**:

1. **Given** the corrected entry, **When** a reader lists the aggregations the format has against the schema, **Then** the enumeration is complete.
2. **Given** `sum` in the list, **When** a reader asks why it does not take a weighted sum of counts, **Then** the entry answers: it sums the values a metric carries, and nothing in the format classifies requests into bands or weights one.
3. **Given** the edited file, **When** the isolation gate counts ideas against `*Would need*` lines, **Then** the counts are equal, because no entry was added.

---

### User Story 4 - The gate a plan is held to matches the rule it cites (#83, Priority: P4)

`.specify/templates/plan-template.md` asks, at the Principle VI gate: *"Does adding a target change the format, the schema, or an existing document?"* That is the sentence being amended. Left as it is, the next plan is gated on wording that no longer exists in the file the template points at, and a plan that satisfies the constitution fails the template — or, worse, passes it by answering a question nobody can locate.

**Why this priority**: last because it follows mechanically from Story 1 and has no argument of its own. It is in scope because the constitution's own amendment convention reviews the templates, and because a stale gate is how a repaired rule gets re-broken by the next feature that runs the check.

**Independent Test**: read the template's Principle VI question against the amended principle. The two agree on what adding a target may change.

**Acceptance Scenarios**:

1. **Given** the amended constitution, **When** the template's Principle VI gate is read, **Then** its question quotes the current wording and not the withdrawn one.
2. **Given** a plan answering that gate, **When** a reviewer checks the answer against the constitution, **Then** no third document is needed to decide whether it passes.

---

### Edge Cases

- **A reach row is edited.** Does the amended clause make every change to a target description a governed event? It must not: the rule governs *adding a target*, and editing a published row is ordinary work under the existing issue and milestone rules.
- **A format-level statement sits near a target one.** `README.md` § *Names* records a gap the format has — a duration for a span an author bracketed — beside metric names a target can and cannot assert. The rule must not push format-level claims into a target's section. v0.6.0 drew this line deliberately (its FR-015 and FR-016 against FR-017), and the amendment must not blur it.
- **A survey sentence names a tool.** `README.md:478` says `loadtest.request.name` is what k6, Gatling and JMeter each call a request, which is the argument for the field existing. It is not a description — a renderer reads nothing from it — and the rule must leave it standing, or the amendment deletes the evidence for a debt `README.md` deliberately records.
- **The gate restates a reason.** `scripts/verify.sh:566` gives the reason a `cannot` row gives. v0.6.0's FR-023 required exactly that. The rule must permit it and must still forbid a second copy of the rows.
- **The one document becomes two.** If `targets/gatling.md` is ever created while `README.md` keeps a Gatling section, the rule is violated by the state of the repository rather than by a change to it. The text must make that a violation and not a gap.
- **A rule nothing checks.** No script reads `.specify/memory/constitution.md`; this defect stood through two releases for exactly that reason. The amendment adds no gate — the milestone touches no script — so the containment rule ships unenforced, and must not read as though something enforced it.
- **A withdrawn number.** Neither principle is removed, so no number is withdrawn and none is reused.

## Requirements *(mandatory)*

### Functional Requirements

**#83 — the constitution permits the one home it already has**

- **FR-001**: Principle VI's second bullet MUST stop forbidding what the repository does. The sentence *"Adding a target MUST NOT change the format, the schema, or any existing document"* MUST be replaced by wording under which adding a target may change exactly one existing document — the one that holds the target descriptions — and no other.
- **FR-002**: The replacement MUST keep every prohibition still true of the repository: adding a target MUST NOT change the format, MUST NOT change the schema, and MUST NOT change the published corpus in `examples/`.
- **FR-003**: The replacement MUST require that there be exactly **one** such document. That singularity is the property #68 bought — two copies of the tables drifted, and four issues closed a release earlier were live again in one of them — and it is the whole of what the departure traded for.
- **FR-004**: The replacement MUST NOT name a file path. `targets/gatling.md` is where the descriptions go if a second target arrives, recorded in `specs/008-path-denotation/plan.md` § *Complexity Tracking*, and a rule naming today's filename would need amending again on a move it does not govern.
- **FR-005**: Principle VI MUST carry the containment rule that replaces the structural one it loses, and MUST define its subject before constraining it. A target's **description** is what a renderer reads to turn a document into that target's assertions; there MUST be exactly one per target; and a gate implementing a description is **not** a second description — it may name the reason a row gives and MUST NOT carry a second copy of the rows. The rule MUST NOT be written as a prohibition on stating any fact about a target, which is false of this repository at four sites ([research.md](./research.md) R1), and the text MUST make clear that no gate checks it.
- **FR-006**: Principle VI's first bullet MUST stand unchanged, and the amended second bullet MUST NOT be readable as licensing a per-target section in a *requirement* document. A reader MUST be able to tell the two kinds of document apart from the principle's own text.
- **FR-007**: Principle VI MUST record what changed and why the previous wording failed, in the principle itself, in the manner Principle III's 3.0.0 paragraph and Principle VI's own rationale already use. A reader MUST NOT have to open `specs/` to learn that the rule moved.
- **FR-008**: The Sync Impact Report at the head of `.specify/memory/constitution.md` MUST be rewritten for this amendment: which principles are altered, why each current wording fails, the version limb each hits, and the templates reviewed.
- **FR-009**: The Compatibility Constraints rationale sentence *"nothing in this repository describes a target"* MUST stop being false. It MUST record that the third surface was removed when nothing described a target, and that a description now exists.
- **FR-010**: The list of compatibility-sensitive surfaces MUST NOT change. Restoring *"what a target's description may declare"* is the rejected alternative and MUST be recorded as one: it would put an argued issue and a `GLOSSARY.md` *Rejected* entry behind every edit to a reach row, and `GLOSSARY.md` is the vocabulary document — a rejected table row does not belong in it. v0.6.0 edited four reach rows through ordinary issues without incident.
- **FR-011**: The document's version MUST become **4.0.0** and **Last Amended** MUST become the date the amendment lands. Principle VI hits the MAJOR limb — *"redefined in a way that permits what it previously forbade"* — and Principle II's new clause hits MINOR — *"existing guidance is materially expanded"*. The policy's *"the highest limb governs"* settles it at MAJOR, and the Sync Impact Report MUST name both limbs rather than only the one that wins.
- **FR-012**: `AGENTS.md` § *Architecture* MUST lose the parenthetical *"(argued in `specs/008-path-denotation/plan.md` § Complexity Tracking, against constitution Principle VI)"*. The rule the sentence states is unchanged; what ends is its status as a declared departure and its citation of a plan the same file reads as history.
- **FR-013**: `.specify/templates/plan-template.md`'s Principle VI gate MUST ask a question the amended principle answers. Its current second clause — *"Does adding a target change the format, the schema, or an existing document?"* — MUST follow the wording it quotes, and MUST also ask whether there is still exactly one description per target.
- **FR-014**: The same file's version pointer — *"See `.specify/memory/constitution.md` (v3.0.0)"* at `:44` — MUST name the version this milestone ships. A gate citing a superseded version is the defect this milestone is fixing, one file over.
- **FR-015**: The same file's Principle II gate asks whether there are *"derived quantities masquerading as metrics"*. It MUST cover composite ones too, so the gate and the amended principle name the same two classes.
- **FR-016**: No file under `specs/` may change. `specs/008-path-denotation/plan.md` keeps its unchecked Principle VI box and its Complexity Tracking row: that is the record of what was true when it was written, and rewriting it would erase the evidence that the departure was disclosed.

**#75 — Principle II stops carrying the false reason**

- **FR-017**: Principle II's derived-quantities clause MUST name only quantities the stated reason is true of. `apdex` leaves the parenthetical, and that sentence becomes what `README.md` has carried since #64.
- **FR-018**: Principle II MUST gain a second clause for **composite** quantities, with a reason that is true of them: they reduce to no construct the format has, and they do not become metrics either. apdex MUST be named there, so the correction moves it rather than dropping it.
- **FR-019**: The new clause MUST state the rule and not restate the argument. Why apdex reduces to nothing — the banded classification carrying a second threshold, and the aggregation weighting the bands — stays in `docs/ideas.md`. A rule and its argument have different homes, and copying one into the other is the mechanism both issues in this milestone are made of.
- **FR-020**: The clause MUST NOT be written as the only thing refusing `loadtest.apdex`. `GLOSSARY.md` § *metric*, the reach tables' `any other` Metrics row and the parking in `docs/ideas.md` already do, and the text MUST NOT imply that they stopped mattering.
- **FR-021**: `README.md` MUST NOT change. Its sentence is the correct one and is what Principle II's first clause is being brought to. It gains no counterpart to the composite clause: `README.md` § *Names* tells an author what they may write, and a class of quantity the format cannot express is not something an author can write — it is refused by the reach tables and parked under `docs/`, which § *What is not in the format yet* already points at. The two documents agree on every name they both mention, which is what #75 asks for.
- **FR-022**: `docs/ideas.md`'s apdex entry MUST enumerate the aggregations the format has. `sum` MUST join `p*`, `max`, `min`, `avg`, `stddev`, `count` and `rate`, matching the schema's `$defs/aggregation` enum exactly.
- **FR-023**: The sentence MUST stay true with `sum` present: it MUST state why `sum` does not take a weighted sum of counts — it sums the values a metric carries, and no construct in the format classifies requests into bands or gives a band a weight.
- **FR-024**: No entry may be added to `docs/ideas.md`. The isolation gate counts line-initial bold entries against `*Would need*` lines and fails when they differ, and this fix edits prose inside an entry that already has both.

**Across the milestone**

- **FR-025**: No term is added, renamed or redefined, so `GLOSSARY.md` MUST NOT change. `.specify/memory/constitution.md` is not a compatibility-sensitive surface, and none is touched.
- **FR-026**: The word *composite* in FR-018 owes no glossary entry. Principle I requires a term to reach `GLOSSARY.md` before it reaches an example, a schema or an implementation; the constitution is none of the three, and `docs/ideas.md` already uses the word of apdex in the sentence this milestone corrects. It classifies a quantity the format does not carry — it is not a field, a value or a name a document may contain.
- **FR-027**: Nothing in `schema/`, `examples/` or `scripts/` may change. `scripts/verify.sh`'s one citation of Principle VI — that extending the reach gate to read the schema would be the format narrowing to one tool — stays true, because the amended bullet keeps *"MUST NOT change the format, the schema"*.
- **FR-028**: `bash scripts/verify.sh` MUST exit green at every commit, and every document in `examples/` MUST keep both its validity and its verdict.
- **FR-029**: The milestone lands as one pull request carrying milestone **v0.7.0**: the spec commit first, then one commit per issue, with `Closes #83` and `Closes #75`. #83 comes first, as the milestone's own description orders it.
- **FR-030**: The pull request's first paragraph MUST state that it amends the constitution and MUST show what breaks without the amendment. The governance disclosure rule bites on amendments travelling with other work; this one travels with none, and the disclosure is made anyway because an amendment a reviewer finds by reading a diff is smuggled however small the diff is.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reader who opens `AGENTS.md` § *Architecture* and Principle VI finds no statement in either that the other forbids, and needs no third file to reconcile them.
- **SC-002**: No document still in force declares a departure from a principle still in force. The one that did is under `specs/`, is unchanged, and is read as history.
- **SC-003**: Every quantity Principle II's derived clause names has exactly one aggregation that computes it, and a reader can name which. apdex is not among them; it is named in the composite clause, under a reason that is true of it. Principle II and `README.md` § *Names* say the same thing about every name they both mention.
- **SC-004**: The aggregation enumeration in `docs/ideas.md`'s apdex entry equals the schema's `$defs/aggregation` enum — seven names — plus the percentile pattern, and the conclusion it supports holds with the seventh name present.
- **SC-005**: The Principle VI gate in `.specify/templates/plan-template.md` and the principle it gates agree, word for word, on what adding a target may change.
- **SC-006**: The constitution's version is **4.0.0**, and its Sync Impact Report names both altered principles, why each previous wording failed, and the limb each hits — MAJOR for VI, MINOR for II — with the highest governing.
- **SC-007**: `bash scripts/verify.sh` exits green at every commit of the pull request, and the milestone's diff over `schema/`, `examples/`, `scripts/`, `GLOSSARY.md`, `README.md` and `specs/008-path-denotation/` is empty.
- **SC-008**: Four files change and no others: `.specify/memory/constitution.md`, `AGENTS.md`, `.specify/templates/plan-template.md` and `docs/ideas.md` — plus this feature's own directory under `specs/`.
- **SC-009**: Both issues are closed by the commits that land their fixes, and the pull request carries milestone **v0.7.0** before it merges.

## Assumptions

- **The one-home decision stands.** #68 was argued and shipped; #83 states it is not reopening it. The amendment is written to legitimise that decision, not to re-litigate it.
- **`AGENTS.md`'s rule is right and only its footing is wrong.** The sentence *"a second target is a second section there, not a second file"* survives the milestone. What is removed is its parenthetical, because after the amendment the rule needs no plan to stand on.
- **`specs/` is history.** `AGENTS.md` says so and the isolation gate exempts it. No spec artifact is corrected to match the new rule, including the one that declared the departure.
- **No gate is added.** The milestone description says nothing here touches the schema, the gate or the corpus. The containment rule in FR-005 therefore ships as text a reviewer applies, and says so — writing a check for "does this sentence state a fact about a target" is not something a script decides.
- **`GLOSSARY.md` § *metric* is binding.** The mint bar set in v0.6.0 lives there, and the Development Workflow's *"a PR that contradicts a decision recorded in `GLOSSARY.md` MUST amend that entry instead"* is what makes a glossary decision a rule rather than a note. FR-020 rests on this.
- **The constitution may say more than `README.md` without drifting from it.** After this milestone Principle II carries a composite clause `README.md` has no counterpart to. That is not the #75 defect repeated: #75 was a false sentence in the higher-authority document, not an absent one in the lower. The constitution states the naming rules; `README.md` § *Names* tells an author what they may write. FR-021 records the reasoning so the next audit finds a decision rather than a gap.
- **The version limb is MAJOR.** Principle VI is redefined to permit what it forbade; Principle II's new clause is a MINOR expansion. *"The highest limb governs"* settles it, and both are disclosed.
- **Two commits, one per issue**, as `AGENTS.md` requires — the spec commit precedes both and is not folded into either.

## Out of Scope

- **A check on the constitution.** Nothing in `scripts/verify.sh` reads `.specify/memory/constitution.md`, which is why both defects survived two releases. Principle III says an artifact nothing validates must say so in its own text, and the constitution does not. That is a third defect of the same family, it needs its own issue and its own argument about what such a check could decide, and it does not ride here: the milestone touches no script.
- **#84.** Closed as *not planned*. Its subject — success criteria of `v0.5.0` that contradict a functional requirement in the same file — is a spec artifact under `specs/`, which this milestone does not touch by FR-016.
- **The mint bar's home.** Whether v0.6.0's *"a name is minted only where something outside this repository already records the quantity under one"* ought to be a constitutional clause rather than a `GLOSSARY.md` line is a real question and is not this milestone's. The composite clause added by FR-018 states which quantities may not become metrics; it does not restate the bar for minting the ones that may. Those are different rules with different homes, and moving the second is its own argument.
- **A composite clause in `README.md`.** Not added, for the reason FR-021 records. If a later audit finds an author who needed it there, that is an issue about `README.md` § *Names* and not an amendment.
- **Restating the Gatling correspondence anywhere.** The reach tables stay where they are, unedited. This milestone changes the rule that says they may be there; it does not touch a row.
