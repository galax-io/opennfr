# Architecture

How a requirement becomes a target's own assertions, what each component on that path may not
know, and what the target is told it could not be given.

## Status of this document

This document carries **two statuses at once**, and every clause and table row below says which
one applies to it. Nothing is unmarked.

| Marker | Meaning |
|---|---|
| **(binding)** | Later specifications must obey it. Component roles, their forbidden dependencies, and the boundaries between follow-up specs |
| **(proposed)** | Describes something that does not exist yet. True of every component named here — none is built |

The split is not decoration. [Principle IV](.specify/memory/constitution.md) forbids a
document from reading as more settled than it is, while a rule nobody must follow is not worth
writing. Roles bind; the machinery that would fill them is proposed.

**Amending this document** *(binding)*: an ordinary pull request that edits it, landing
**before** the specification that diverges from it. No decision record is required — this
document is not a compatibility-sensitive surface. The sanctioned route is deliberately cheaper
than the workaround, because a route more expensive than the workaround is not a route.

---

## 1. The path

A requirement is written once, by a human, and names no tool. It is rendered into the target's
own assertions, and there it stops.

```text
requirement ── criterion ──> the target's own assertion ──> the target runs it and decides
     │             │                    │
     │             │                    └─ plus one named entry for every predicate that
     │             │                       could not be rendered, before the run starts
     │             └─ rendered against one target description (R2)
     └─ parsed into an object model (R1)
```

1. *(binding)* The path ends at the **rendering**: the target's own assertions, together with
   the named list of predicates that could not be rendered. What happens next belongs to the
   target — it evaluates, it reports, it decides the run. This repository defines no verdict,
   no outcome, no gate policy and no result document, and no component here consumes a
   target's output.
2. *(binding)* No role may read the requirement document to discover which target it is for.
   The target is a parameter of rendering, never a property of the requirement — the
   constitution's Principle VI. The same holds one step further out for any source of
   measurement, which is [ADR-0002 § D18](docs/adr/0002-compatibility.md) and is unaffected by
   the narrowing.
3. *(binding)* What may enter the format at all is decided by the constitution's Compatibility
   Constraints, and this document deliberately keeps no copy of that rule. The clause that
   stood here — "No construct may be checkable only while a run is in progress" — was the
   third of four copies of a rule that has since been inverted, and four copies are what let
   four documents disagree.

---

## 2. The component roles

Roles are contracts, not modules. Two remain. **Render is now the whole of the glossary's
`Adapter`**, not one of its four jobs: renaming metrics, converting units and renaming a tool's
tags survive only inasmuch as rendering needs them to write an assertion the target will
accept. The glossary's `Adapter` entry is narrowed accordingly rather than joined by a rival
word, which is what [Principle I](.specify/memory/constitution.md) requires.

The original request called these *interpreters*. In this repository's vocabulary that word is
`Adapter`; `interpreter` is not used.

| # | Role | Input | Output | MUST NOT know | Status |
|---|---|---|---|---|---|
| R1 | Parse | One document | An object model, or a parse error naming the field and its line | Which target will consume the result | **binding** |
| R2 | Render *(Adapter)* | The document's predicates + one target description | The target's native assertions; **a named list of every predicate it could not render, with a reason**; and, per rendered entry, **the identity the target will derive its own report line from**, and whether that entry states a condition of the run rather than a property of the system | Whether the run will pass | **binding** |
| R3 | ~~Ingest~~ | — | — | — | **withdrawn 2026-08-20, with post-run evaluation** |
| R4 | ~~Evaluate~~ | — | — | — | **withdrawn 2026-08-20, with post-run evaluation** |

R3 and R4 are withdrawn and their numbers are withdrawn with them. R1 and R2 are cited
elsewhere and a reused number silently redirects a citation. The arguments for both roles are
parked, not deleted: they return through the same route any other idea does.

**Why R2's third output exists** *(binding)*. A target need not let a document name an
assertion, and neither surveyed target does. Gatling derives every string it prints for an
assertion from the assertion itself — console, JUnit XML and the HTML table all render one
derived message per result, and its per-request scope is rewritten to a concrete request path
before any message is built (checked in `gatling/gatling`, 2026-08-20). k6 prints the metric,
the tag selector and the expression. A statement about the run's conditions therefore cannot
be told from a statement about the system by a name in the report; it is told apart by matching
the report's line to the rendering entry that produced it. That correlation is what makes
[Principle III](.specify/memory/constitution.md) enforceable at run time against a target that
has no field for a name.

**Units are converted at render time** *(binding)*, by the declaration in the target's
description, never by whoever implements the role. The survey records targets whose duration
thresholds are whole milliseconds and targets that take a float; an error here is three orders
of magnitude wide and produces a confident, wrong, green result. A threshold that does not
survive the conversion exactly makes its predicate unrenderable rather than rounded.

### What no role may do

4. *(binding)* Every predicate is either rendered or reported unrenderable **by identity**.
   Dropping one silently is forbidden: a dropped predicate is a check that never ran and a
   result that looks clean. The identity relation is *predicate → exactly one of the two
   lists*. It is **not** *predicate → exactly one assertion*: one predicate may legitimately
   render into more than one native assertion — a range a target expresses only as two
   comparisons, a per-request scope a target reaches only by naming each request, a companion
   assertion that stops the target passing on an empty selection — and that is not a breach of
   the sum rule.
5. *(binding)* When a target cannot honour a construct, the result is a **named failure** —
   never a substitution, an approximation, or a silent omission. The gap is declared in the
   target's description and surfaces at render time, before the run rather than after it.
6. *(binding)* A measurement taken at one vantage point may not stand in for one taken at
   another. A load generator measures latency as a client; a production stack usually measures
   it as a server. The numbers are not comparable — and neither are two targets' derivations of
   the same statistic, which each target's description records for itself, dated.
7. *(binding)* Silence is not a pass, at render time or at run time. A predicate that produced
   neither an assertion nor a named entry is forbidden here. A target that can pass an
   assertion which matched nothing is a property of that target and MUST be declared in its
   description; rendering may not present a predicate as covered when the description says the
   target cannot fail it. [Principle III](.specify/memory/constitution.md).

---

## 3. Targets

*(binding)* A **target** is the external product an adapter faces. Support is added by adding
data, never by adding code.

| Class | What it does | Can host assertions? | Status |
|---|---|---|---|
| Load generator | Produces the traffic, asserts against what it measured, reports, and decides the run | Yes — and only a target that can is served by this format. *What* it can assert is declared per capability in its own description, each claim dated and sourced, never as a level | **binding** |
| Monitoring backend | Holds telemetry and answers a query | No. It hosts no assertion, so it has no path in scope; the direction is parked — see § 6 | **parked** |

The full definition, including why `monitoring backend` is defined inside the `Target` entry
rather than on its own, is in [docs/GLOSSARY.md](docs/GLOSSARY.md).

A target faces **outward**: it receives rendered assertions. A *data source* faces inward and
supplied normalised series to the withdrawn evaluation role; with that role parked, nothing in
scope has an inward face, and the word survives only so that the parked argument stays
readable. What survives unconditionally is the rule that kept them two words:
[ADR-0002 § D18](docs/adr/0002-compatibility.md) — a requirement carries neither a target nor a
source — which the constitution's Principle VI now states directly.

---

## 4. What the walkthroughs established

*(the three walkthroughs are withdrawn with post-run evaluation: each traced a document through
R3 and R4, and the document they traced carries constructs the assertion-first format does not
have. The findings that survive are kept as clauses, because they were expensive to get and
none of them depends on the withdrawn roles. Tool facts are dated; the machinery is proposed.)*

8. *(binding, checked 2026-08-20)* An error-ratio predicate whose bad side is selected by the
   presence of an error attribute has no counterpart in a target whose selection is a
   conjunction of exact equalities over tags it actually emits. It is unrenderable, named, and
   reported before the run — clauses 4 and 5. There is no post-run path that quietly covers it.
9. *(binding, checked 2026-08-20)* A route is not emitted by the surveyed load generators; each
   carries a request name instead, defaulting in one case to the URL. Requirements written
   against a request name do not travel between targets. That is a declared cost of addressing,
   carried in each target's description, and the mechanism formerly proposed for reconstructing
   a route belonged to a withdrawn artifact and has no owner today.
10. *(binding)* Neither first target has a description in this repository yet. Producing them —
    dated and sourced, gaps declared — is a deliverable of the assertion-first feature itself,
    not of a later one. Until a target has a description, nothing in a document can be rendered
    for it, and saying so is cheaper than a reader assuming otherwise.
11. *(binding)* A target that cannot host assertions has no path in this format. That is a real
    loss against the previous design, in which such a tool was served completely after the run,
    and it is recorded here rather than absorbed: the admission rule in the constitution's
    Compatibility Constraints is what makes it so.
12. *(binding)* A predicate that is only violated when something goes wrong can be passed by a
    target that saw nothing at all. Verified for one surveyed target on 2026-08-20: a threshold
    on a selection that received no samples exits successful, and the target's own test suite
    pins that behaviour. Per clause 7 this MUST be declared in that target's description. A
    rendering may pair such a predicate with a companion assertion the target can fail — which
    is one predicate rendering into two assertions, expressly permitted by clause 4.
13. *(binding)* A statement about the run's conditions that rests on a quantity the target
    cannot measure is unrenderable and is named before the run. It never becomes a red run
    blamed on the system, and it never becomes a silent omission.
14. *(binding)* Two constructs are satisfiable by no surveyed target: a phase window, which
    rests on an attribute nothing emits, and a comparison against a previous run, which needs
    stored history no load generator provides. Under the constitution's admission rule these
    are not declared gaps but inadmissible, and they stay out until some target can assert them
    — which may be never.

---

## 5. Support is data

17. *(binding)* Support for a target is added as **data** — a description of that target — and
    requires changing no normative-core artifact, no existing document, and no reference
    implementation. A description says how the target names things, what it can assert, what it
    cannot, how its units convert, and where it can report success on absent data. This is
    [ADR-0002 § D12](docs/adr/0002-compatibility.md) with its artifact re-derived: D12's
    conclusion — a target list only maintainers can extend is not tool-agnostic — is why the
    rule exists, and D12's `kind: MetricMapping` was shaped for a path that ended in evaluation.
    D12 carries a dated supersession note; its argument stays readable.
18. *(binding)* A target's description declares what that target **cannot** do. An undeclared
    gap is a defect of the description, not of the format. A description that is silent about a
    capability is not asserting the target has it.

---

## 6. The monitoring direction

19. *(proposed, and explicitly unverified — dated 2026-08-18)* The same requirement document is
    claimed to reach a monitoring backend: a query that returns the canonical measurement, and
    that backend's native monitoring definition for the same criterion, across Datadog,
    Prometheus, VictoriaMetrics and InfluxDB.

**This claim has not been verified and nothing here demonstrates it.** No committed file in
this repository mentions any of those four products. The claim is owned by the parked
monitoring follow-up specification, whose status page lives at `docs/experimental/README.md`
and carries its promotion and retirement conditions. That area is outside the
compatibility-sensitive surface, holds markdown only, and **nothing outside it links into it** —
which is what makes it removable in one operation.

With the format now ending at a target's own assertions, this direction is further from scope
rather than nearer: a monitoring backend hosts no assertion, so the parked claim would have to
establish a second kind of path, not merely a second target.

20. *(binding)* Statements about the load generator do not survive the crossing. A statement
    that the run reached its intended load, or that the generator was not itself the
    bottleneck, is not applicable to production telemetry, and must be reported as
    unrenderable **by name** — never silently dropped so the rest of the document can go
    across without it. This is clause 4's sum rule applied at the crossing, and the crossing is
    where dropping one would be least visible.

---

## 7. The follow-up specifications

*(binding — later specifications must stay inside the boundaries below; a specification that
needs a role this document does not have amends this document first)*

21. *(binding)* Entries are named by **slug, never by ordinal**. `specs/NNN-` records the order
    specifications were *created*, not the order they must be *completed* —
    `001-nfr-format-architecture` already sets a numbering a reader will otherwise read as a
    schedule. Order comes from the dependency graph in § 7.2 and from nothing else.
22. *(binding)* The unit of claim is an **individual file**, not an artifact class. Several
    entries legitimately add to the normative core; no two claim the same file.

### 7.1 The entries

| Slug | Delivers | Depends on | Role | Scheduling |
|---|---|---|---|---|
| `core-schema` | `schema/opennfr.io/v1/requirementset.schema.json` and the common definitions it needs; one ADR fixing the field names | — | Substrate for R1 and R2 | **partly delivered** — the requirement schema has shipped. `evaluationreport.schema.json` is withdrawn with post-run evaluation; `indicator.schema.json` is withdrawn with `indicatorRef` |
| `target-description-schema` | the schema for a target's description: how it names things, what it can and cannot assert, how units convert, where it can report success on absent data | `core-schema` | Substrate for R2 | scheduled — supersedes the former `mapping-schema`; `metricmapping.schema.json` is withdrawn |
| `object-model` | the reference parser and its type declarations; `docs/object-model.md` | `core-schema` | **R1 Parse** | scheduled — without verdict or outcome types |
| `rendering-contract` | what a rendering is, and the corpus of *(document, target description, expected rendering)* triples any implementation in any language must reproduce | `core-schema`, `target-description-schema` | **R2 Render**, as a contract | scheduled — **nothing in this repository renders**; the implementation belongs to whoever integrates a target. Absorbs the former `renderer` and `conformance-corpus` |
| `target-gatling` | a Gatling target description and `docs/targets/gatling.md`, every claim dated and sourced | `target-description-schema` | A target, as data | scheduled — **serves the named customer**, and no longer waits on a renderer |
| `target-k6` | a k6 target description and `docs/targets/k6.md` | `target-description-schema` | A target, as data | scheduled — the second target is what makes portability checkable rather than claimed |
| `target-jmeter` | — | — | — | **withdrawn**. Scheduled on the strength of level `report`, which no longer exists. Whether the tool can host an assertion of the shape this format renders needs a fresh dated check before any entry returns |
| `ingest` | — | — | ~~R3~~ | **withdrawn with post-run evaluation** |
| `evaluation` | — | — | ~~R4~~ | **withdrawn with post-run evaluation**; `docs/evaluation.md` is parked with the argument, not deleted |
| `conformance-corpus` | — | — | — | **absorbed** into `rendering-contract`: what a conforming consumer must reach is a rendering, not an outcome |
| `mapping-schema` | — | — | — | **superseded** by `target-description-schema` |
| `monitoring-experiment` | everything under `docs/experimental/` | `core-schema` | Second target class | **parked — no position, see § 7.4** |

`docs/README.md` says the next step is *"A JSON Schema for the requirement and result
documents"*. Half of that has shipped and half is withdrawn: there is no result document, and
the sentence should be corrected where it lives rather than reinterpreted here.

### 7.2 The dependency graph

```text
assertion-first format
 ├─> core-schema (requirement schema already shipped)
 │    ├─> target-description-schema ─┬─> target-gatling
 │    │                              └─> target-k6
 │    ├─> object-model
 │    └─> rendering-contract  (also needs target-description-schema)
 └─> monitoring-experiment   (parked)
```

Nothing in that graph is a schedule. `target-gatling` is still the entry that should be
started first, because it is the only one with a counterparty waiting — and it now sits one
edge deep instead of three.

### 7.3 The answer owed to the named customer

23. *(binding)* `gatling-picatinny` is removing `assertionFromYaml` in 2.0 and has recorded
    that a replacement decision is needed. The entry that serves it is `target-gatling`, and
    the answer is **two-part**, because a decision that blocks a 2.0 release on work that does
    not exist is not an answer:
    - picatinny 2.0 removes `assertionFromYaml` **without** a one-to-one replacement, and its
      migration note documents that assertions are written with Gatling's native DSL. That
      unblocks 2.0 immediately.
    - The same migration note names OpenNFR as the intended successor: the format, a dated
      Gatling target description, and the rendering corpus that says what a correct rendering
      produces. The library that constructs Gatling assertion objects belongs to whoever
      integrates Gatling — nothing in this repository commits anyone to writing it, and the
      destination no longer waits on a component nobody has started.

    The first deliverable of `target-gatling` is the Gatling target description, which does not
    exist today — see clause 10.

### 7.4 The parked entry

24. *(proposed, unverified, dated 2026-08-18)* `monitoring-experiment` carries **no schedule
    position** — no milestone, no "after X". In its place it carries promotion conditions,
    retirement conditions and a date, all published in its own status page at
    `docs/experimental/README.md`. Promotion requires one unchanged requirement document
    assembling a valid query for **all four** named backends, each check dated and sourced.
    Three of four is not promotion; it is a narrower scope, and narrowing amends this document
    first.
