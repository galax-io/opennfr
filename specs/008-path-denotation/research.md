# Phase 0: Research

Five questions, each answered against a primary source rather than against the repository's own
account of one. R1 was the gate the plan opened as failing; R2 and R5 were executed against a trial
checkout rather than reasoned about, and say so.

---

## R1 — What `details(...)` denotes when a group shares a request's path

**Decision**: rows 2 and 3 of the Selection table carry a dated **precondition**, not a denotation:
*the rendered path must not also be the full hierarchy of a recorded group.* Where it is, Gatling's
resolution is unspecified and the assertion may measure a different quantity. The rows stay **can**.

**Read from primary source 2026-08-25**, `gatling/gatling` at tags `v3.15.1` and `v3.13.5`, plus the
`io.gatling:gatling-shared-model` sources those tags pin (`0.1.3`, `0.0.11`). The four methods below
are identical across the two versions.

**Rationale.** The question the specification asked — *which branch is tried first* — has no answer,
because the branches are not tried in sequence. `LogFileData.findPathByParts` is one `collectFirst`
over the **keys of a hash map**:

```scala
override def findPathByParts(parts: List[String]): Option[AssertionStatsRepository.StatsPath] =
  resultsHolder.groupAndRequestsNameBuffer.map.keys.collectFirst {
    case RequestStatsPath(request, group) if group.map(_.hierarchy).getOrElse(Nil) ::: request :: Nil == parts =>
      AssertionStatsRepository.StatsPath.Request(group.map(_.hierarchy).getOrElse(Nil), request)
    case GroupStatsPath(group) if group.hierarchy == parts => AssertionStatsRepository.StatsPath.Group(group.hierarchy)
  }
```

A key is a `RequestStatsPath` or a `GroupStatsPath`, never both, so the textual order of the two
`case` arms is never exercised as a tiebreak. The tiebreak is the iteration order of
`scala.collection.mutable.HashMap` — a function of the hashes of every key present and of the table
size. Not insertion order, not documented, not stable.

Where the group wins, `AssertionValidator.resolvePath` measures the **group's cumulated response
time**, which is a different quantity from the request's response time:

```scala
case Some(AssertionStatsRepository.StatsPath.Group(group)) =>
  Right(AssertionValidator.PathResolution(
    unfoldedAssertion = assertion,
    // FIXME we need an Assertions API overhaul to be able to target the group duration metric as well
    statsByStatus = statsSource.groupCumulatedResponseTimeGeneralStats(group, _)) :: Nil)
```

The collision is reachable in an ordinary simulation — `group("X"){ … }` beside a root-level
`http("X")` — Gatling has no guard against it, and no test covers it: `AssertionSpec`'s
`SetRequestThenGroupModifiers` applies its request and group modifiers one at a time, so the two are
never both present, and its stub `findPathByParts` is `List`-backed and therefore order-deterministic
where production is not. The same collision exists at every depth, so it affects both rendering rows.

**Labelled as replication, not reading** (Principle IV): the three case classes were re-implemented
on the Scala version `build.sbt` pins at `v3.15.1` and exercised directly. Over 676 two-letter names
each given a root group and a root request of that name, the group won 342 and the request 334 — a
coin flip decided by the name — and for a fixed pair the winner flipped as unrelated requests were
added to the buffer. This was **not** run against Gatling itself. It is what turns "unspecified" into
"unstable", and it is the one claim here that is not a source reading.

**Three further readings, all verified from the same source:**

- `forAll()` enumerates **only requests, once per position**. `allRequestPaths()` `collect`s solely
  the `RequestStatsPath` case, so every group key is dropped, and its source is a map's key set, so
  each `(hierarchy, name)` pair appears exactly once. This is what FR-022 is written from, and it
  settles the third granularity question directly: not per distinct value, not per occurrence.
- `forAll()` never calls `findPathByParts`, so the quantified row is **immune** to the collision
  above while the singular rows are not.
- `AssertionPathParts(parts: List[String])` with `/` as plain list append, and
  `AssertionPath.Details(parts: List[String])` — no arity bound at any layer. `Details(Nil)` is
  explicitly aliased to `Global` in `resolvePath`.

**Alternatives considered.** *Pick a side and say the row denotes a request* — rejected: Gatling does
not pick a side, so the row would be asserting something untrue of the target. *Make the rows
`cannot`* — rejected: the collision is a corner of the target, not a property of the format, and
three of four published documents would leave the corpus over a case none of them is in. *Add a
construct that says "a request, not a group"* — rejected: nothing in Gatling's assertion API consumes
such a distinction, so it would be a field no target can honour.

**Risk.** The precondition is unenforceable from a document: whether a run records a group of that
name is not knowable when the document is written. It is recorded as a fact about the target, which
is what this repository does with facts about targets.

---

## R2 — The `scripts/verify.sh` edit set

**Decision**: `selection_why()` is a rewrite, not an extension; `SELECTIONS` and `QUANTIFIABLE` keep
their values; a second probe table is added for the direction a rejection table cannot cover; and the
three schema-level rejections SC-005 names go in a **different** section.

**Verified by execution**, not proposed: the set below was applied to a trial checkout of `HEAD`, the
gate ran `PASS`, and a twenty-mutation sweep confirmed each rule reddens the gate when deleted.

**Rationale, in the four parts that are load-bearing.**

*The key-set list was never the whole rule.* The value rule always sat beside it. What changes is
that the value rule was uniform — every value a string — and now is not: `loadtest.group.name`
carries a list and every other key a scalar. So the value half splits, and the split needs a joint:
a `path_parts()` flattener producing the path a selector spells, with the two attribute names bound
to constants so that four literals of one name are not four chances to fix three of them.

*Branch order is a rule, not a style.* The `isinstance(..., list)` check must precede the flattener.
Measured on the real function: `path_parts({"loadtest.group.name": "Checkout", …})` returns
`['C','h','e','c','k','o','u','t','POST /checkout']` — nine parts, every one a string, silently
accepted as an eight-deep hierarchy. This is why the scalar rejection is a probed rule and not only
a schema concern.

*One substitution carries an existing row into the array world.* Moving the `"*"` test from
`sel.values()` to `path_parts(sel)` is what keeps `{loadtest.group.name: ["*"], …}` a **cannot**
without adding a rule. Under `sel.values()` the group value is a list and never equals `"*"`, so the
existing branch **goes silently dead** — confirmed: `["*"] == "*"` is `False` — and a `"*"` inside a
hierarchy would render to `details("*" / "X")`, a path matching nothing. That is the exact hazard
#55 closed, re-entering through the arity change.

*A rejection table cannot show that a row still renders, and the corpus cannot either*: nothing
published nests two groups, so a one-group depth bound added to the rule would leave every existing
check green. Measured. Hence a second, positive probe table whose last row is SC-004's three-level
requirement, and a floor under both tables — with ten rows, pruning eight is the realistic accident,
not emptying the table.

**Where SC-005 lives.** The Gatling section reads `examples/` and never the schema, by a rule it
carries in its own comments. The three schema-level rejections — a scalar, an empty list, an array
under another attribute — therefore go in § *The schema holds up its own examples, and still
rejects*, whose closure floor moves from 50 to 54.

**Two side effects, both measured**: `$defs/selector.examples[2]` carries
`"loadtest.group.name": "MyGroup"` and must become `["MyGroup"]`, caught by the embedded-example
check; and adding `properties` to `$defs/selector` does **not** add an inline-shape slot, because
that scan appends only nodes that themselves carry `properties`.

**Risk.** "Outermost first" is stated in `path_parts()` and nowhere machine-checkable: the gate never
renders, so element order cannot be verified here. Recorded as a limitation rather than papered over.

---

## R3 — Where the contract lands in `README.md`

**Decision**: § *What any tool can actually run* (`README.md:499`) grows in place; the contract
becomes a `### Gatling` beneath it; the summary table at `README.md:510-520` is **deleted**, not kept
alongside.

**Rationale.** Keeping both recreates the two-copy defect inside one document, which is the whole
subject of #68. The summary is a strict subset — checked row for row against the contract, with the
contract carrying ten Selection rows to the summary's one. A `### Gatling` wrapper costs one heading
and makes a second target a sibling heading rather than a rewrite of the section, which is the only
mitigation available for the Principle VI departure recorded in the plan. No markdown link or anchor
anywhere in the repository targets a README heading, so the heading edits are free as far as the gate
is concerned.

**Overlaps that would otherwise become duplicates inside one document**, each to be resolved in the
commit that creates it:

- The quantifier definition would sit in three places at once — § `selector`, a code comment in its
  example block, and the contract's own prose, which says out loud that it is "restated in
  `README.md`" and becomes self-referential after the move. § `selector` owns the **definition**;
  the Selection row carries the **correspondence** and no second definition.
- "A selector cannot say an attribute is absent" has three homes outside `specs/` and would have
  three inside README after the move. It stays once, in § `selector`; the fraction table's `good`
  row points at it.
- The contract's list of unreachable units is the complement of README's own unit table. Two derived
  lists of one enumeration in one document drift silently.
- README's example block for a selector duplicates `$defs/selector.examples`; both carry the scalar
  form and both change in the same commit.

**Verified**: `mappings/` does not exist (`ls` → no such file); it was deleted by `02829bd`. The
provenance citation `mappings/gatling.yaml @ cb7cb58` is dead and does not move.

**Link inventory**, produced with the gate's own extractor: six markdown links resolve to the
contract, in `specs/004-strip-to-schema/quickstart.md:38`, `tasks.md:33`, `tasks.md:97`,
`tasks.md:104`, `tasks.md:105`, `plan.md:41` and `plan.md:69`. Mentions elsewhere are code spans and
are unaffected.

---

## R4 — The four wordings

**Decision**: one kernel of five clauses, carried by the three texts that state value semantics —
`GLOSSARY.md` § *selector*, `README.md` § `selector`, and `$defs/selector.description`. The fourth
node, the annotation beside `$ref`, carries **none** of them.

The kernel, so that the three texts can be checked against each other rather than against taste:

- **K1** — a selector selects requests by attribute; every entry must match, by equality.
- **K2** — `loadtest.group.name` is the enclosing groups as an ordered list, outermost first, at any
  depth; each element a literal recorded name; matched as the whole hierarchy and not a prefix.
- **K3** — where a selector names a request, an absent `loadtest.group.name` means the empty
  hierarchy. It fires only where a request is named.
- **K4** — `"*"` is presence, not a glob. On a requirement's selector it also quantifies: once of
  each request position the selector admits. Not once per distinct value, not once per occurrence.
- **K5** — inside `bad` or `good` it does not quantify; everything else reads the same there.

**Rationale.** FR-024 requires four homes to state one rule, and the only way to check that is to
write the rule once and derive each text from it. The `GLOSSARY.md` entry additionally carries what
Principle I requires: what each previous wording got wrong, and the rejected alternatives — a
separate `loadtest.group.path` key (two keys for one attribute; the name was never what was missing,
the arity was), a scalar-or-array union (two spellings of one hierarchy), and `[]` for "no enclosing
group" (a third spelling of what omitting the key already says, and one that reads as
"unconstrained" to everyone who meets it first).

**Risk.** The claim "the only numerator any surveyed target renders is `{error.type: \"*\"}`" appears
in the drafted text and is sourced only to the contract restating itself. It is true of the
Aggregations table as it stands, and it is not new to this change; flagged rather than fixed here.

---

## R5 — The commit sequence

**Decision**: the specification's order holds — #68, #53, #54, #70, #71, #69 — with one deferral
made explicit and one prerequisite that is red today.

**Verified by execution.** Every commit is green on its own, and no pair of issues has to be merged.
Only #53 has any gate coupling at all: the gate reads `examples/`, the schema's *constraints*, and
markdown link targets, and never compares prose or `description` strings against anything.

**The prerequisite.** The working tree is red **now** — `plan.md` links `./research.md`, which did
not exist when the plan was written. Reproduced: `bash scripts/verify.sh` → `FAIL … -> ./research.md`,
`rc=1`, while a clean export of `HEAD` passes. The `docs(speckit)` commit must therefore carry
`research.md` and `tasks.md`, not `spec.md` and `plan.md` alone.

**#53 cannot be split**, proven in both directions by running the gate:

- corpus first (`Checkout` → `[Checkout]`, schema untouched) → six failures across two sections;
- schema first (constraint added, corpus still scalar) → two failures: the corpus document **and**
  `$defs/selector.examples[2]`, the schema's own embedded example.

So #53 lands the schema constraint, the schema's own example, `selection_why()`, the probes and the
corpus value together — one issue over three surfaces, which the rule permits, rather than two
issues in one commit, which it does not.

**#68 moves the tables unchanged**, and this is both the smaller diff and the more reviewable one.
The contract's tables already carry the post-#55/#56/#60/#64 form — spec 007 edited them, and
README's summary is the stale copy — so #68's entire job is to replace the stale summary with the
maintained tables, reduce the old file to a dated redirect, and repoint the gate's source comment.
Zero row edits from this milestone. Folding the later row edits in would put three issues in one
commit and make the move undiffable as a move.

**#70's schema half is deferred to #71.** FR-024 wants the quantifier stated in four homes including
the schema; the schema's only statement of `"*"` today sits on the wrong node, which is #71's entire
subject. Satisfying FR-024 inside #70 means writing the new definition onto that node and deleting it
one commit later — add-then-remove across a stack, which `AGENTS.md` forbids. So **FR-024, SC-007 and
SC-009 are milestone-end criteria satisfied at #71, not per-commit criteria**, and #70's PR is not to
be failed for an unmet FR-024.

**One coordination point between #53 and #71**: #53 adds the `properties.loadtest.group.name` node.
If it puts the list semantics in a `description` there while #71 puts them on
`$defs/selector.description`, the rule is stated twice in the schema and SC-009 fails. #53 picks one
home and holds it.

**Alternative considered**: #53 before #68, so the construct lands before the contract moves.
Rejected — every row #53 touches would then be edited in two copies, which is the defect #68 exists
to remove and the reason the specification puts it first.
