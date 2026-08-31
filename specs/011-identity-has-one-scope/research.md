# Phase 0 — Research: Identity Has One Scope

**Feature**: `011-identity-has-one-scope` | **Date**: 2026-08-31 | **Spec**: [spec.md](spec.md)

Eight questions. Two changed a functional requirement. R1 found that the version the spec told the Identity row to cite is a version this machine cannot read, so the row now cites the one that was actually opened. R3 found that the two identity checks live in separate processes, so the single implementation the spec requires has to be a module on disk — which adds a file the spec had not counted, and a clause to `AGENTS.md`. The rest is verification: exact text, exact line, exact count, so the plan edits sentences it has read.

Everything about this repository was read at `7cf314a` on 2026-08-30 and re-confirmed on 2026-08-31. R1 is the one claim about an external tool and carries its own source and date.

---

## R1 — What are Gatling's `Assertion` fields, and at which version can that be checked here?

**Question**: spec FR-025 and FR-026 rest on `Assertion` having no slot for a label. #82 checked it with `javap` at Gatling 3.13.5; § *Gatling* is sourced to 3.15.1. The milestone says this is the one claim that cannot be checked in this repository. What can be?

**Answer**: **3.13.5 and 3.11.5, from jars already on this machine. 3.15.1 cannot be read here, and the row will say 3.13.5.**

`~/.m2/repository/io/gatling/` holds `gatling-core` at 3.11.5 and 3.13.5 and `gatling-shared-model_2.13` at 0.0.6 and 0.0.11. The poms pin them to each other:

| Gatling | pins `gatling-shared-model_2.13` |
|---|---|
| 3.11.5 | 0.0.6 |
| 3.13.5 | 0.0.11 |

3.15.1 is not present in any form, and fetching it was offered and declined — see § *What Phase 0 changed*.

`javap -p` on `io/gatling/commons/stats/assertion/Assertion.class` from 0.0.11, **read 2026-08-31**:

```text
Compiled from "AssertionModel.scala"
public final class io.gatling.commons.stats.assertion.Assertion implements scala.Product, java.io.Serializable {
  private final io.gatling.commons.stats.assertion.AssertionPath path;
  private final io.gatling.commons.stats.assertion.Target target;
  private final io.gatling.commons.stats.assertion.Condition condition;
  ...
}
```

Three fields. None is a label, a name, an id or a description. `productArity` is 3.

The same class file in 0.0.6 has the **same SHA-256**, `b58c26f79b6d6f4e9b89e48a00bc1b68bf8ad004fcbc12a2011349ccfa3ae8e9` — byte-identical across the two Gatling minors available here. That is not evidence about 3.15.1 and is not offered as any; it is the reason the row can say the shape has been stable rather than only that it was true once.

Two further findings, read while `Assertion` was open. Both are **kept out of the row** and are recorded here only as what was seen: they describe what Gatling does with an assertion once it has one, and a target description says what a renderer produces, not what becomes of it afterwards. The row's claim needs the three fields and the absence of a fourth, and nothing below.

**A result carries the assertion and nothing that points at a document.** `AssertionResult` is sealed with two cases:

```text
AssertionResult.Resolved(assertion: Assertion, success: Boolean, actualValue: Double)
AssertionResult.ResolutionError(assertion: Assertion, error: String)
```

`Resolved` adds the observed value; `ResolutionError` adds a message about resolution. Neither adds anything an author wrote.

**The failure text is a pure function of the assertion.** `AssertionMessage.message(Assertion): String` takes the `Assertion` and nothing else.

What the row states is the rendering fact and only that: two requirements selecting the same requests with the same criterion render to equal `Assertion` values, because the three fields are all there is and the key is not among them. Where those assertions go next is Gatling's, and this repository does not describe it.

**Source**: `io.gatling.commons.stats.assertion.Assertion`, read with `javap -p` from `gatling-shared-model_2.13-0.0.11.jar`, the release Gatling **3.13.5** pins. **Checked 2026-08-31.** `AssertionResult` and `AssertionMessage` were read from the same jar on the same date and are not cited by the row.

Note for the row's wording: `Assertion` is compiled from `AssertionModel.scala`, which § *Gatling*'s header **already lists** among its four sources at 3.15.1. The Identity row is therefore not introducing a new source file — it is a differently dated reading of one the section already names, and the text should say exactly that rather than leaving a reader to reconcile two version numbers on their own.

**Alternatives considered**: fetching `gatling-core-3.15.1.pom` and the shared-model jar it pins from Maven Central. Offered with sizes and declined. Writing the row at 3.15.1 anyway on the strength of the two versions that were read — rejected: Principle IV requires a claim about an external tool to be dated and sourced, and a date attached to a version nobody opened is the defect, not the discipline.

---

## R2 — Where is identity's scope stated today, and what does each site say?

**Question**: the milestone says "one scope, in four places". Is four the count, and does any site say both things?

**Answer**: **Seven sites, and two documents contradict themselves.**

| Site | Reading | Exact text |
|---|---|---|
| `schema/…/requirementset.schema.json:130` | requirement | "…so two predicates **in one requirement** may not then share an aggregation." |
| `README.md:357` | requirement | "Needed only when two predicates **of one requirement** would otherwise be indistinguishable." |
| `README.md:360-364` | requirement | a `guards:`/`criteria:` pair, both `rate`, commented "one of them must be named" |
| `README.md:366-367` | **list** | "`criteria` and `guards` are checked separately: a guard and a criterion may both be `rate`." |
| `README.md:546` | — | "That two predicates have distinct identities. The gate checks it; the schema cannot." |
| `GLOSSARY.md:202-204` | **both** | "The identity of a predicate **within one requirement**… Two predicates **in the same list** may not share one." |
| `scripts/verify.sh:157-166`, `:341-350` | **list** | `for section in ("criteria", "guards")`, `seen` reset per section |
| `examples/the-run-held-up.yaml` | **list** | two unnamed `rate` predicates in `whole-run`, one guard and one criterion |

`README.md` states the requirement reading in prose and in its worked example, then exempts the guard/criterion pair three lines below. `GLOSSARY.md` names the requirement in its definition and the list in its rule. So the "one against three" the milestone describes is really "two documents that each say both, one that says one, and two artifacts that do one thing" — which is why correcting copies was rejected in favour of one home.

**What the plan must not miss**: `README.md:546` is *not* a statement of scope and is not edited by #58. It says which artifact checks the rule. #72 makes it true.

---

## R3 — Can one implementation of the identity check serve both sites?

**Question**: spec FR-019 forbids a second implementation for probes to call. Can the two sites share a function?

**Answer**: **Not inside `verify.sh` alone. They are in separate `python3` heredocs — separate processes.**

| Section | Heredoc | Lines | Identity check |
|---|---|---|---|
| *Examples validate against the schema* | `SCHEMA` | 118–172 | `:157-166`, over `examples/*.yaml` |
| *The schema holds up its own examples, and still rejects* | `SELFCHECK` | 198–522 | `:341-350`, over the schema's root `examples` |

Nothing crosses that boundary except a file on disk. The repository already solved this once, for the same reason. `scripts/mdlinks.py` holds what a markdown link is, and both the link-resolution and the `docs/`-isolation sections import it via `sys.path.insert(0, "scripts")`. Its comment at `scripts/verify.sh:895` states the motive in this milestone's own terms:

> shared with the isolation section below so the two cannot drift into disagreeing about the same text

`mdlinks.py` also shows the rest of the shape: a `selftest()` returning every fixture it gets wrong, called before anything trusts the module, carrying **its own floor** on the fixture list — `if len(SELFTEST) < 15 or len(RESOLVE_SELFTEST) < 5` — because "an emptied fixture list would otherwise read as a sound extractor".

**Decision**: `scripts/identity.py`, imported by both heredocs, with `selftest()` and a fixture floor.

**Alternatives considered**: moving the schema's root-example identity check into the `SCHEMA` heredoc, which does already hold the parsed schema (`verify.sh:127`) and could walk `schema["examples"]`. It needs no new file and was rejected anyway: it moves a check out of the section named for checking the schema's own examples, so both sections' summary lines would stop describing what they ran. Duplicating the function into both heredocs was rejected outright — it is #58 reproduced one directory over, and spec FR-019 forbids it by name.

**Cost recorded**: `AGENTS.md` § *Structure* describes `scripts/` as "the gate (`verify.sh`) and what it shares (`mdlinks.py`)". With a second shared module that parenthetical names half of what it claims to name, so it gains one clause. This is the whole of the AGENTS.md change and it is a map correction, not a rule.

---

## R4 — What must each identity probe catch, and what is the floor?

**Question**: `FLOORS` requires each probe to be the sole catcher of something, and the number beside it to be exact. What are the classes?

**Answer**: **six probes, floor six.** Two directions, and the exemption.

| # | Probe | Sole catcher of |
|---|---|---|
| 1 | two criteria, both `rate`, neither named | the aggregation arm of the fallback, in `criteria` |
| 2 | two guards, both `rate`, neither named | the rule reaching `guards` at all — the corpus has one guard and can never collide |
| 3 | two criteria, `name: a`/`name: b` colliding, aggregations differing | the **`name` arm**, which nothing in the repository has ever exercised |
| 4 | two criteria, same aggregation, different `name`s | the check hardening into "every pair collides" — no rejection probe can show this |
| 5 | `name: rate` beside an unnamed `rate` | the two arms being one namespace, not two |
| 6 | one `rate` guard and one `rate` criterion | the per-list reset — the exemption #58 settles, and the reading `examples/the-run-held-up.yaml` depends on |

Probe 6 duplicates coverage the corpus already provides — flatten the two lists and `the-run-held-up.yaml` fails. Spec FR-017 requires this be said rather than assumed, and it is included anyway: the corpus is what a target can run and is free to change for reasons that have nothing to do with this rule, whereas a probe is here to hold the rule.

Probes 4 is the direction `SELECTION_RENDERS` and `PREDICATE_RENDERS` were added for in v0.6.0, and its absence is the reason a "return every pair" mutation would otherwise pass every other probe here.

---

## R5 — What catches a deleted call site rather than a deleted rule?

**Question**: probes call the shared function. Deleting a *call* at `:162` or `:346` leaves every probe green. What fails?

**Answer**: **a count with a floor, which is the idiom this file already uses twice.**

`verify.sh:352` floors the schema's embedded examples at `EXAMPLES = 20`, with the message *"the check is reading less than it was written to read"*. The isolation section counts `scanned` for the same reason. Principle III requires it in terms: *"any check that scanned nothing MUST say so"*.

So each site counts the lists it scanned and floors the number:

| Site | Unit | Count today | Floor |
|---|---|---|---|
| `examples/*.yaml` | lists (`criteria` and `guards` bodies) | **5** across 4 requirements, 10 predicates | 5 |
| the schema's root `examples` | lists | **1** across 1 requirement, 1 predicate | 1 |

Lists rather than predicates or requirements, because the list is the unit uniqueness is checked within after #58. Deleting either call drops its count to zero and fails on the floor; adding an example raises the count and the floor is a minimum, not an equality.

---

## R6 — What does the third verdict say, and where does the subsection go?

**Question**: FR-024 forbids **can** and **cannot**. What word, and placed where?

**Answer**: **not carried**, in a `#### Identity` subsection between § *Units* and § *Two things Gatling cannot do at all*.

The word has to survive two readings that the existing pair cannot hold together: the predicate renders (so not **cannot**), and the key does not travel into what it renders to (so not **can**). **not carried** is about the key rather than the predicate, which is exactly the distinction the axis draws.

Placement is with the axes, because it is one: § *How these tables are applied* claims the tables partition each axis, and an axis kept somewhere other than among the axes is how a partition claim goes stale. It is not a third bullet under § *Two things Gatling cannot do at all*, because nothing there fails and this does not either — that section is about aborting a run and about absent data, both of which change a verdict.

Two rows, because two of the nine predicate keys have no row today:

| Key | Verdict | Why the reason differs |
|---|---|---|
| `name`, and the `aggregation` standing in for it | **not carried** | the key is live — it is what makes two statements in one list distinguishable — and `Assertion` has no field for it |
| `displayName` | **not carried** | and nothing is lost, because the key is declared inert: nothing selected, measured or compared depends on it |

Recording `displayName` as **not carried** rather than omitting it is what makes the partition claim true for all nine keys. #82 argues `displayName` "needs no row" because it is inert, and then observes the partition is false for two keys; the row is how both are satisfied at once, and its verdict and its reason are not `name`'s.

---

## R7 — Does anything today catch a rejection added on `name`?

**Question**: FR-029 wants a rendering probe carrying `name`. Is one needed, or is it already covered?

**Answer**: **Nothing covers it. Nothing in the repository puts a `name` on a predicate.**

All 10 predicates in `examples/*.yaml` carry `name = None`; so does the schema's single root example; so do all 24 `PREDICATE_PROBES` and `PREDICATE_RENDERS` entries. A line added to `predicate_why` refusing a `name` would be caught by no document and no probe, and the corpus could not be asked to catch it — spec FR-021 keeps the corpus out of the coverage business.

`predicate_why(p)` (`verify.sh:665`) reads `metric`, `aggregation`, `op`, `threshold`, `unit`, `bad` and `good`. It never reads `name`, which is the behaviour the row publishes and therefore the behaviour that needs a probe.

**Decision**: `PREDICATE_RENDERS` gains `{**RENDERABLE, "name": "p95-latency"}` and its floor goes **14 → 15**. `verify.sh:826` states that cost as a rule — *"Adding a probe means raising the number beside it, which is the intended cost"* — and it is paid rather than waived.

---

## R8 — What replaces the worked example, and is the replacement renderable?

**Question**: FR-003 requires the example's collision be one the rule forbids; FR-004 requires it be renderable.

**Answer**: **two criteria in one list, and both rows are `can`.**

The present example collides a guard against a criterion, which the sentence three lines below permits — it teaches the reading being removed. The replacement puts both predicates in `criteria`:

| Predicate | Gatling row | Verdict |
|---|---|---|
| `{bad: {error.type: "*"}, aggregation: rate, op: lte, threshold: 5, unit: "%"}` | `failedRequests.percent` | **can** |
| `{aggregation: rate, op: lte, threshold: 400, unit: "{request}/s"}` | `requestsPerSec` | **can** |

Two identities, both `rate`, in one list, so one must be named — and naming one is what the snippet shows. Both shapes are already in `PREDICATE_RENDERS`, so the illustration is of a document the gate would accept, which is not true of the example it replaces only by accident.

The guard/criterion case does not disappear from the page. It moves to the sentence that states the exemption, where it names `examples/the-run-held-up.yaml` as the document that relies on it — spec FR-005.

---

## What Phase 0 changed

- **FR-026** required the row be dated at Gatling **3.15.1**. R1 could not read 3.15.1: it is not on this machine, and fetching `gatling-core-3.15.1.pom` and the shared-model jar it pins from Maven Central was offered with sizes and declined. The row now says **3.13.5**, which is what `javap` was run against, and adds that `Assertion.class` is byte-identical at the release Gatling 3.11.5 pins. A date on a version nobody opened is the Principle IV failure the row is being written to fix.
- **FR-034** said four files. R3 makes it six: `scripts/identity.py` is new, because the two checks are in separate processes and spec FR-019 forbids a second implementation; and `AGENTS.md` § *Structure* names what the gate shares and would otherwise name half of it.
- **SC-008** now requires a reader to be able to see that the row's version is not the section header's. R1 made that a fact about the shipped page rather than a detail of how it was checked.

Nothing else in the spec moved. The three decisions recorded in spec.md § *Decisions* were all confirmed by what Phase 0 read: the corpus and the gate hold the list reading (R2), the one-home route has a working precedent in the same file (R3), and the third verdict is the only wording that states the fact without misfiling it (R6).
