# Phase 0 — Research: The Constitution Catches Up

**Feature**: `010-constitution-catches-up` | **Date**: 2026-08-30 | **Spec**: [spec.md](spec.md)

Seven questions. One of them changed a functional requirement: the containment rule the spec wrote
into Principle VI is **false of this repository today**, and shipping it would have put a violated
MUST into the document whose entire claim is that it wins — which is #83, recreated by the commit
that fixes #83. R1 is that finding and its resolution. The rest are verification: exact text, exact
line, exact count, so the plan edits a sentence it has read rather than one it remembers.

Everything below was read at `1e394f1` on 2026-08-30. Nothing here is a claim about an external
tool, so nothing here needs a source date beyond that one.

---

## R1 — Is "a fact about a target MUST NOT be stated outside a target's description" true today?

**Question**: spec FR-005 replaces Principle VI's structural containment — a separate file cannot
leak, because it is a separate file — with a rule about where target facts may appear. Before the
amendment carries that rule, is the repository already obeying it?

**Answer**: **No.** Under the rule as the spec first worded it, four sites violate it, and at least
two of them are load-bearing and were kept deliberately.

Every mention of the target outside `README.md` § *What any tool can actually run*, excluding
`specs/` (history) and `.claude/`:

| Site | What it says | Under the rule as first worded |
|---|---|---|
| `README.md:49`, `:56` | gatling-picatinny's `assertionFromYaml` is tool-internal; Gatling Enterprise has a results transport | violation — facts about the target |
| `README.md:478` | *"`loadtest.request.name` — k6's `name` tag, Gatling's request name, JMeter's sampler label — is the honest fallback"* | violation, and under the **unamended** principle too: it is literally a correspondence between the format's vocabulary and three targets' own |
| `README.md:759`, `docs/ideas.md:130` | k6 signals a failed request with a metric, JMeter with a boolean column, Gatling with KO | violation — facts about the target |
| `scripts/verify.sh:566`, `:655` | *"no Gatling scope denotes the requests a path encloses"*; *"Gatling spells that forAll(), which takes no path"* | violation — and v0.6.0's FR-023 **required** the first of these to stay |
| `CONTRIBUTING.md:48`, `AGENTS.md:31`/`:39` | the target is Gatling; the gate checks the tables | not a capability claim; survives any wording |

The two that matter are `README.md:478` and the gate's comments. The first is the argument for the
field existing at all — every load generator records a request name, and three are named as evidence.
Striking the names would remove the evidence for a debt `README.md` deliberately records. The second
is the executable form of the tables; v0.6.0 settled it in terms — *"MUST lose its `(#52)` pointer
and keep the sentence that gives the reason. It MUST NOT gain a copy of the row"* — so a rule that
forbids the gate from naming a reason contradicts a decision this repository took nine days ago.

**Resolution**: the rule is not about *facts*, it is about **descriptions**, and the amendment has to
say what one is. A target's description is what a renderer reads to turn a document into that
target's assertions. With that definition the clause is true today and stays checkable:

- `README.md` § *What any tool can actually run* is a description — a renderer reads the rows. There
  is exactly one, and `specs/004-strip-to-schema/contracts/gatling-reach.md` is a redirect that says
  in its own text that it carries no rule. The one-home property holds.
- `README.md:478` is not a description. A renderer reads nothing from it; it is why the field exists.
- `scripts/verify.sh` is not a description either — it is the one implementation of one, and
  `README.md:559` already says so: *"implements these tables and is the only implementation, and
  nothing else restates them."*
- `README.md:759` and `docs/ideas.md:130` are arguments about constructs the format does not have.

**What changed in the spec**: FR-005 was rewritten. It now requires the amended principle to define
a target description before it constrains one, to require exactly one per target, and to say that a
gate implementing a description is not a second description — it may name the reason a row gives and
may not carry a second copy of the rows. That last clause is v0.6.0's FR-023 promoted from a
one-release decision to the rule it was already following.

**Alternatives considered**: (a) keep the broad wording and clean up the four sites — rejected,
because it deletes the evidence at `README.md:478` and reverses v0.6.0's FR-023, neither of which is
in this milestone and both of which would need their own argument. (b) drop the containment rule
entirely and let Principle VI keep only the one-home clause — rejected, because the structural
guarantee the amendment removes is the whole reason #68's drift was possible, and replacing it with
nothing is what the amendment is being watched for.

---

## R2 — How many statements of the Gatling correspondence exist, and is "exactly one" true?

**Question**: FR-003 requires the amended principle to demand exactly one description per target.
Is that satisfied at `1e394f1`, or does the amendment ship a rule the repository already breaks?

**Answer**: **Satisfied.** One description: `README.md` § *What any tool can actually run* § *Gatling*
(`README.md:551` onwards). `README.md:559` states the singularity itself. The former second copy,
`specs/004-strip-to-schema/contracts/gatling-reach.md`, was reduced to a redirect on 2026-08-25 and
says so in its first line: *"This file is a redirect and carries no rule."* `AGENTS.md:31` records
that this one file under `specs/` is not history for that reason.

The gate is the one implementation and is carved out by R1's definition rather than by exception.

---

## R3 — Which documents still in force cite the wording being amended?

**Question**: an amendment that leaves a citation pointing at deleted text is the defect this
milestone exists to remove, one file over. The constitution's own 3.0.0 report says that had already
happened three times.

**Answer**: **two in force, two history.**

| Site | Cites | Disposition |
|---|---|---|
| `.specify/templates/plan-template.md:62` | *"Does adding a target change the format, the schema, or an existing document?"* | **in force** — follows the amendment (FR-013) |
| `AGENTS.md:35` | the departure, *"against constitution Principle VI"* | **in force** — loses the parenthetical (FR-012) |
| `specs/008-path-denotation/plan.md:233` and its Constitution Check | the unchecked VI box and the Complexity Tracking row | **history** — untouched (FR-014) |
| `specs/003-assertion-first-format/spec.md:117`, `:271` | the old wording, twice | **history** — untouched (FR-014) |

Nothing under `.github/` cites a principle. `scripts/verify.sh:540` cites Principle VI for a claim
the amendment preserves — that narrowing the format to one tool is forbidden — and needs no edit,
because the amended bullet keeps *"MUST NOT change the format, the schema"* verbatim.

---

## R4 — Which version limb, and what number?

**Question**: the document's own policy decides this, and getting it wrong is the kind of error that
is invisible until someone cites a version.

**Answer**: **4.0.0**, MAJOR, and the Sync Impact Report names two limbs.

- Principle VI is *"redefined in a way that permits what it previously forbade"* — MAJOR by name.
- Principle II's composite clause is *"existing guidance is materially expanded"* — MINOR.
- *"Where one amendment carries material at more than one limb, the highest limb governs and the
  document takes one version number."*

No principle is removed, so no number is withdrawn and VII stays the only withdrawn number.
`3.0.0 → 4.0.0`, and **Last Amended** takes the landing date.

---

## R5 — Can the `docs/ideas.md` edit break the isolation gate?

**Question**: Principle VIII's gate counts ideas against conditions, and an edit that changes either
count fails the section.

**Answer**: **No, provided no line-initial bold is added.** `scripts/verify.sh` counts entries with
`re.findall(r"^\*\*(.+?)\*\*", text, re.M)` and conditions with `text.count("*Would need*")`, then
fails when the two differ. The apdex entry begins `**apdex**` at `docs/ideas.md:75` and carries its
`*Would need*` at `:88`. FR-021's edit is inside the sentence at `:81`, adds no line-initial bold and
no second `*Would need*`, so both counts are unchanged at 16 and 16 (counted at `1e394f1`; the
`26` the gate prints on that line is its link count, not its entry count).

`specs/` is exempt from the isolation scan and is *"the ONLY exemption"* per the gate's own comment,
so this feature's own artifacts may name `docs/ideas.md`. They name it in code spans anyway, matching
the habit of every prior spec here.

---

## R6 — What exactly does the format's aggregation set contain?

**Question**: FR-020 requires the enumeration in the apdex entry to match the schema. A fix that
guesses the set repeats the defect it is fixing.

**Answer**: `$defs/aggregation` is a string constrained by `anyOf` of two branches — an enum of
**seven** names, `avg`, `min`, `max`, `count`, `rate`, `sum`, `stddev`, and the percentile pattern
`^p\d{1,2}(\.\d+)?$`.

`docs/ideas.md:81` lists `p*`, `max`, `min`, `avg`, `stddev`, `count`, `rate` — the pattern and six
of the seven. `sum` is the single omission. `README.md:150` and `:309` both list it, and
`README.md:647` carries a `cannot` row for it, so it is not a name the repository has forgotten.

The conclusion the enumeration supports survives `sum`: it sums the values a metric carries, and the
format has no construct that classifies requests into bands and none that gives a band a weight, so
there is nothing for a weighted sum of counts to be taken over.

---

## R7 — Is `AGENTS.md` § *Architecture* the only copy of that sentence?

**Question**: #83 is a duplicated-and-drifted sentence. Before editing one copy, count them.

**Answer**: **No — there is a fourth copy, two revisions stale, and it is out of scope.**
`.copier-answers.yml:6` carries an `architecture:` answer reading *"The schema decides; `README.md`
explains it and is the only document that describes a field."* That is the **pre-v0.5.0** wording: it
never gained *"or states what a target can assert"* and never gained the second-target sentence, so it
never carried the departure #83 is about and does not become false by amending it. Its `structure:`
answer is stale in a second way — it predates the `gatling-reach.md` redirect sentence in
`AGENTS.md:31`.

It is a generator answer file, not a document a reader follows, and correcting it is not one of this
milestone's two issues. Under `AGENTS.md` — *"Work that is not one of the milestone's issues does not
ride along: it gets its own issue"* — it is recorded in the plan's *Out of Scope* and owed an issue.

---

## What Phase 0 changed

| Finding | Verified how | Where it landed |
|---|---|---|
| FR-005's containment rule is false of the repository at four sites, two of them deliberate | enumerated every target mention outside the reach section; read v0.6.0's FR-023 and `README.md:478` in full | **FR-005 rewritten**: the rule is about descriptions, the amendment must define one, and the gate is carved out by the definition rather than by exception |
| `README.md:478` violates the **unamended** Principle VI as well — it is a vocabulary correspondence outside a target's description | read the principle's second bullet against the line | recorded here; not fixed, because the definition R1 adopts resolves it and the alternative deletes a recorded debt's evidence |
| A fourth copy of the architecture sentence exists in `.copier-answers.yml`, two revisions behind | read the file | *Out of Scope*, owed its own issue |
| Two in-force citations of the amended wording, not one | swept every file outside `.git` for the sentence and for principle citations | FR-012 and FR-013 confirmed as the complete set |
