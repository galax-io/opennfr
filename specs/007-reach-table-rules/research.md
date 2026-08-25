# Phase 0: research

**Feature**: `007-reach-table-rules` | **Date**: 2026-08-24

Seven questions the plan had to settle. R1 is the one that changed the shape of the work: the
resolution chosen for #55 and #56 turns out to require a change to a defined term, which the
specification did not carry.

---

## R1 — `"*"` on a path attribute carries a quantifier the selector does not have

**Question**: the spec's User Story 1 maps `{loadtest.request.name: "*"}` to Gatling's `forAll()`.
Does the format's own semantics support that reading?

**Finding**: not as the term is defined today, and this is the crux of the feature.

`GLOSSARY.md:55-57` defines the selector as "a map where every entry must match", `{}` as "every
request, said explicitly", and `"*"` as "the attribute is present with any value — it is presence,
not a glob". `README.md:246` and the schema's `$defs/selector` description agree. Under that
definition every selector picks **one set**, and every predicate under it reduces that set to
**one number** — the pooled reading. Nothing in a map of equalities carries a quantifier, which is
precisely #56's diagnosis.

So the pooled reading of `{loadtest.request.name: "*"}` is "all requests that have a recorded
name". In Gatling every request it records has a name, so that set is every request, and the
pooled reading is `global` — a longer spelling of `selector: {}`. The value would be redundant.

The per-request reading — *each named request, separately* — is the one an author reaches for and
the one #56 says cannot be written. Giving it to `"*"` is what makes the value carry its weight.
But it is a change to what a document **means**, not only to what it renders to.

**Decision**: define, at the format level, that `"*"` on a selection attribute quantifies over the
matching series — one statement per distinct value — rather than pooling them. State it without
naming a target; let the reach contract map it to `forAll()`.

**Consequences the specification did not carry**:

1. `GLOSSARY.md` § *selector* must gain the quantifier meaning in the same change. Principle I
   requires it, requires a rejected alternative with its reason, and requires the argument to
   live in an issue — which it does: #55 and #56 both argue it.
2. `README.md`'s selector table must say the same thing in the same change, since it is the
   document that describes every field.
3. The schema's `$defs/selector` description currently defines `"*"` as presence alone. What the
   schema *validates* does not change and must not (Principle VI; spec FR-017). Whether its
   `description` gains the quantifier meaning is a live question — see "Open, carried to
   `/speckit-tasks`" below.

**Alternatives considered**:

- *Map `{loadtest.request.name: "*"}` to `global`.* Faithful to the term as defined and needs no
  glossary change. Rejected: it makes the value redundant with `{}` while still reading, to an
  author, as the blanket requirement — the same trap #56 filed, moved one step along.
- *Reject the document.* The option put to the author on 2026-08-24 and declined. It would leave
  the blanket NFR — the commonest requirement there is — unwritable until v0.5.0 or later.
- *Add a separate quantifier construct (`perAttribute`, a grouping key).* A new field, a schema
  change, and a term with no precedent in the surveyed formats. Rejected as disproportionate to a
  value the format already hands authors, and it would not stop `"*"` being reached for anyway.

**Cost, recorded rather than hidden**: after this change there is no way to assert about a request
literally named `*`. The value the format hands authors for "any value" cannot also be a literal.

---

## R2 — `forAll` takes no arguments

**Question**: FR-016. Does Gatling's `ForAll` scope accept a path, and is the DSL spelling
argument-free?

**Finding**: no path, no arguments. Two independent sources agree.

- **Primary, already in this repository.** `git show cb7cb58:mappings/gatling.yaml` is the target
  description this contract was written from, deleted by `004-strip-to-schema` and still reachable
  in history. Its `assertion-support` evidence, sourced to
  `gatling-core/src/main/scala/io/gatling/core/assertion/AssertionSupport.scala @ v3.15.1` and
  **checked 2026-08-20**, states: *"Three scopes exist and no more: AssertionPath.Global,
  AssertionPath.ForAll, and AssertionPath.Details(parts). Only Details carries author strings."*
  Its `assertion-model-3-9-5` evidence adds: *"No case carries author text except Details."*
- **Corroborating, checked 2026-08-24.** Gatling's published assertion reference
  (`https://docs.gatling.io/reference/script/core/assertions/`) lists `global` and `forAll` as
  taking no arguments.

**Decision**: the claim is carried by the primary evidence, which is dated and sourced to named
files at a named version. The contract's **Checked** header is updated to 2026-08-24 for the
corroborating read, and the new rows cite `AssertionSupport.scala`, which the header already names.

**Recorded honestly**: the 2026-08-24 read of the documentation page also described `details` as
argument-free, which is wrong — `AssertionPathParts(parts: List[String])` is the whole point of
that scope. The page read is therefore used **only** for the `forAll`-takes-no-arguments point,
where it agrees with the primary source; the primary source decides everywhere else.

**Consequence**: `{loadtest.group.name: G, loadtest.request.name: "*"}` — "every request inside
one group, each separately" — has no correspondence, because there is no scope that both
quantifies and carries a path. It is a **cannot** row, and so is `"*"` in the group position.

---

## R3 — which percentiles the contract should name

**Question**: FR-011. The Aggregations table writes `p50`…`p99.9`. What is the honest row?

**Finding**: all three ends already admit more than the table names, and they agree with each
other.

| End | What it admits |
|---|---|
| Schema | `^p\d{1,2}(\.\d+)?$` — `p0` through `p99` with an optional fractional part |
| Gate | `scripts/verify.sh:561` — `a.startswith("p") and a[1:].replace(".", "", 1).isdigit()` |
| Gatling | `percentile(Double)` — arbitrary |

**Decision**: the row names *any percentile the schema's pattern admits*, and quotes the pattern
so a reader can decide `p1`, `p10` and `p99.99` without interpolating a range.

**Not a gap**: `p100` falls outside the pattern — the integer part is capped at two digits — and
needs no row. The quantity it names, the slowest observed request, is `max`, already a **can**.

**Note for `/speckit-tasks`**: the gate's predicate is looser than the schema's pattern in one
respect — it accepts a trailing dot (`"p50."`) that the pattern rejects. The schema runs first and
rejects such a document, so no document reaches the gate in that state, and no behaviour changes.
Recorded because the row will quote the pattern as the authority, and the gate should not be left
disagreeing with the sentence it implements.

---

## R4 — what apdex needs that this format does not have

**Question**: FR-012 and FR-013. What is the true reason apdex cannot be a metric here, and what
would have to become true?

**Finding**: apdex partitions each request against **two** thresholds — `rt ≤ T` satisfied,
`T < rt ≤ 4T` tolerating, `rt > 4T` frustrated — and computes
`(satisfied + tolerating / 2) / total`. Two constructs are missing:

1. **A banded classification.** A predicate carries one `threshold`; a fraction (`bad`/`good`)
   splits a selection in two by attribute presence. Neither produces three bands, and neither
   takes a second threshold.
2. **A weighted aggregation.** No member of `p*`, `max`, `min`, `avg`, `stddev`, `count`, `rate`
   takes a weighted sum of counts.

By contrast the other two quantities in the same sentence are one construct each: throughput is
`aggregation: rate`; an error rate is `bad: {error.type: "*"}` with `aggregation: rate`.

**Decision**: apdex leaves `README.md`'s derived-quantities sentence and becomes an entry in
`docs/ideas.md` § *Fields argued for and left out*, whose `*Would need*` clause names both missing
constructs. The repository already labels it **composite** rather than **derived** at
`docs/ideas.md:152`, so this aligns two documents rather than introducing a distinction.

**Alternative considered**: rewrite the reason in place, keeping apdex in the sentence. Rejected by
the author on 2026-08-24 — a construct the format does not have belongs in the ideas area under
Principle VIII, not in a sentence about quantities that *are* computable.

**Left knowingly**: `.specify/memory/constitution.md`'s Principle II carries the same sentence,
naming apdex. Out of scope (spec FR-015), recorded so it does not read as overlooked.

---

## R5 — what the two Principle III citations become

**Question**: FR-014. Principle III is *No Silent Green*; its three surviving obligations are about
reporting success on missing or unchecked data, and contain no clause about approximation. What do
the two citations at `gatling-reach.md:67` and `:92` become?

**Finding**: the constitution states plainly why the clause is absent — 3.0.0 cut the obligations
governing *rendering a document into a target's assertions* because no artifact in this repository
does that. That reasoning is recorded in the principle itself and still holds for the constitution.

**Decision**: both rules are argued from what they cost rather than by citation.

- *The fraction numerator*: a `bad` narrower than "an error happened" has no `failedRequests`
  equivalent, so a renderer meeting one has to choose a nearest available number. The rule exists
  to stop that choice being made silently — which is what the paragraph already says in its own
  words, one sentence above the citation.
- *The whole-number threshold*: rounding `0.5 ms` to `0` or `1` moves the bar the author wrote.
  The document says one thing and the run checks another, and nothing in the report says so.

Neither loses its reason; both stop borrowing authority they do not have.

**Alternative considered**: restore the clause to Principle III, on the ground that the renderer
whose absence justified the cut now exists at `galax-io/gatling-picatinny#236`. Rejected by the
author on 2026-08-24 — it is still not in *this* repository, and an amendment is an "ask first"
surface under `AGENTS.md`.

---

## R6 — how a **cannot** row is demonstrated

**Question**: FR-008 and FR-009. `examples/` holds only documents that validate, so it cannot
carry a counter-example. What proves that a rejection rule actually rejects?

**Finding**: the pattern already exists in this repository, in a different section.
`scripts/verify.sh:381-474` builds a `probes` dict for the schema section — a base document plus
one mutation per constraint, each of which must be rejected. The reach section has no equivalent:
it reads `examples/` and its only floor is `checked == 0`.

**Decision**: the reach section gains the same shape — a probe table of documents that must be
rejected, one per **cannot** rule this feature adds, with a floor that fails the section if the
table is emptied. `specs/005-fix-milestone-bugs` FR-002a settled the principle: a section
reporting success over zero probes reads exactly like a section that passed.

**Boundary**: the probes are documents handed to the gate, not schema introspection. The reach
section must keep reading `examples/` and never the schema — reading the schema would narrow the
format to one tool (`scripts/verify.sh:524-526`).

---

## R7 — how the four issues decompose into commits

**Question**: `AGENTS.md` maps one tracked issue to one semantic commit, each green on its own.
Four issues, but #55 and #56 have one answer.

**Decision**: three commits, in this order.

| # | Commit | Closes | Green on its own because |
|---|---|---|---|
| 1 | `fix(contract): three sentences that are not true as written` | #64 | Documentation only; no gate behaviour changes |
| 2 | `fix(contract): a selection row constrains its value` | #60 | Adds the string rule to contract and gate, with its probe; the corpus is unaffected |
| 3 | `fix(contract): "*" selects every named request, and says so` | #55, #56 | Needs commit 2's value-aware gate; adds the quantifier meaning, the rows, the probes and one corpus document |

Commit 3 names both issues. Splitting it would produce one commit that adds a row nothing reaches
and another that reaches a row that does not exist; neither half is green alone, and the rule's
purpose — every issue traceable to a green commit — is served by naming both on the one commit
that answers them.

**PR shape**: three PRs, stacked, each assigned to milestone v0.4.0 before merge, rebased not
merged. Commit 3's PR carries the `GLOSSARY.md` and `README.md` changes R1 requires, because they
are the same concern as the row.

---

## R8 — the schema's `$defs/selector` description gains the quantifier meaning

**Question**: spec FR-017 says the schema must not change. `$defs/selector` is one of the three
places `"*"` is defined. Does its `description` follow the redefinition, or stay as it is?

**Finding**: what FR-017 protects is the set of documents that validate, and no option here touches
it — a `description` is documentation, not a constraint. But since #31 landed, the schema documents
every shape it defines, and this description is where `"*"` is defined for anyone reading the schema
rather than the prose.

**Decision** (author, 2026-08-24): amend the `description` string, in commit 3, alongside
`GLOSSARY.md` and `README.md`. It is `$defs/requirement`'s `selector` description that carries the
quantifier, not `$defs/selector` itself: `bad` and `good` `$ref` the latter, and a numerator is one
number whatever `"*"` means for a requirement's selection. FR-017 is read as *nothing that changes which documents validate* —
every constraint the schema makes is kept, byte for byte, and only the description moves.

**Alternative considered**: leave it, so the schema stays untouched by the letter of FR-017.
Rejected: the meaning would live in `GLOSSARY.md` and `README.md` while the schema stated a
narrower one — three documents disagreeing about one value, which is the defect this whole
milestone exists to remove.

**Check**: the schema section of the gate validates every embedded example against the definition
it illustrates (`005-fix-milestone-bugs` FR-013). A description change touches no example and no
closure probe, so that section's counts — 24 embedded examples, 54 closures — must come out
unchanged. If either moves, something other than the description moved with it.
