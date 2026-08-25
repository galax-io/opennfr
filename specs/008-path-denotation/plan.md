# Implementation Plan: The Denotation Of A Path

**Branch**: `008-path-denotation` | **Date**: 2026-08-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-path-denotation/spec.md`

## Summary

Milestone v0.5.0 — six issues, four of them one gap seen from four sides. A selection row states a
key set and a value; the target resolves it against a request's full recorded position, its
enclosing groups in order and then its name. So `{loadtest.request.name: X}` renders to a request
with **no** enclosing group and nothing said so (#54), a position deeper than one group cannot be
written at all (#53), the quantifier is defined over attribute values while `forAll()` enumerates
recorded positions (#70), and the schema half of the previous release's redefinition landed on an
annotation beside a `$ref` instead of on the node that defines a selector (#71). A fifth issue is
the whole contract existing twice, with only one copy fixed (#68), and a sixth is a guard that is
quantified along with its requirement and vacuous in exactly the case it exists to catch (#69).

Phase 0 of the *specification* already changed the shape of the work twice, and both changes are
carried here rather than rediscovered. The first: an early rule making an absent
`loadtest.group.name` *unconstrained* was rejected — an absent group key means an **empty**
hierarchy, which is what makes `{loadtest.request.name: X}` renderable and leaves three of four
published documents untouched. The second: reading the design back against the repository showed
that deleting the contract dangles six markdown links and turns the gate red, that the schema
rejects an array today for every attribute, and that it cannot reject a *scalar*
`loadtest.group.name` without naming that attribute. All three are in the spec and priced here.

What this plan adds on top of the spec is the order the six commits go in, the exact edit set for
each surface, and one piece of evidence the spec deliberately left open: FR-021, the resolution
order between Gatling's request and group branches. See [research.md](./research.md) R1 — the rows
may not claim exactness until it is answered from source and dated.

## Technical Context

**Language/Version**: None — this repository ships no code. One JSON Schema (draft 2020-12),
markdown, and a POSIX shell gate that embeds Python 3 for the checks a shell cannot do.

**Primary Dependencies**: `python3` with `pyyaml` and `jsonschema`, used by `scripts/verify.sh`
only. No dependency is added by this feature.

**Storage**: N/A

**Testing**: `bash scripts/verify.sh` is the whole test model. This feature extends the probe table
in its § *Examples are assertable by Gatling* so that each rule the new rows carry is demonstrated
rather than trusted, and rewrites `selection_why()`, whose key-set list can no longer carry the
whole rule once the group key holds a variable-length array.

**Target Platform**: N/A — documents.

**Project Type**: Format specification plus its validation gate.

**Constraints**: the schema keeps every constraint it has apart from the one FR-008 adds; the
constitution is not amended, and the one place this feature departs from it is declared in
*Complexity Tracking* rather than argued away; the reach gate keeps reading `examples/` and never
the schema; no file under `specs/` is touched except the one that becomes a redirect.

**Scale/Scope**: `README.md` (the reach section absorbs the contract, plus the `selector` section
and two lists), `GLOSSARY.md` (one entry), the schema (two description nodes and one new
constraint), `scripts/verify.sh` (one section), `examples/fast-and-reliable.yaml` (one value),
`examples/every-request-is-fast.yaml` (one comment), and
`specs/004-strip-to-schema/contracts/gatling-reach.md` (reduced to a redirect). Six commits, six
PRs, one per issue.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Vocabulary Before Features** — **engaged, twice.** No term is added. Two are redefined:
      `loadtest.group.name` gains an arity, and `"*"` has its quantifier restated over recorded
      request positions rather than attribute values. `GLOSSARY.md` § *selector* changes in the
      same commits, records what each previous wording got wrong, and records the rejected
      alternatives — a separate `loadtest.group.path` key, a scalar-or-array union, and an
      empty-array spelling of "no groups", each a second spelling of something already sayable
      (spec FR-012, FR-027). Both arguments predate the files: #53 and #70 make them.
- [x] **II. Borrow Names, Never Invent Them** — no metric or attribute name is added, renamed or
      aliased. `loadtest.group.name` keeps its name and its meaning; only the shape of its value
      changes. This principle is what **kills** the obvious alternative: `loadtest.group.path`
      beside `loadtest.group.name` would be two spellings for a depth-one hierarchy, which the
      alias clause forbids. That reasoning is recorded in `GLOSSARY.md` rather than left in a
      review comment.
- [x] **III. No Silent Green** — every rule the new rows carry gets a probe that fails if the rule
      is deleted (spec FR-035), extending the table that already exists for the same reason. The
      probe table keeps its floor, so an emptied table fails the section instead of reporting
      success over nothing. Nothing skips. The one deletion this feature makes — the contract's
      body — does not remove a check: the gate section that implements the tables stays and points
      at `README.md` instead.
- [x] **IV. Honest Status** — **opened as failing, closed by Phase 0.** FR-021 required the
      request/group collision to be read from source before any row claimed exactness.
      [research.md](./research.md) R1 read it at `gatling/gatling` `v3.15.1` and `v3.13.5` on
      2026-08-25 and the answer is not the one the question assumed: there is no resolution order
      to record, because both key kinds live in one `mutable.HashMap` and `collectFirst` takes
      whichever the hash reaches first. The rows therefore carry a dated **precondition** rather
      than a denotation, and SC-003 says so. One supporting claim — that the outcome flips when
      unrelated requests are added — is a **replication** rather than a reading, and is labelled
      as one wherever it appears, which is this principle's "verified separated from speculation"
      clause doing its job rather than being waived.
- [x] **V. Structure Over Grammar** — an ordered list is structure. No string is parsed: the
      alternative that *would* have needed a grammar is `loadtest.group.name: "Checkout / Payment"`,
      split on a separator, which is both the deprecated mechanism this format replaces and the
      thing this principle exists to forbid — and it is recorded as rejected. The value set stays
      closed: an array of at least one string, checked by the schema without a bespoke parser and
      decodable into `map[string]any` without a custom unmarshaler.
- [ ] **VI. The Requirement Is Target-Blind** — **departed from, declared.** No requirement
      document names a target; the corpus is untouched in that respect. But making `README.md` the
      sole home of the Gatling correspondence means adding a second target would change an existing
      document, which this principle forbids in terms. See *Complexity Tracking*.
- [x] **VII** — *withdrawn in 3.0.0. No gate.*
- [x] **VIII. Ideas Are Parked, Not Merged** — `docs/` is not linked into and does not change.
      Checked directly rather than assumed: `docs/ideas.md:170` is the only mention, and it says
      `loadtest.request.name` and `loadtest.group.name` "are **not** ideas any more" — a claim
      about the **names**, which an arity change does not touch. `AGENTS.md:31` names
      `docs/ideas.md` in a code span and not as a link, so the isolation scan stays clean and
      `git rm -r docs && bash scripts/verify.sh` stays green.
- [x] **Compatibility** — **engaged.** `loadtest.group.name` appears in a published example, so its
      value shape is a compatibility-sensitive surface: the change is argued in #53 before the
      files move, and `GLOSSARY.md` records what was rejected. On the binding constraint — a
      construct may not enter unless at least one surveyed target asserts it **exactly** — Gatling
      does: `AssertionPathParts(parts: List[String])` with no arity cap, at every layer. And it is
      not entering solely to reach one target's feature: nested groups are ordinary in load
      simulations, and the NFR-YAML format this one replaces takes them at any depth. The corpus
      does not narrow, and the format does not narrow with it.

## Project Structure

### Documentation (this feature)

```text
specs/008-path-denotation/
├── plan.md              # This file
├── research.md          # Phase 0 — R1 the resolution order, R2 the gate, R3 README, R4 wording, R5 order
├── data-model.md        # Phase 1 — the selector's value shapes and what each denotes
├── quickstart.md        # Phase 1 — how to check each success criterion, runnably
├── contracts/
│   └── reach-selection.md   # Phase 1 — the delta to the Selection table, not a copy of it
└── tasks.md             # Phase 2 (/speckit-tasks — NOT created here)
```

### Files this feature changes (repository root)

```text
README.md                                     the reach contract's new and only home; the selector
                                              section; "what the schema does not check"; the
                                              "names are not enumerated" claim gains its qualifier
GLOSSARY.md                                   § selector — the arity, the anchoring rule, the
                                              quantifier, and what each previous wording got wrong
schema/opennfr.io/v1/
  requirementset.schema.json                  $defs/selector gains `properties` for
                                              loadtest.group.name and carries the value semantics;
                                              the annotation beside $ref keeps only what is true of
                                              a requirement's selector
scripts/verify.sh                             § Examples are assertable by Gatling — SELECTIONS,
                                              QUANTIFIABLE, selection_why(), the probe table, and
                                              the source reference at line 516
examples/fast-and-reliable.yaml               Checkout -> [Checkout]
examples/every-request-is-fast.yaml           the note about the guard that says the run happened
specs/004-strip-to-schema/
  contracts/gatling-reach.md                  reduced to a dated line: the contract moved to
                                              README.md. Not deleted — six markdown links in three
                                              files of the same completed spec resolve to it
```

**Structure Decision**: there is no source tree. The format is the schema, the corpus is
`examples/`, the explanation is `README.md`, the vocabulary is `GLOSSARY.md`, and the gate is
`scripts/verify.sh`. This feature touches one of each plus the redirect, which is the whole
surface a change to a selection rule can have.

## The commit sequence

Verified by execution — each commit was walked against the gate, not reasoned about. See
[research.md](./research.md) R5.

```text
docs(speckit): add 008-path-denotation spec/plan/tasks        # must carry research.md and tasks.md
fix(contract): the reach contract has one home, and it is README (#68)
feat(schema): loadtest.group.name spells a hierarchy of any depth (#53)
fix(contract): a selection row says which requests it denotes (#54)
fix(contract): the quantifier enumerates what forAll() enumerates (#70)
fix(schema): the selector's semantics sit on the node that defines one (#71)
fix(examples): a guard under a quantified selector is quantified too (#69)
```

Three things this order encodes that are not obvious from the specification:

- **The `docs(speckit)` commit is a prerequisite, not a formality.** The working tree is red as
  this is written — `plan.md` links `./research.md` and the gate fails on a dangling link. A clean
  export of `HEAD` passes; the tree does not. The Phase 0 and Phase 2 artifacts ship with the
  Phase 1 ones or the milestone starts red.
- **#53 is one issue over three surfaces and cannot be split.** Landing the corpus value first
  gives six failures across two sections; landing the schema constraint first gives two — the
  corpus document *and* `$defs/selector.examples[2]`, the schema's own embedded example, which
  carries the scalar form. Both were run. So the constraint, the schema's example,
  `selection_why()`, the probes and the corpus value are one commit.
- **#70 does not touch the schema.** The schema's only statement of `"*"` sits on the node #71
  exists to correct, so satisfying FR-024 inside #70 would mean writing the new definition there
  and deleting it one commit later — add-then-remove across a stack, which `AGENTS.md` forbids.
  FR-024, SC-007 and SC-009 are therefore **milestone-end criteria satisfied at #71**, and #70's
  PR is not to be failed for an unmet FR-024. #53 and #71 also share one coordination point: #53
  adds the `properties.loadtest.group.name` node, and if it states the list semantics there while
  #71 states them on `$defs/selector.description`, the rule is in the schema twice and SC-009
  fails. #53 picks one home and holds it.

#68 moves the tables **unchanged**, which is both the smaller diff and the more reviewable one: the
contract's tables already carry the post-#55/#56/#60/#64 form, and README's summary is the stale
copy, so #68 replaces the stale copy with the maintained one and edits no row. One consequence for
FR-007: at #68 this milestone has written no rows yet, so the merged provenance note lands with the
existing dates and without the dead `mappings/gatling.yaml` citation, and whichever later commit
writes a row adds its own dated line.

## Constitution Re-Check (post-design)

Re-evaluated against the Phase 1 artifacts rather than against the intention.

- **IV. Honest Status** — now passing; opened failing and closed by R1 from primary source. The
  disposition changed as a result: the rows carry a precondition rather than a denotation, and the
  one claim that is a replication rather than a reading is labelled as one in `research.md`,
  `contracts/reach-selection.md` and the spec's Assumptions.
- **III. No Silent Green** — strengthened by design rather than merely preserved. Phase 1 added
  what a rejection-only table cannot do: a **positive** probe table, because a one-group depth
  bound would otherwise leave every existing check green — the corpus does not nest two groups, so
  the corpus cannot stand in for a probe. Both tables gain a floor, since with ten rows the
  realistic accident is pruning eight rather than emptying the table.
- **I, II, V, VIII, Compatibility** — unchanged by the design. The wordings drafted in R4 carry the
  rejected alternatives Principle I requires, and no name is added or aliased.
- **VI. The Requirement Is Target-Blind** — still departed from, and the design adds the only
  mitigation available: the contract becomes a `### Gatling` subsection rather than the body of the
  section, so a second target is a sibling heading rather than a rewrite. The row in *Complexity
  Tracking* stands.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| **Principle VI** — the Gatling correspondence lives in `README.md`, so adding a second target changes an existing document | #68: the contract exists in two copies and they have drifted — four issues closed a release ago are live again in the copy on the page most readers meet. One home is the only fix that makes the drift structurally impossible, and the user chose `README.md` as that home | A `targets/gatling.md` would honour the principle literally, and was not chosen because the repository has **no** target-description artifact — the constitution's own Compatibility Constraints removed that surface, noting "nothing in this repository describes a target" — while `README.md` has carried a Gatling section since `6d3a882`. The real choice was one home or two, not one home or none. If a second target ever arrives, `targets/gatling.md` is where both go, and this row is the record of why it was not built first |
| ~~**Principle IV**~~ — *resolved in Phase 0, kept here as the record* | The plan opened with this gate failing: the rows claimed exact correspondences while one branch of the target's path resolution was unaccounted for | Closed by [research.md](./research.md) R1 from primary source. The disposition is not the one either alternative anticipated — the rows carry a dated precondition, because Gatling itself does not decide the collision and no format-side construct can decide it for them |
