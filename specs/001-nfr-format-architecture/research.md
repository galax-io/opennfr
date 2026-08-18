# Phase 0 Research: Repository Architecture and Operating Principles

**Feature**: [spec.md](spec.md) | **Date**: 2026-08-18 | **Branch**: `001-nfr-format-architecture`

Seven parallel investigations over the repository, then two adversarial verification passes —
one on every citation, one on every claim about an external tool, since Principle IV makes an
unlabelled tool claim a defect. The verifiers were instructed to default to REFUTED when they
could not confirm from a file in this repository. They refuted a great deal, including two
statements in the specification itself.

Every quote below was independently re-checked. Line numbers cited by the first pass were
wrong four times in a row (off by one or by a range end); the numbers here are the verified
ones.

---

## D1. Which candidate principles survive, and what the constitution actually gains

**Decision**: The amendment adds **two** numbered principles, **widens one** existing binding
constraint, and carries a **third principle only in a narrowed form** — or drops it.

| Candidate | Outcome | Grounding, verified |
|---|---|---|
| Targets Are Data | **Not a new principle.** Widen the existing constraint, per FR-011 | `constitution.md` § Compatibility Constraints — "Support for a load testing tool MUST be expressible as data, not as code in the reference implementation." Confirmed verbatim. The words "monitor"/"monitoring" appear nowhere in `docs/`, `README.md`, `AGENTS.md` or the constitution — the gap is real |
| Evaluation Is Target-Blind | **New Principle VI** | `compatibility.md` § Requirements for the Go implementation → Layering — "the evaluation layer knows nothing about tools or sources" |
| Architecture Before Implementation | **New Principle VII** | `AGENTS.md` § Commits & PRs → Spec-first |
| Experiments Are Parked, Not Merged | **Conditional — see D2** | Contested |

**Rationale**: FR-011 forbids adding a parallel principle that nearly duplicates an existing
constraint, and the load-testing-tool constraint is exactly the one being generalised.
Numbering the conditional principle **VIII**, last, means dropping it renumbers nothing.

**Alternatives considered**:

- Adding *Targets Are Data* as a numbered principle — rejected by FR-011: the constitution
  already says it, narrowly.
- Citing `README.md` § "Tool support as data, not code" as primary grounding — rejected: the
  README hedges it as "Unproven", which weakens a principle citation.
- Citing ADR-0002 § D18 for target-blindness — rejected: D18 is about the data source being
  absent from the document, which FR-005 already spends.

**Two honesty caveats the amendment must carry**:

1. `compatibility.md` § Layering sits under `## Requirements for the Go implementation`, which
   that document's own opening classifies as a *proposal*, not a verified fact, and which
   states "nothing is implemented yet". Cite it by its full path and do not let Principle VI's
   wording imply the layering exists.
2. `AGENTS.md` declares everything below its `---` to be "the **stack-agnostic development
   process** … meant to be reused verbatim across all projects". The Spec-first bullet is
   therefore inherited boilerplate, not an argument this repository had. Co-cite
   `constitution.md` Principle I's ordering rule, which is ratified and repository-specific.

**Defect found in the specification itself**: [spec.md](spec.md) quotes the Spec-first bullet
as "`specs/NNN-*/` artifacts → commit BEFORE any `feat`/`fix`", eliding
`docs(speckit): add NNN-<feature> spec/plan/tasks` **without marking the elision**. In a
document whose own FR-008 says "an invented utterance is not a citation", that is
self-inflicted. The `compatibility.md` quote has the same problem: its ellipsis swallows a
sentence boundary. Both must be re-quoted in full.

---

## D2. "Experiments Are Parked" — the drafted principle contradicts its own evidence

**Decision**: Do not ship the principle as drafted. Either narrow it to the half that is
grounded, naming the two existing counter-examples as grandfathered, or drop it and rely on
the spec's FR-018 and SC-011, which already bind this feature's own artifacts.

**Rationale**: three findings, all confirmed.

1. **The offered citation was refuted.** The hunt proposed ADR-0001 § D7 (`workload` reserved,
   unused). The verifier rejected it: D7 records an *abstention* — nothing was built, tried,
   labelled or held anywhere; the ADR says the question "is still open" and the name "is left
   free". The drafted principle governs work that **exists and is nearly right**. Different
   thing.

2. **A closer citation exists that the hunt missed** — and it says the opposite of the draft.
   `constitution.md` Principle III carries the bullet "Any artifact nothing validates MUST say
   so in its own text." That is ratified and repository-specific, and it grounds the
   *self-labelling* half of parking. But the drafted text opens "Unsettled work is contained,
   not labelled. A warning notice on something load-bearing is not containment" — which
   contradicts the only constitutional text that supports it.

3. **The repository has practised the opposite, twice, in published artifacts.**
   - `docs/semconv/loadtest.md` announces itself as "a proposal written in semconv style,
     nothing more … has not been submitted anywhere, and nothing emits these names today" —
     and core constructs depend on it anyway.
   - `docs/examples/mapping-k6.yaml` marks its `errorSignal` block "a draft: the expressiveness
     of conditional rules must stay bounded, or it becomes the very DSL we rejected" — in a
     published example.

   Both are unsettled work admitted with a label instead of held back. A principle forbidding
   that would make two committed artifacts retroactively non-compliant on the day it lands.

**Alternatives considered**:

- Ship as drafted — rejected: it contradicts `constitution.md` Principle III's labelling
  bullet and two committed artifacts.
- Drop entirely — viable, and the spec already anticipates it. Costs nothing mechanically:
  FR-018 and SC-011 still bind this feature's own experimental area.
- **Recommended**: narrow to *new* unsettled work, keep labelling as the mechanism the
  constitution already blesses, and name `docs/semconv/loadtest.md` and the `errorSignal`
  sketch as grandfathered with a dated note. This preserves the author's stated intent
  ("parked, in some form") without a rule the repository itself violates.

**This is the one decision in Phase 0 that the plan cannot take alone** — it changes what the
constitution says. Carried into Complexity Tracking.

---

## D3. Two better-grounded principles that are not among the candidates

**Decision**: Record them, do not add them in this amendment.

- **A generated artifact never enters the source of truth.** Grounded twice — ADR-0001 § D2
  ("the word `assertion` does not appear in the OpenNFR schema") and `docs/GLOSSARY.md`
  § Layer 2 → Assertion, which ranks it: "the single strongest constraint the notes have
  produced so far, and the one most likely to hold". Not in the constitution.
- **One concept, one layer; a word is never reused across layers.** Grounded in
  `docs/GLOSSARY.md` § Layers and ADR-0001 § D2, both naming it as the exact point where the
  surveyed formats break. Principle I requires a glossary entry and a rejected alternative but
  says nothing about layer separation.

**Rationale**: both are stronger candidates than one of the four in the spec, but neither is
*this feature's* subject — this feature is about repository architecture. Principle I treats
every added rule as a permanent cost, and an amendment that quietly grows from three items to
five is the kind of scope drift AGENTS.md's one-concern rule exists to stop.

**Alternatives considered**: adding them now — rejected as scope creep into a PR the
constitution requires to travel alone. They belong in a later amendment with their own
argument.

---

## D4. The three deferred clarifications

### (a) The experimental area is a real directory with two link rules

**Decision**: Create `docs/experimental/` holding exactly one markdown file, `README.md` — the
parked monitoring direction's status page (status, promotion condition, retirement condition,
date, and the follow-up spec that owns it). Add two binding rules to the layout document:

- **No markdown link may point into the experimental area from outside it.** Outside
  references name the path in prose, inside a code span, never as markdown link syntax.
- **The area holds markdown only, no YAML.**

**Rationale**: `scripts/verify.sh` fails the build on any dangling internal markdown link, so a
single inbound link makes SC-007's one-operation deletion turn the gate red. With these two
rules SC-007 becomes literally executable: `git rm -r docs/experimental && bash scripts/verify.sh`
stays green. The no-YAML rule keeps the area clear of the sketch-label check, which is
hardcoded to `docs/examples/*.yaml`.

**Alternatives considered**: prose-only, no directory — rejected: SC-007 and SC-011 become
unfalsifiable, and this feature's only literally runnable criterion is lost. Inbound links
permitted with SC-007 reworded — rejected: AGENTS.md makes `verify.sh` the gate and the
constitution forbids weakening it quietly.

### (b) The `loadtest.*` registry is normative core, at its existing home

**Decision**: File `docs/semconv/` in the normative core. Do not invent a seventh artifact
class. Discharge FR-015 by widening the normative core's definition in the layout document
with one clause: it includes the `loadtest.*` registry, the only core artifact whose
**upstream** status is unratified, which it must state in its own dated text — as it already
does.

**Rationale**: filed in the experimental area, SC-007's removability claim is false on day one,
because deleting it breaks `window.phase` and the `loadtest.request.name` addressing fallback
(ADR-0002 § D14). Principle II already licenses `loadtest.*` names as first-class; Principle IV
requires the unsubmitted status to be stated, not the artifact to be quarantined.

**Alternatives considered**: a seventh artifact class "proposed upstream contribution" —
rejected: one artifact does not justify a class, and Principle I prices the new word. The
experimental area — rejected: makes SC-007 false immediately.

**Consequence**: the constitution's compatibility-surface bullet "any OpenTelemetry name the
format borrows" does not cover names the format *defines*. Widening it is a candidate edit —
but see the open question in D6, since it may push the bump past MINOR.

### (c) "Who may change it" is uniform: anyone, by pull request

**Decision**: FR-014's middle column reads the same in every row — **"Anyone, by pull
request"**. Every difference between classes lives in the third column, "what changing it
obliges", which FR-014 already mandates. Introduce no role vocabulary at all.

**Rationale**: the constitution's own binding constraint says "A tool list that only
maintainers can extend is not tool-agnostic", which rules out a role taxonomy for the mappings
class at least; and Principle I prices every added governance word. Two sentences below the
table carry the whole answer.

**Alternatives considered**: a prose taxonomy (maintainer / contributor) — rejected: two new
governance words for no mechanical effect. CODEOWNERS plus branch protection — rejected:
machinery this repository does not have, for a rule the constitution already fixes.

**Operational catch**: `scripts/check-linkage.sh` gates every PR on a milestone and a
registered closing link, and outside contributors cannot normally set a milestone on a fork
PR. The layout document must say who does that on an outsider's behalf, or the "anyone" is
theatre.

---

## D5. Vocabulary: four defects, one of them in the specification's own trace

**Decision**: settle `target` in the glossary; **drop the noun `binding`**; rename the
component sense of `reader`; drop `interpreter`; and **fix the endpoint of the traced path**.

| Word | Decision |
|---|---|
| `target` | `### Target` in `docs/GLOSSARY.md` § Layer 2. Runtime, between `### Assertion` and `### Adapter`. No fourth layer is created — FR-012 holds literally |
| `binding` | **Drop the noun.** It collides with `MetricMapping`, and worse, `binding` is already load-bearing in this repository as an *adjective* meaning normative. The artifact class becomes **tool mapping**, home `mappings/` |
| `monitoring backend` | Collides with `backend`, already used in the glossary in a different sense (the thing that evaluates after the run). By FR-012's own collision test it belongs in the glossary — which contradicts the 2026-08-18 clarification that sent it to the architecture document. **Resolution: define it inside the `Target` entry**, where the collision is visible, and have the architecture document cite rather than redefine it |
| `reader` | Used in two senses — a human (SC-001, US1, eight more occurrences) and a software component. The human sense is load-bearing for two success criteria. Rename the component to **file adapter** |
| `interpreter` | A straight synonym of the glossary's `Adapter`. Drop outside the quoted user input; `renderer` and `file adapter` are its legitimate sub-roles |
| `source` | Four committed senses already. Always write `data source` in full; never the bare noun |

**The trace ends on the wrong word.** FR-001, SC-001 and User Story 1 all end at **verdict** —
"the verdict a CI job prints". In `docs/GLOSSARY.md` a `Verdict` is "The result of checking
**one** criterion or guard"; what a CI job prints is an `Outcome`, "The aggregated result of
the whole run". Ending at `verdict` stops the trace one component short of `gate`, which US1's
own Acceptance Scenario 1 requires to be named. The three walkthroughs must run
**requirement → criterion → verdict → gate → outcome**, and FR-001/SC-001 need the word fixed.

**Rationale**: Principle I makes one-concept-one-word the product. Each of these is a live
collision in a document that has not been written yet, which is the cheapest possible moment.

**Alternatives considered**: keeping `binding` and disambiguating by context — rejected: three
senses in one repository is exactly what the glossary exists to prevent. Keeping `interpreter`
because the user's request used it — rejected: the request is input, not vocabulary; the
architecture document should say plainly that `interpreter` means the glossary's `Adapter`.

**Process**: Principle I requires naming disagreements to be argued in an issue **before files
change**, and no vocabulary issue exists (`gh issue list` returns #1, #3, #5, all closed, none
about vocabulary).

---

## D6. The constitution amendment, edit by edit

**Decision**: `1.0.0 → 1.1.0`, MINOR, on both limbs of the policy simultaneously — principles
are added, and an existing binding constraint is materially expanded.

**Files in the amendment PR — exactly two**:

1. `.specify/memory/constitution.md`
   - Add `### VI. Evaluation Is Target-Blind` and `### VII. Architecture Before Implementation`
     after Principle V, before `## Compatibility Constraints`.
   - Add conditional `### VIII` last (see D2).
   - Widen the Compatibility Constraints bullet: "Support for a load testing tool" → wording
     that covers any target.
   - Governance → Compliance review: "five principles above" → "seven".
   - Version footer: `1.0.0` → `1.1.0`, `Last Amended` updated.
   - Rewrite the SYNC IMPACT REPORT comment block in place — it is a current-state report, not
     a changelog.
2. `.specify/templates/plan-template.md`
   - Line 44 hard-codes "See `.specify/memory/constitution.md` (v1.0.0)" — a stale version
     pointer of exactly the kind this amendment exists to prevent.
   - Add gate bullets for the new principles, before the Compatibility gate.

**Not touched**: `spec-template.md`, `tasks-template.md`, `checklist-template.md`. The added
principles impose no new mandatory section; both are checked at plan time.

**A real, unresolved tension in committed text**: if the widened bullet or Principle VI uses
the noun `target`, the amendment PR introduces a governance word, and the constitution's
Development Workflow says "A PR that changes a term MUST update `docs/GLOSSARY.md` in the same
PR" — which the amendment procedure's "and nothing else" forbids.

**Resolution**: settle `target` in the glossary in an **earlier** PR, so that by the time the
amendment lands the word is not new. This is why the ordering below is not arbitrary.

**PR ordering** — the amendment must land before the architecture and layout documents,
because the constitution says a conflicting document "is wrong and MUST be fixed", so an
architecture document written against unamended text is born wrong:

1. spec PR — `specs/` artifacts only
2. glossary PR — settles `target`, drops `binding`, renames the component sense of `reader`
3. **constitution amendment PR** — two files, nothing else
4. architecture document — `docs/architecture.md`
5. layout document — `docs/layout.md`

**Open**: whether adding `loadtest.*` to the compatibility-surface bullet (D4b) is MINOR or
PATCH. The policy's MINOR limb covers "existing guidance is materially expanded"; a reviewer
could read the addition as a clarification instead. Decide when drafting.

---

## D7. Are the three walkthroughs actually writable? Partly — and they expose real defects

**Decision**: SC-002 is achievable for k6 and JMeter from committed evidence. **Gatling is the
problem**: `docs/examples/` contains `mapping-k6.yaml` and `mapping-jmeter.yaml` and **no
`mapping-gatling.yaml`**. The Gatling walkthrough must trace from the tool survey alone and
declare every gap, or the feature must produce a Gatling mapping — which is a tool-mapping
artifact, and FR-025 forbids this feature from shipping one.

**Rationale and corrections.** The first research pass made several claims the verifier
overturned; these are the corrected findings:

- **`routeHints` exists and is not JMeter-specific.** It is a field of `kind: MetricMapping`,
  sketched in `docs/examples/mapping-jmeter.yaml`. `http.route` is therefore addressable for
  any tool with a mapping — the earlier "not addressable by any construct the repository has
  sketched" was wrong.
- **k6's native thresholds are properly sourced.** `docs/compatibility.md` states its facts as
  "Verified against documentation as of August 2026" and gives k6 `thresholds` and
  `abortOnFail`, level `abort`. The earlier rejection of that claim misapplied Principle IV.
- **`http.route` appears in three requirements** of `checkout-perf.yaml` (four times), not four.
- **"k6: fully honourable" is false.** The ratio indicator cannot render as a k6 threshold:
  `mapping-k6.yaml` renders selectors as k6 tags, and `error.type` is not a tag — it is derived
  from a different metric via `errorSignal`.
- **"Gatling's inline half is honourable" is false.** `docs/GLOSSARY.md` says "`inline` is an
  adapter capability: k6 and Taurus have it, Gatling and JMeter only partly", and no Gatling
  mapping exists at all.
- **Confirmed impossibilities**: Gatling `onViolation: abort` (survey records Abort: no);
  JMeter both halves (level `report`, "no native assertions rendered").
- **Unlabelled knowledge claim caught**: an assertion about Gatling's `simulation.log` columns
  came from the agent's own knowledge, not this repository. Nothing committed speaks to it.
  Under Principle IV it must be labelled or dropped.

**Four defects in the reference example the walkthroughs will expose.** These are findings
about `docs/examples/checkout-perf.yaml`, not about the architecture, and they belong in the
walkthrough as declared gaps and in issues of their own:

1. **`overall-availability` can produce a silent RED.** A run in which nothing fails yields no
   series carrying `error.type`, hence `noData`, hence `onNoData: fail` — the run fails because
   the system was perfect.
2. **An unmeasurable guard fails the run for the wrong reason.** If a tool cannot measure
   `loadtest.dropped_iterations`, the guard lands on `onNoData: fail` rather than on
   `onGuardViolation: inconclusive`, so a tool limitation reads as a system failure.
3. **`skipped` has no gate key.** It appears in the glossary's status enum and as `skipped: 0`
   in the report sketch, but no `gate` key handles it. Silence is undefined behaviour in a
   project whose Principle III forbids exactly that.
4. **`indicatorRef: checkout-latency` points at a Requirement name**, while ADR-0001 § D10 and
   the glossary describe `Indicator` as a reusable kind of its own.

**Alternatives considered**: dropping Gatling from the three — rejected: it is the internal
consumer's tool, which is why it ranks alongside k6. Writing a Gatling mapping inside this
feature — rejected by FR-025, but it becomes the first thing the `target-gatling` follow-up
spec delivers.

---

## D8. Repository layout

**Decision**: keep the existing tree, add two documents and one directory, move nothing.

| Artifact class | Home | Changing it obliges |
|---|---|---|
| Normative core | `docs/` top level, plus `docs/semconv/` | term change updates `docs/GLOSSARY.md` in the same PR with a rejected alternative; naming disagreements argued in an issue first; compatibility-sensitive change requires an ADR |
| Decision records | `docs/adr/NNNN-slug.md` | a PR contradicting an ADR amends it instead; status stays `proposed` until something validates it |
| Tool mappings | `mappings/` (was "bindings" — see D5) | claimed conformance level evidenced and dated |
| Conformance corpus | `docs/examples/` | every file announces itself as a sketch until a schema validates it |
| Experimental area | `docs/experimental/` | self-labelling; no inbound links; markdown only |
| Reference implementation | declared, not created | — |

**New documents**: `docs/architecture.md` and `docs/layout.md`, flat in `docs/`, matching the
existing naming convention. All three walkthroughs stay **inside** `architecture.md`: SC-001
requires the trace to be followable "using the architecture document alone".

**Rationale**: AGENTS.md forbids opportunistic refactors outside scope, and the two mapping
files are linked from at least five other documents, so moving them would turn `verify.sh` red
across the tree. Publish the layout, name the mismatches under FR-013, schedule the moves
separately.

**Six currently non-conforming entries** to publish as a named list, of which the two sharpest:

- `docs/examples/mapping-k6.yaml` and `mapping-jmeter.yaml` are tool-mapping artifacts sitting
  in the corpus home. **Moving them has a hidden cost**: `verify.sh`'s sketch-label check is
  hardcoded to `for f in docs/examples/*.yaml`, so mappings relocated to `mappings/` silently
  stop being checked until `verify.sh` is extended.
- `docs/compatibility.md` spans three classes by its own admission — conformance levels
  (normative), the tool survey (evidence), and the Go notes (proposal).

**Two `verify.sh` behaviours the plan depends on**, both verified by reading the script:

- The link check greps `--include='*.md'` then filters `grep -v '^\./\.'`, so **anything under
  a dot-prefixed root directory has its outgoing links unchecked** — `.specify/`, `.claude/`,
  `.github/`. The checked set is 12 files today.
- The sketch-label check is hardcoded to `docs/examples/*.yaml`.

**`specs/` is not an artifact class** and must be excluded from the layout table explicitly,
with a sentence saying so — a newcomer scanning the tree will otherwise assume it holds format
artifacts. Flow is one-directional: a follow-up spec produces artifacts into the homes the
layout names; it never becomes one.

---

## D9. The follow-up spec list

**Decision**: eleven entries, named by **slug, never by ordinal**, with the dependency graph
stated explicitly. `specs/NNN-` records the order specs were *created*, not the order they
must be *completed* — the architecture document must say so in one sentence, because
`001-nfr-format-architecture` already sets a numbering a reader will read as a schedule.

Entries span: the normative core schema; the tool-mapping schema; the object model; the file
adapter; evaluation; the renderer; per-target mappings for Gatling, k6 and JMeter; the
conformance corpus; and the parked monitoring experiment.

**No individual deliverable appears in two entries** — verified by enumerating every claimed
file. FR-022's unit is the file, which is what makes the check possible; at artifact-class
granularity it would be unwritable, since the schema, the object model and the corpus all add
to the normative core.

**`docs/README.md`'s stated next step — "A JSON Schema for the requirement and result
documents" — names the core-schema entry exactly and stays true.** It is first in dependency
order.

**The answer to `gatling-picatinny#236`** (FR-024, SC-009), served by the `target-gatling`
entry: picatinny 2.0 removes `assertionFromYaml` without a one-to-one replacement and
documents that assertions are written with Gatling's native DSL; the migration note names
OpenNFR's Gatling target as the intended successor once the renderer lands. That answers the
issue's "replacement decision needed" without blocking 2.0 on work that does not exist.

**The parked entry carries promotion and retirement conditions instead of a schedule
position** (SC-011). Promotion requires one unchanged requirement document assembling a valid
query for **all four** backends, each check dated and sourced. Three of four is not promotion —
it is a narrower scope, and narrowing requires amending the architecture.

**Open**: every directory name used above is a proposal. None exists today.

---

## D10. Operational preconditions

**Decision**: create GitHub issues before the first PR.

`scripts/check-linkage.sh` gates every PR on carrying milestone `v0.1.0` **and** a registered
closing link to an issue in that milestone. Milestone `v0.1.0` is the only open one and is
therefore active under AGENTS.md. It currently reports 0 open and 6 closed items; the three
issues that exist (#1, #3, #5) are all closed and none covers this work.

**Consequence**: no PR in the sequence of D6 can merge until its issue exists. Issue creation
is the first task, not an afterthought.

**Superseded 2026-08-18**: `v0.1.0` was tagged, released and closed after this was written.
`v0.2.0` is the active milestone and is created by T001.

---

## Residual unknowns carried into Phase 1

1. **Whether Principle VIII ships, and in what form** (D2). Changes the constitution's content;
   recorded in Complexity Tracking.
2. **Whether `monitoring backend` is settled in the glossary or the architecture document**
   (D5). FR-012's collision test says glossary; the 2026-08-18 clarification said architecture
   document. The test is mechanical and the clarification predates the discovery of the
   `backend` collision, so the test should win — but it reverses a stated answer.
3. **Whether widening the compatibility-surface bullet to cover `loadtest.*` is MINOR or
   PATCH** (D4b, D6).
4. **How the Gatling walkthrough discharges SC-002 without a Gatling mapping** (D7).
5. **Whether `conformance corpus` survives as a name** — `conformance` already has a closed
   committed meaning (a level a tool reaches) and is a field name in two published examples.
