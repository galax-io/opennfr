# Phase 0: Research

**Feature**: `009-what-was-measured` | **Date**: 2026-08-30 | **Revised** the same day after adversarial review

Everything below was run against the repository at `114e4c1` (the branch point) with `python3`,
`pyyaml` and `jsonschema`. Where a finding is a reading of an external tool rather than something run
here, it is marked as such and carries its source — see R5, which is about exactly that distinction.

**R1 and R3 were rewritten after review.** The first draft's conclusion on #57 — narrow the schema —
was reversed. R1 keeps what was investigated, because the work is the reason the reversal is cheap:
the rule was written and validated, so if the condition in R2 is ever met, it can be shipped from
this file unchanged.

---

## R1 — The schema rule that was written and is not shipped (#57)

Three forms of a fifth `allOf` branch were written and validated. All three agree on every verdict
and differ only in the message and the error path:

| Form | `if` / `then` | Message on `{metric, aggregation: count}` | Path |
|---|---|---|---|
| **A** | aggregation ∈ {count, rate} → `not required metric` | `{'metric': …, 'aggregation': 'count', …} should not be valid under {'required': ['metric']}` | `spec/requirements/0/criteria/0` |
| B | aggregation ∈ {count, rate} → `properties: {metric: false}` | `False schema does not allow 'http.client.request.duration'` | `spec/requirements/0/criteria/0` |
| C | `required: [metric]` → aggregation `not` ∈ {count, rate} | `'count' should not be valid under {'enum': ['count', 'rate']}` | `spec/requirements/0/criteria/0/aggregation` |

A would have been the one, as rule 4's exact counterpart. The `"required": ["aggregation"]` guard
was verified to be load-bearing: without it, a predicate missing `aggregation` picks up a second,
spurious message about a `metric` it was never told it could not carry.

Verified verdicts under form A, all nine cases: `{metric, count}` and `{metric, rate}` rejected with
one message each; `{count}`, `{rate}`, `{bad, count}`, `{bad, rate}`, `{metric, p95}` unchanged;
`{metric}` with no aggregation and `{metric, median-ish}` unchanged at one message each.

**None of it ships.** See R2.

---

## R2 — Why the schema is not narrowed, and what would reverse that (#57)

**Decision**: outcome 1 of #57's three — fix the gate, leave the schema alone.

**Three grounds, each checked:**

1. **The shape has a referent.** `{metric: X, aggregation: count}` denotes how many observations of
   `X` the selection carries. That differs from how many requests it carries wherever the metric is
   not recorded for every request — and the format admits metrics for which that is so: it publishes
   `http.server.request.duration` "when a requirement is stated over the system's own data rather
   than the generator's", and the schema does not enumerate metric names at all. `README.md` states
   the meaning at format level, in § *What a criterion can be about*: the `metric` row's
   "aggregations that mean anything" include `count` and `rate`.
2. **Narrowing would break a binding constraint.** From the constitution's Compatibility
   Constraints, verbatim: *"The published corpus MAY be narrower than the format, and the format
   MUST NOT be narrowed to match it… The schema keeps what no target reaches, and the field
   description says which parts those are."* The first draft's FR-004 would have deleted the
   format-level claim above to make the schema agree with a Gatling table. `scripts/verify.sh` makes
   the same argument in its own comment, in the other direction: *"Extending this section to read the
   schema would be the format narrowing to one tool, which the constitution's Principle VI forbids."*
3. **No principle separates it from the shapes already left alone.** Run against the published
   schema: `{metric, sum}` → **valid**, `op: neq` → **valid**, `{http.route: …}` → **valid**. All
   three are `cannot` rows. The rule would have made `{metric, count}` the only reach-`cannot` the
   schema also rejects.

**And the defect is elsewhere.** The first draft's own R3 said it and did not draw the conclusion:
with `count` and `rate` removed from `TABLE["metric"]`, such a predicate "falls to
`aggregation count over a metric has no equivalent`, which is the reach tables' own verdict". That is
the silent drop, ended, in four deleted lines.

**The condition that reopens this**, recorded because neither side checked it: if no surveyed target
computes a per-metric observation count, and the format cannot say what the shape denotes
independently of the request count, then the field has no referent and form A is correct. The check
is k6's Trend `count` and Prometheus's `_count`, against dated documentation, as Principle IV
requires. The asymmetry decides the order: shipping the gate fix now costs two lines and adding the
rule later costs the same as it costs today, while shipping the rule now and finding a referent costs
a withdrawal on a compatibility-sensitive surface.

**Rejected alternatives**, recorded in `GLOSSARY.md` § *aggregation*: outcome 2, declaring the
`metric` ignored, which Principle III forbids by name; and outcome 3, the schema rule above.

---

## R3 — The `scripts/verify.sh` edit set

Three edits, in two commits.

**#52, in commit 4:** the comment above `SELECTIONS` (line ~555) ends *"…a cumulated duration the
Metrics table cannot name (#52)"*. The pointer goes; the sentence stays. It does not gain a copy of
the row — `README.md` is the only place the tables are stated. No behavioural change: `SELECTIONS`
keeps its three key sets, `NOT_A_PATH` is unchanged, and the `{HIERARCHY: ["Checkout"]}` probe still
fires.

**#57, in commit 5:**

1. `TABLE["metric"]` (line ~597) loses `"count"` and `"rate"`. Both were byte-identical to the
   `"requests"` rows, which is precisely why the `metric` key resolved to nothing and was reported
   nowhere.
2. A **predicate probe list** and its floor arrive — see R4.

**Not edited**: `QUANTIFIABLE`, `selection_why`, `SELECTION_PROBES`, `SELECTION_RENDERS`,
`REJECTIONS`, `RENDERS`, `shape_of`, `BAD`, `OPS`, the fraction table. #77 and #78 change what three
documents *say* about `"*"`; the gate already implements the surviving reading —
`({HIERARCHY: ["*"], REQUEST: "POST /checkout"}, QUANTIFIED)` is probe 10 and passes today. That the
gate already agrees is itself evidence that the presence reading is the intended one.

---

## R4 — Four of five reach axes have never been probed

**Finding**, and the largest thing this milestone found: the Gatling section probes **one** axis.

```
SELECTION_PROBES  = [...]   # 10 entries, selection only
SELECTION_RENDERS = [...]   #  5 entries, selection only
REJECTIONS, RENDERS = 10, 5
```

There is no probe for the metric axis, the aggregation axis, the operator axis or the unit axis. The
corpus cannot stand in for them: it holds only documents that are assertable, so every *rejection*
rule on those axes is unexercised and could be deleted green. The file states the principle itself —
*"a rule nothing probes is a rule nothing checks"* — and then applies it to one axis in five.

That is the mechanism behind #57: `TABLE["metric"]`'s `count` and `rate` rows survived five releases
because nothing exercised the metric axis.

**Decision**: a predicate probe list joins the section in commit 5, in the shape `SELECTION_PROBES`
has, with its own floor. Minimum coverage: `{metric, count}` (the sole catcher of the defect
regressing), `{metric, rate}`, `{metric, sum}`, a non-addressable metric, `op: neq`, a percentile in
`%`, and a fractional-millisecond threshold. No rendering counterpart is needed — every accepted
predicate shape is already exercised by the corpus, which the selection axis could not claim.

---

## R5 — The claims that must not be made (#62, Principle IV)

**Decision**: #62's row asserts nothing about Gatling, and does not claim a naming gap where there is
none. Two sentences were cut for two different reasons.

**Cut one — an undated external claim.** A first draft read: *"`responseTime` is the same statistic
whatever recorded the entry, so Gatling would render it."* The evidence exists — #62 reports
`statsEngine.logResponse` recording a bracketed span as a named entry, read from gatling-core and
gatling-charts 3.13.5 and 3.15.1 — but it is the issue author's reading of decompiled sources and
this branch cannot re-check it. The row does not need it: the verdict is `cannot` either way.

**Cut two — a false claim about upstream.** A first draft read: *"no published name is true of the
quantity"*, applied to the whole class. That is false for the non-HTTP protocol half. Semantic
conventions do name a database call, a message and a remote call, and a document carrying such a name
**validates against the published schema today** — verified by running the published schema against
one. For that half the obstacle is that no rendering has been checked and dated and no example uses
one: an evidence gap, not a naming gap.

So the published text states two halves differently. Only one is the format's:

| Case | Obstacle | Where |
|---|---|---|
| an operation on another protocol | no dated rendering, no example — the general Names rule already applies and the document is valid | § *Names*, and the `any other` row |
| a duration recorded for a span an author bracketed | **no name at all**, in any convention | § *Names*, and the `any other` row |

**A further constraint on the wording**: no specific convention name may be written into a file
unless it is checked and dated in the same change. This branch does not do that, so the text names
none.

**The contrast is #52**, where the equivalent claims are already published and dated: the three
scopes (checked 2026-08-20, re-checked 2026-08-24) and the cumulated statistic (2026-08-25, v3.15.1
and v3.13.5). That row reuses them and introduces nothing.

**Rule for the implementer, because the temptation recurs**: a `cannot` may describe what the format
cannot say. It may not describe what the target would do.

---

## R6 — The `"*"` sentences: where they live, and what stays (#78, #77)

Counted at `114e4c1`:

| Artifact | `is not a name` | Where |
|---|---|---|
| `README.md` | 1 | line 257, inside the anchoring rule's paragraph |
| `GLOSSARY.md` | 2 | line 71 (the quantifier's derivation) and line 80 (the anchoring rule's trigger) |
| schema | **0** | — |

**Decision, #78**: the schema gains it in `$defs/selector.description`, beside the anchoring rule, so
a consumer sent there by `$defs/requirement` can evaluate the rule's trigger without opening another
file. Its closing sentence — *"…whose values may be strings, numbers or booleans"* — gains the
exception for `loadtest.group.name`; verified that `7`, `true` and `"MyGroup"` are each rejected with
*"is not of type 'array'"*. The sentence is corrected and not deleted: it is what justifies
`additionalProperties: {type: [string, number, boolean]}`.

**Decision, `GLOSSARY.md`'s two occurrences: both stay.** The first draft proposed deleting line 71's
clause, justified by *"this is exactly how `README.md` is already arranged"*. That justification is
**false**, checked at `README.md:249-258`: README joins the premise and the consequence in one
sentence, and its `"*"` cell carries neither *"no hierarchy is claimed"* nor *"at any depth"*.
Deleting the clause would leave *"the quantifier reaches every position at any depth"* asserted
without its premise. #78 asks for neither deletion; it reports the schema's silence.

**Decision, #77**: `"*"` is presence in every position it can occupy, hierarchy elements included.
This is the milestone's one genuine judgment call and it is made on cost:

- The presence reading is the status quo, published coherently in three places — the `"*"` cell, the
  reach row for a wildcard path part, and the gate's `QUANTIFIED` message, which already covers both
  positions — so #77 costs one schema sentence, one *Rejected* line and one README cell.
- The literal reading is a semantics reversal on a compatibility-sensitive attribute: two README
  paragraphs, a deleted reach row, a changed gate rule, a moved probe and two shifted floors.
- It does not remove an exception, it relocates one. `"*"` would mean presence in a scalar value and
  a literal name in a list element, so the token's meaning becomes arity-dependent and one selector
  could carry both at once.

The cost is stated rather than hidden, and `README.md` already states it: a group whose recorded name
is literally `*` is **unnameable**. That is what one spelling for "any" costs.

**Kept reversible**, since the evidence is thin: `GLOSSARY.md` § *selector* records the literal
reading as rejected in its strongest form — *an element of a list is not a value of the attribute* —
so a later reversal is a documented flip of one gate test rather than a rediscovery.

**One duplication is removed**: the `loadtest.group.name` cell in § `selector` ends *"and no scope
carries a wildcard path part"*. That is a fact about a target inside a field description, duplicated
from the reach row. It goes; the row keeps it.

---

## R7 — What the isolation gate counts, and why no idea is added (#62, #52)

Read from `scripts/verify.sh` § *docs/ is isolated*:

```python
entries = re.findall(r"^\*\*(.+?)\*\*", text, re.M)
needs = text.count("*Would need*")
...
elif needs != len(entries):
```

An entry is a line beginning `**…**`, and the count of *Would need* must **equal** the count of
entries — not merely be non-zero.

**Decision**: no entry is added. The first draft proposed two; both duplicate a condition already
published verbatim under § *The `loadtest.* registry*`, whose *Would need* reads *"submission
upstream, and something that emits the names"* and which already carries a "deliberately absent"
list. The registry entry gains **one clause** naming the composite-span case, and the counts stay
equal without touching them.

#52's condition is not parked in `docs/` at all: it belongs in the reach row, which is where a reader
meets the refusal. A second home for it is exactly the duplication `docs/ideas.md` forbids in its own
opening — *"A note that has become a rule is a second source for one decision."*

---

## R8 — The commit sequence, and why #57 is last

The milestone description sequences #62 → #52 → #57. That dependency is preserved. The rest is
ordered so the contestable commit is the revertable one.

| # | Issue | What it is | Contestable |
|---|---|---|---|
| 1 | #78 | schema description gains a clause; closing sentence corrected | no |
| 2 | #77 | one reading in three artifacts; one duplication removed | the reading is a judgment call, recorded as reversible |
| 3 | #62 | a row gains its reason; a *Rejected* line | no |
| 4 | #52 | a row stops deferring and gains a better reason | no |
| 5 | #57 | two lines deleted from the gate; two rows; a probe list | **yes** — it decides that the shape stays valid |

#78 before #77 because a `"*"` element is presence *because* `"*"` is never a name; stating the
consequence before the premise is how the two readings came apart. #57 last because a reviewer who
prefers the schema rule reverts one commit and loses nothing else — which is not true in any other
position.

Commits 1–2 both edit `$defs/selector.description`; commits 3–5 all edit `README.md` § *What any tool
can actually run*. Each group is adjacent so no unrelated commit sits between two edits to one
paragraph.

**Recorded as a deviation** from the milestone's narrative order rather than applied silently.

---

## R9 — Found here, out of scope, needs its own issue

`$defs/aggregation.description` reads: *"`rate` reads from the shape it is applied to, as it does in
k6: over a `distribution` it is per second, over a `ratio` it is the fraction."* Neither
`distribution` nor `ratio` is a term this schema contains — `$defs` holds nine definitions and
neither is among them; both were removed with the assertion-first revert, as `scripts/verify.sh`
itself records. `GLOSSARY.md` § *aggregation* already carries the correct wording: *"over requests it
is per second, over a fraction it is the share."*

The schema is the sole dissenter of three artifacts, in a milestone about what a word means. It is
still out of scope: `AGENTS.md` is explicit that docs, tweaks and out-of-scope improvements go in
separate PRs and never mix with issue commits. Recorded here and in the spec's *Out of Scope* so it
is filed rather than forgotten.
