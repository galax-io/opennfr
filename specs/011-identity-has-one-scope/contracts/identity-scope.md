# Contract — #58: one scope, and one place that states it

**Commit**: `fix(format): identity is unique within one list (#58)`
**Files**: `README.md`, `schema/opennfr.io/v1/requirementset.schema.json`, `GLOSSARY.md`
**No gate change.** `scripts/verify.sh` already implements this reading; #72 is what makes it fire.

---

## 1. `README.md` § *A predicate* — the one home

Replaces lines **357–367** in full.

### Before

```markdown
**`name`.** Needed only when two predicates of one requirement would otherwise be
indistinguishable. Identity is the `name` if set, and the `aggregation` otherwise:

```yaml
guards:   [{aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"}]
criteria: [{aggregation: rate, op: lte, threshold: 400, unit: "{request}/s"}]
# both identities are "rate" — one of them must be named
```

JSON Schema cannot express that fallback, so uniqueness is checked by `scripts/verify.sh`.
`criteria` and `guards` are checked separately: a guard and a criterion may both be `rate`.
```

### After

```markdown
**`name`.** Needed only when two predicates of one list would otherwise be indistinguishable.
Identity is the `name` if set, and the `aggregation` otherwise, and it must be unique
**within one list** — `criteria` and `guards` are counted apart:

```yaml
criteria:
  - {bad: {error.type: "*"}, aggregation: rate, op: lte, threshold: 5,   unit: "%"}
  - {name: request-rate,     aggregation: rate, op: lte, threshold: 400, unit: "{request}/s"}
# both identities would be "rate" — one is named, and either one could have been
```

A guard and a criterion may share an identity, because they are two lists.
`examples/the-run-held-up.yaml` states an unnamed `rate` guard beside an unnamed `rate` criterion
and is correct: one says the run reached the load it assumed, the other says what share of it
failed, and the shape of each is what tells them apart. JSON Schema cannot express the fallback, so
uniqueness is checked by `scripts/verify.sh`.
```

### What each edit is for

| Edit | Requirement | Why |
|---|---|---|
| *"of one requirement"* → *"of one list"* | FR-003 | the sentence named the scope this milestone removes |
| *"and it must be unique within one list"* added | FR-002 | the scope is now stated here, because it is stated nowhere else |
| the snippet's collision moves into `criteria` | FR-003 | its old collision was a guard against a criterion, which the sentence below it permits — it taught the rule being removed |
| the snippet shows the resolved form | FR-003 | `# one is named, and either one could have been` states the rule and the freedom in one line |
| `examples/the-run-held-up.yaml` named | FR-005 | the exemption is the part a reader is likeliest to take for an oversight, and the corpus is where it is already load-bearing |

### Renderability of the new snippet

FR-004. Both predicates match a **can** row exactly ([research.md](../research.md) R8):

| Predicate | Gatling | Verdict |
|---|---|---|
| `{bad: {error.type: "*"}, aggregation: rate, op: lte, threshold: 5, unit: "%"}` | `failedRequests.percent` | **can** |
| `{aggregation: rate, op: lte, threshold: 400, unit: "{request}/s"}` | `requestsPerSec` | **can** |

Both shapes are already in `PREDICATE_RENDERS`, so the illustration is of a document the gate would accept — which the example it replaces was only by accident.

---

## 2. `schema/opennfr.io/v1/requirementset.schema.json` — `$defs/predicate.name`

One string, at line **130**.

### Before

```json
"description": "Optional. Identifies this predicate in a report; without it the aggregation is the identifier, so two predicates in one requirement may not then share an aggregation."
```

### After

```json
"description": "Optional. Distinguishes this predicate from the others beside it; without it the aggregation is the identifier. What the identity must be unique within is in README.md; JSON Schema cannot express the fallback, so scripts/verify.sh checks it."
```

**Why a pointer and not a corrected copy** (FR-006). The schema does not decide this rule — it says so itself, and has since the rule existed. A description that restates a scope it cannot enforce is a copy that nothing keeps in step, which is how this one came to disagree with the document that does state it. `$defs/unit` already uses the shape: *"Closed list, from README.md."*

**And it stops saying "in a report"** (FR-006a). That phrase is the last downstream claim in the schema: a report is something a consumer builds out of results, and this format describes neither results nor consumers — a renderer turns a requirement into a target's assertions and stops. What `name` actually does is distinguish a predicate from the ones beside it, which is a fact about the document and is what a field description is for. It rides here because it is the same sentence #58 is rewriting.

The description keeps three things: that the key is optional, what it distinguishes, and that the aggregation stands in when it is absent.

---

## 3. `GLOSSARY.md` § *criterionId*

Lines **200–207**.

### Before

```markdown
### criterionId

The identity of a predicate within one requirement: its `name` if set, otherwise its `aggregation`.
Two predicates in the same list may not share one. JSON Schema cannot express that fallback, so the
gate checks it.

*Rejected*: requiring `name` on every predicate — a name is noise where `p99` and `max` already
distinguish two statements.
```

### After

```markdown
### criterionId

The identity of a predicate: its `name` if set, otherwise its `aggregation`. What it must be unique
within is stated in [README.md](README.md) § *A predicate*; JSON Schema cannot express that
fallback, so the gate checks it.

*Rejected*: requiring `name` on every predicate — a name is noise where `p99` and `max` already
distinguish two statements. *Rejected*: scoping uniqueness to the whole requirement rather than to
one list — `rate` over the requests and `rate` over a fraction are different quantities sharing a
word, the predicate's own shape already tells them apart, and the wider scope would force a name
onto a collision that is only lexical, which is the same noise the first rejection refuses.
```

### What each edit is for

| Edit | Requirement | Why |
|---|---|---|
| *"within one requirement"* leaves the definition | FR-007 | it was the entry's own contradiction: the definition said requirement, the rule two lines later said list |
| *"Two predicates in the same list may not share one"* → a pointer | FR-007 | the rule has one home, and this is not it |
| a second *Rejected* line | FR-007, Principle I | the requirement scope is the alternative this milestone refuses, and Principle I says the rejection outlives the term it protects |
| the derivation stays | — | it is the definition, and defining the term is what this page is for |

**The link style** matches the page's own: `[README.md](README.md)` as at `GLOSSARY.md:7`, with the section named in prose as `§ *A predicate*`. No anchor is written, because nothing in the repository resolves one.

---

## What this commit does **not** touch

| | Why |
|---|---|
| `examples/` | every published document is already valid under this reading (FR-009). `the-run-held-up.yaml` keeps both unnamed `rate` predicates |
| `scripts/verify.sh` | it implements this reading today. Making it *fire* is #72 |
| `README.md:546` | *"That two predicates have distinct identities. The gate checks it; the schema cannot"* states which artifact checks the rule, not what the rule is (FR-010). #72 makes it true |
| `README.md` § `criteria` and `guards` — one shape, two meanings | its snippet names a guard `reached-target-rate` beside a `p95` criterion. No collision, so nothing in it depends on the scope |
| the `name` pattern, length or optionality | unchanged (FR-011) |

## Acceptance

- `bash scripts/verify.sh` green.
- `git diff --stat` over `examples/` is empty.
- Searching the repository for a statement of what an identity is unique within returns exactly one: `README.md` § *A predicate*.
- Deleting that paragraph leaves no other document making the claim.
