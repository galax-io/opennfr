# Phase 0 — Research

**Feature**: [003-assertion-first-format](spec.md) | **Date**: 2026-08-20

Every claim about an external tool below was checked against that tool's own source or
documentation and carries the date, as Principle IV and FR-026 require. Three of these findings
changed the specification rather than confirming it; those are marked **CONTRADICTED THE SPEC** and
the spec has been amended.

---

## R1. Can a target carry an author-chosen name into its own report? — **No**

**CONTRADICTED THE SPEC.**

**Decision**: a precondition is identified in the **rendering**, by the native assertion identity the
target derives its report line from, and flagged there as a precondition. No target is required to
carry a name.

**Rationale**: Gatling's assertion is `Assertion(path, target, condition)` — three fields, no label,
verified at tag `v3.15.1` in `AssertionBuilders.scala` and against the last open-source definition of
the type at `v3.9.5`. Every printed string is `AssertionMessage.message(assertion)`, a function of
the assertion alone; the JUnit XML `testcase` name and the HTML report row use the same derived
string. The only author-controlled fragment, `Details(parts)`, is resolved against paths actually
recorded during the run, so it is an address rather than a label — and it is absent entirely at
global scope, which is exactly where a throughput precondition lands. k6 is no better: its report is
built from metric, selector and expression.

**Alternatives considered**:

| Alternative | Rejected because |
|---|---|
| Carry a name into the report *(the spec's original choice)* | The capability does not exist on either surveyed target. FR-020 forbids admitting a construct nothing can check |
| Smuggle a label into `details("PRECONDITION: …")` | The parts must equal a recorded group or request name, so this would rename the user's own requests and corrupt the recorded vocabulary — and it is unavailable at global scope regardless |
| Drop preconditions | Abandons the under-delivered-load failure mode the project was founded on |

**Spec changes made**: FR-009 restated; SC-012 restated as report-line-to-entry resolution; decision
D1 revised with the finding and the newly discovered rejected alternative; Appendix D added.

**Incidental finding, in the project's favour**: an unresolvable request path in Gatling **fails**
rather than skipping. Principle III is already honoured there without being asked.

---

## R2. Does the per-request scope justify an aggregate-versus-each distinction? — **No, on the format's own rule**

**CONTRADICTED THE SPEC, and the decision was withdrawn.**

**Decision**: the distinction is **not admitted**. Spec D2 is withdrawn; FR-007's slot now carries the
display name instead.

**Rationale**: FR-020's second half says one target being able to assert a construct is necessary and
*"is not by itself sufficient, so a construct MUST NOT enter the format solely to reach one target's
feature."* The distinction was admitted on exactly one target's native scope. Three findings from
this probe point the same way: the scope is hard-wired to *every request observed in the run* rather
than to a selection, so it renders only when the selection is "every request"; the second target has
no equivalent, and its nearest construct quantifies over samples rather than requests; and that one
renderable combination **exits successfully when it matches nothing**. The only place it worked was
the only place it could lie.

And the ambiguity it removed does not exist without it: a selector matching many requests is
unambiguous while there is one reading. The idea returns to the notebook with its argument, per
FORMAT.md's rule about a knob nobody asked for.

**Superseded finding, kept for the record**: the scope is genuinely native and conjunction-folded, so
the construct is *implementable* — it is simply not admissible under this format's own admission
rule.

**Alternatives considered before withdrawal**: admitting the distinction but restricting it to the
one selection that renders — rejected, a construct whose validity depends on the value of another
field is a rule a reader must simulate. Letting it quantify over *samples* so the second target could
carry it — rejected, that is a third statement again, and one word meaning two things on two targets
is the failure the format exists to prevent.

**What the format gives up**: "no endpoint slower than 2 s" as a single statement. It becomes one
requirement per endpoint, which is verbose and silently stops covering an endpoint added later. The
cost is real, it is why the argument will return, and it returns with a second target or not at all.

---

## R3. What can the second target assert, and does the asymmetry fit in data? — **Eleven axes, all expressible**

**CONFIRMED THE SPEC.**

**Decision**: FR-016 and FR-017 are well-founded. The two targets differ on eleven concrete axes —
available statistics, available comparisons, selection axes, threshold value type, abort support and
the gaps — and every one is expressible as data with no bespoke parser.

**Rationale and specific confirmations**:

- **FR-008 is satisfiable on both.** k6 addresses a request inside a group as more tags on the same
  selection, which is the shape FR-008 mandates and the same shape the spec's Appendix A claims for
  Gatling. Hierarchical addressing needs no new term.
- **FR-014 gets two real conversions**: milliseconds against seconds, and a `0..1` rate against a
  `0..100` percent.
- **FR-013 gets a concrete corpus case**: a fractional-millisecond threshold is exact on one target
  (float64) and **unrenderable** on the other (integer). This is the rounding hazard, in one case.
- **Principle V is honoured by both**: one target's left-hand side is a closed eight-token
  enumeration and its selector is a conjunction of literal equalities. A target description can be a
  closed enum with no grammar.
- **No per-request-scope equivalent on the second target.** Combined with R2, this is what withdrew
  the aggregate-versus-each distinction: FR-020 admits a construct one target can assert, and forbids
  admitting it *solely* to reach that target's feature.

---

## R4. What shape is a target description? — **An enumerated capability table**

**Decision**: an explicit table keyed by *(indicator shape, metric, scope, selection)*, each row
carrying the aggregations and comparisons the target supports **and** the gaps that partition the
same axes, plus per-file declarations of what a native assertion is made of, how the target's report
line is derived, how units convert as **exact rationals**, and dated evidence every claim must cite.

Chosen by judged panel over two alternatives (7 / 6 / 5).

**Rationale**: exact-match lookup with a required can-only-reject default makes FR-010's sum rule
structurally guaranteed rather than checked afterwards. Gaps that partition the same axis as the
capabilities turn FR-017's "an undeclared gap is a defect of the description" into a schema
constraint. Units as integer numerator/denominator pairs rather than floats is what lets FR-013
decide exact representability rather than approximate it.

**Alternatives considered**:

| Alternative | Score | Rejected because |
|---|---|---|
| Axes plus declared gaps — the cross product implicit, exceptions explicit | 5 | Small files, but an unanticipated combination falls through as *supported* rather than as a gap. Wrong default under Principle III |
| Ordered first-match rule list with a required catch-all | 6 | Structurally sound, and its required `otherwise` was **grafted in**. Rejected as the base because rule ordering is itself a grammar a reader must simulate |

**Known fatal problem, carried rather than solved**: volume. A description for a target with one
metric family is roughly 330 lines; rows grow as *metrics × path-kinds*. A target with twenty metrics
is thousands of lines nobody hand-authors correctly — and the moment it is generated, the file's
honesty becomes a generator's honesty, which is code, which is what FR-016 pushed out of this
repository. **No answer.** Recorded in the plan's Complexity Tracking, and the reason the first two
descriptions are deliberately narrow.

---

## R5. What shape is a rendering? — **A neutral tuple plus a pinned literal**

**Decision**: one ordered list of entries, one per predicate, in document order. Each entry carries a
structured identity *(requirement, role, id)* and exactly one of `rendered` or `unrenderable`. A
rendered entry restates the criterion in the target's own tokens — the normative part the corpus
checks — and pins the literal native text as **evidence** the corpus does not interpret.
`role: criterion | guard` is where FR-009's repair lives.

Chosen by judged panel over two alternatives (8.5 / 7.5 / 6.5).

**Rationale**: the neutral tuple is what makes the sum rule and the unit conversion mechanically
checkable; the pinned literal is what stops the corpus drifting away from what the tool actually
receives. The judge required the literal to be an opaque string with **no `pattern`** — a pattern is
the first line of a decoder, and Principle V forbids one.

**Alternatives considered**: a neutral tuple alone (7.5) — clean, but nothing pins what the tool
actually gets, so the corpus can be internally consistent and externally wrong. A quoted native
artifact alone (6.5) — pins reality, but nothing is mechanically checkable and the sum rule becomes a
reading exercise.

**Justifying the duplication**: carrying both is not the two-sources failure this project exists to
prevent, because the two halves are not both authorities. The tuple is normative; the literal is
dated evidence. When they disagree, the literal is the finding and the tuple is the bug — which is
exactly the direction a corpus needs.

---

## R6. Restating the sum rule — **predicate to bucket, not predicate to assertion**

**CONTRADICTED THE SPEC.** Both judged panels reached this independently.

**Decision**: FR-033 binds *predicate → exactly one bucket*. One criterion may become more than one
native assertion where a target can only express it as a conjunction, and one native assertion may
expand into many results at run time.

**Rationale**: the original wording invited "one predicate, one assertion", which would forbid both
of those legitimate cases and make the rule unusable on the first real target.

---

## R7. Where does a rejected YAML sketch go when the parking area is markdown-only?

**Decision**: `docs/examples/checkout-perf.report.yaml` is **deleted**, and the argument it carries
moves into a markdown note in `docs/experimental/` with the status, promotion and retirement
conditions and date that Principle VIII requires.

**Rationale**: `LAYOUT.md` § 1 makes the parked area markdown-only, and FR-041 requires a parked
construct to arrive carrying its argument. The argument is what is worth keeping; the YAML is an
illustration of a document kind FR-018 says the format will not define.

**Alternative considered**: amend `LAYOUT.md` to admit YAML into the experimental area — rejected.
The markdown-only rule is what keeps the parked area from accumulating things that look validatable
but are not, and weakening a containment rule to preserve one unvalidated file is a bad trade.

---

## R8. Is *rendering* a fourth term?

**Decision**: no — it names the artifact produced by an act this repository already calls *render*,
in the glossary's layer diagram, in `ARCHITECTURE.md`'s R2 role, and in the spec's Key Entities. Its
glossary entry must say exactly that, so the judgement is recorded rather than assumed.

**Rationale**: SC-011's budget of three concepts is fully committed, and Principle I is
non-negotiable. Naming an existing act's output is not a new concept; pretending otherwise would
either break the budget or hide the decision.

**Alternative considered**: spend the budget differently by folding the aggregate-versus-each
distinction into the existing `Criterion` entry — rejected, because that distinction genuinely *is* a
new concept while a nominalisation is not. Trading the real one away to protect a bookkeeping number
would be the wrong direction.

---

## R9. `mappings/` or a new `targets/`?

**Decision**: `mappings/`, the name `LAYOUT.md` § 1 already reserves.

**Rationale**: no new artifact class is invented and no fourth term is spent. Two edits follow and
must land in the same change: `LAYOUT.md` § 1's row loses "once it exists" and names the new kind,
and § 5's step 1 stops saying `kind: MetricMapping`. The incumbent kind is superseded rather than
kept alongside — FR-021 allows one spelling — and ADR-0002 § D12 receives a dated supersession note
under FR-040 rather than being rewritten.

**The trap that comes with it**, already documented in `LAYOUT.md` § 6 and now load-bearing:
*"`verify.sh`'s sketch-label check is hardcoded to `docs/examples/*.yaml`. A mapping relocated to
`mappings/` silently stops being checked until the script is extended."* That is a fifth silent-green
site waiting to happen, and it is exactly what FR-034 exists to catch.

---

## R10. What must the prerequisite amendments say?

**Decision**: ten amendments across two artifacts, in earlier pull requests, per Principle VII.

**The constitution goes to 2.0.0 — MAJOR.** Its own versioning policy defines MAJOR as "a principle
is removed or redefined in a way that permits what it previously forbade", and three separate
changes meet that test:

| Locator | What is wrong with the current text |
|---|---|
| Principle III | Mandates that a run which did not meet its conditions "MUST be reported as inconclusive … never as a pass or a fail". D1 removes that state; the target has OK/KO per assertion and nothing else. The **spirit is kept** — nothing reports success by omission — and the run-time half moves to the rendering and the corpus |
| § Compatibility Constraints | Binds "The format MUST NOT contain a construct expressible only at conformance level `assert` or above", which FR-020 **inverts**. Separately lists "the conformance levels and what each one guarantees" as a surface requiring an ADR — and `report` is no longer a level at all |
| Principle VI | Forbids consuming "a statistic a target computed for itself" as a verdict. That is now the design. Not violated — nothing in scope produces a verdict — but **vacuous rather than satisfied**, which reads to the next person as a live constraint |
| § Governance, versioning policy | A PATCH limb correction, so that the three above can be version-stamped honestly. Blocks nothing directly; must be in force when 2.0.0 is stamped |

**`ARCHITECTURE.md` — six sections.** It is unversioned and its own § "Status of this document" makes
the amending route an ordinary pull request landing before the specification that diverges from it.
§ 1 (the path, clauses 1–3), § 2 (the four roles and "what no role may do"), § 3 (targets), § 4 (the
walkthroughs, clauses 8–16), § 5 (support is data, clauses 17–18), § 7 (the follow-up table and
dependency graph).

**Note for whoever reviews § 2**: that amendment is where the repair to FR-009 becomes
*architecturally* available — the R2 role's output column is what gives the rendering a definition to
point at. Until it lands, FR-009 and SC-012 have no binding twin.

---

## Open, and deliberately not closed here

- **The volume problem in R4 has no answer.** It is the sharpest cost of the chosen shape.
- **`each` on an empty match is a silent green inside the target.** Declared, not fixed; unfixable
  from this side.
- **The corpus cannot falsify itself.** Spec Appendix C states this; nothing in Phase 0 changes it.
- **A third target is the real test of both shapes.** Two targets fitting a shape drawn around two
  targets is not evidence.
