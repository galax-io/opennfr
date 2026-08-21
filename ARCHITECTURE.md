# Architecture

How a requirement becomes an outcome, what each component on that path may not know, and how
the format reaches a tool at all.

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

A requirement is written once, by a human, and names no tool. Everything else happens to it.

```text
requirement ── criterion ──> verdict ──> gate ──> outcome
     │             │            ▲                    │
     │             │            │                    └─ what a CI job prints
     │             └─ rendered into a target's native form (R2)
     └─ parsed into an object model (R1)
                                │
        a target's raw output ──┴── normalised into series (R3), evaluated (R4)
```

1. *(binding)* The path ends at **outcome**, not at verdict. A `Verdict` is the result of
   checking one criterion or guard; an `Outcome` is the aggregated result of the whole run.
   A trace that stops at verdict stops one component short of `gate`. See
   [docs/GLOSSARY.md](docs/GLOSSARY.md).
2. *(binding)* No role may read the requirement document to discover its data source. The
   source is a parameter of evaluation, never a property of the requirement —
   [ADR-0002 § D18](docs/adr/0002-compatibility.md).
3. *(binding)* No construct may be checkable only while a run is in progress. Anything
   expressible must also be evaluable afterwards, or the format silently excludes every tool
   that cannot assert inline. This is already a ratified constitutional constraint.

---

## 2. The four component roles

Roles are contracts, not modules. Two of them — Render and Ingest — are **sub-roles of the
glossary's `Adapter`**, not rivals to it: the glossary already defines an `Adapter` as doing
four jobs, of which rendering assertions is one and collecting a tool's output is another.
Introducing a competing decomposition of the same pipeline is what
[Principle I](.specify/memory/constitution.md) forbids.

The original request called these *interpreters*. In this repository's vocabulary that word is
`Adapter`; `interpreter` is not used.

| # | Role | Input | Output | MUST NOT know | Status |
|---|---|---|---|---|---|
| R1 | Parse | One document | An object model, or a parse error naming the field and its line | Which target will consume the result | **binding** |
| R2 | Render *(Adapter)* | Criteria + one tool mapping | The target's native artifact, **plus a named list of every criterion it could not render** | Whether the run will pass | **binding** |
| R3 | Ingest *(Adapter)* | A target's raw output + one tool mapping | Normalised series under canonical names, in canonical units | What the criteria say | **binding** |
| R4 | Evaluate | Normalised series, criteria, guards, `gate` | One verdict per criterion and guard, then one outcome | Which target produced the measurements, or how | **binding** |

**R4 is [Principle VI](.specify/memory/constitution.md)** *(binding)*, and it is the only
reason one document can mean one thing across many targets. Its sharpest consequence: a
statistic the target already computed — k6's own p95 — must not be consumed as a verdict. The
moment it is, the verdict depends on that tool's percentile machinery.

**R3 is where units are converted** *(binding)*. The survey records tools reporting
milliseconds where semantic conventions require seconds. An error here is three orders of
magnitude wide and produces a confident, wrong, green result, which is why the conversion is
declared in the mapping rather than left to whoever implements the role.

**Naming** *(binding)*: R3 is the **file adapter** where it reads files. It is not called a
*reader* — in this project's documents `reader` means a human.

### What no role may do

4. *(binding)* A criterion is either rendered or reported unrenderable **by criterion
   identity**. Dropping one silently is forbidden: a dropped criterion is a check that never
   ran and a result that looks clean.
5. *(binding)* When a target cannot honour a construct, the result is a **named failure** —
   never a substitution, an approximation, or a silent omission. The gap is declared in the
   mapping and surfaces at render time, before the run rather than after it.
6. *(binding)* A measurement taken at one vantage point may not stand in for one taken at
   another. A load generator measures latency as a client; a production stack usually measures
   it as a server. The numbers are not comparable.
7. *(binding)* Missing data produces `noData` and a violated guard produces `inconclusive`.
   Neither is a pass. [Principle III](.specify/memory/constitution.md).

---

## 3. Targets

*(binding)* A **target** is the external product an adapter faces. Two classes, supported
identically — by adding data, never by adding code:

| Class | What it does | Can host assertions? | Status |
|---|---|---|---|
| Load generator | Produces the traffic and reports what happened | Sometimes, at conformance level `assert` and above | **binding** |
| Monitoring backend | Holds telemetry, answers a query, can host a standing monitor | Not applicable — see § 6 | **proposed** |

The full definition, including why `monitoring backend` is defined inside the `Target` entry
rather than on its own, is in [docs/GLOSSARY.md](docs/GLOSSARY.md). A target faces **outward**; a
*data source* faces inward and supplies normalised series to R4. One product may play both
roles in one run, in which case it is named by the role it is playing. This document cites
[ADR-0002 § D18](docs/adr/0002-compatibility.md) for `data source` rather than redefining it.

---

## 4. Three walkthroughs

*(proposed — none of the machinery exists; the tool facts are dated)*

One document, unchanged in every character:
[docs/examples/checkout-perf.yaml](docs/examples/checkout-perf.yaml). It carries five requirements, two
guards, and a `gate`. Every tool statement below comes from this repository's own survey in
[docs/compatibility.md](docs/compatibility.md), *"Verified against documentation as of August 2026"*, or
from the mapping sketches in `examples/`. Nothing here is asserted from outside those files.

### 4.1 k6 — the best case

Conformance **`abort`**: OTLP output built in, native `thresholds`, `abortOnFail`.

| Requirement | R2 renders | R3 ingests | Result |
|---|---|---|---|
| `checkout-throughput` | `rate` over the histogram count | `k6_http_req_duration` → `http.client.request.duration`, **ms → s** | works |
| `checkout-latency` p95/p99 | `p(95)`, `p(99)` thresholds; `onViolation: abort` → `abortOnFail` | same metric | works |
| guard `generator-not-saturated` | — (guards are evaluated post-run) | `k6_dropped_iterations` → `loadtest.dropped_iterations` | works |
| `checkout-error-rate` | **cannot render** | `k6_http_req_failed` via `errorSignal` | **gap** |
| `no-latency-regression` | **cannot render** | — | **gap** |

**Declared gaps** *(binding that they are declared, proposed how)*:

8. *(binding)* The ratio indicator cannot become a k6 threshold. `mapping-k6.yaml` renders selectors as k6
   tags (`selectorAs: tag`), and `error.type` is not a tag — it is derived from a separate
   metric through `errorSignal`. Evaluation post-run is unaffected; only the inline rendering
   is impossible. Per clause 4, R2 reports it rather than dropping it.
9. *(binding)* `http.route` is not emitted by k6. The mapping carries k6's `name` tag to
   `loadtest.request.name`, and reconstructing a route needs `routeHints` — a field of
   `kind: MetricMapping` sketched in `examples/mapping-jmeter.yaml`, not specific to JMeter.
   Requirements written against `loadtest.request.name` do not travel between tools.

### 4.2 Gatling — the case with a named customer and no mapping

Conformance **`assert`**: native `assertions`, **no abort**, and OTLP only in the Enterprise
Edition — the open-source build goes through `simulation.log`.

10. *(binding)* **There is no `mapping-gatling.yaml`.** `examples/` holds mappings for k6 and JMeter only.
    This walkthrough is therefore traced from the survey alone, and producing the mapping is the
    first deliverable of the `target-gatling` follow-up specification. Until it exists, no
    criterion in the example document can actually be rendered for Gatling.

| Construct | Status against the survey |
|---|---|
| Latency, throughput | Response time is recorded; canonical naming needs the missing mapping |
| `onViolation: abort` | **Impossible** — the survey records Abort: `no` for Gatling |
| guard on `loadtest.dropped_iterations` | **No equivalent** — the mapping table in [docs/semconv/loadtest.md](docs/semconv/loadtest.md) records an em-dash |
| Error signal | `KO` carries it |
| `http.route` | Reconstructed by an adapter, per the survey — which does not exist yet |

### 4.3 JMeter — the worst case, and still complete

Conformance **`report`**: no OTLP output, no native assertions, no abort. The path is JTL files
through R3.

11. *(binding)* `report` is **not a degraded mode**. Every requirement in the example document
    is evaluable after the run: R2 renders nothing, reports all criteria as unrenderable per
    clause 4, and R4 produces the same verdicts it would for k6. `assert` and `abort` shorten
    the feedback loop; they add no expressiveness. This is why the format may contain no
    construct expressible only at `assert` or above.

| Construct | Status |
|---|---|
| Latency | `elapsed` (**ms**), `Latency` ≈ TTFB only |
| `http.request.method` | **Not in the mapping** — `mapping-jmeter.yaml` maps `label`, `responseCode` and `URL` only. `checkout-latency`'s method selector cannot be satisfied as mapped |
| `http.route` | Via `routeHints`, manually maintained |
| `loadtest.dropped_iterations` | **No equivalent** |
| Native assertions, abort | **None** |

### 4.4 What the walkthroughs expose about the example itself

*(binding that these are declared; each needs its own issue — fixing them changes the format,
which this feature does not do)*

12. *(binding)* **`overall-availability` can produce a silent RED.** A run in which nothing fails yields no
    series carrying `error.type`, hence `noData`, hence `onNoData: fail`. The run fails because
    the system was perfect.
13. *(binding)* **An unmeasurable guard fails for the wrong reason.** Gatling and JMeter cannot measure
    `loadtest.dropped_iterations`, so the guard lands on `onNoData: fail` rather than
    `onGuardViolation: inconclusive`, and a tool limitation reads as a system failure.
14. *(binding)* **`skipped` has no gate key.** It appears in the status enum and in the report sketch, but
    no `gate` key handles it. Silence is undefined behaviour in a project whose Principle III
    forbids exactly that.
15. *(binding)* **`indicatorRef: checkout-latency` points at a Requirement name**, while ADR-0001 § D10 and
    the glossary describe `Indicator` as a reusable kind of its own.
16. *(binding)* **Two constructs are satisfiable by no tool in the survey**: `window.phase` rests on
    `loadtest.phase`, which nothing emits, and `baseline: previousPassed` needs stored history
    no load generator provides. Both are core constructs with a published dependency.

---

## 5. Support is data

17. *(binding)* Support for any target is added as **data** — a `kind: MetricMapping` document
    — and requires changing no normative-core artifact and no reference implementation. This is
    [ADR-0002 § D12](docs/adr/0002-compatibility.md), generalised to both target classes by
    [the constitution's Compatibility Constraints](.specify/memory/constitution.md).
18. *(binding)* A mapping declares what its target **cannot** do. An undeclared gap is a defect
    of the mapping, not of the format.

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

20. *(binding)* Preconditions about the load generator do not survive the crossing. A guard on
    `loadtest.dropped_iterations` is not applicable to production telemetry and must be reported
    as such by name, never silently dropped so the requirement can be evaluated without it.


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
| `core-schema` | `schema/opennfr.io/v1/common.schema.json`, `requirementset.schema.json`, `indicator.schema.json`, `evaluationreport.schema.json`, one ADR fixing the field names | — | Substrate for all four roles | scheduled |
| `mapping-schema` | `schema/opennfr.io/v1/metricmapping.schema.json` | `core-schema` | Substrate for R2 and R3 | scheduled |
| `object-model` | The reference parser and its type declarations; `docs/object-model.md` | `core-schema` | **R1 Parse** | scheduled |
| `ingest` | The normalised-series contract and the file adapter | `object-model`, `mapping-schema` | **R3 Ingest** | scheduled |
| `evaluation` | The verdict and gate engine; `docs/evaluation.md` | `object-model` | **R4 Evaluate** | scheduled |
| `renderer` | The criterion-to-native-artifact renderer and its unrenderable report | `object-model`, `mapping-schema` | **R2 Render** | scheduled |
| `target-gatling` | `mappings/gatling.yaml`, `docs/targets/gatling.md` | `renderer` | A target, as data | scheduled — **serves the named customer** |
| `target-k6` | `mappings/k6.yaml`, `docs/targets/k6.md` | `renderer` | A target, as data | scheduled |
| `target-jmeter` | `mappings/jmeter.yaml`, `docs/targets/jmeter.md` | `ingest` | A target, as data | scheduled |
| `conformance-corpus` | `conformance/` — documents paired with the outcome any conforming consumer must reach | `core-schema`, `evaluation` | Cross-cutting; also the first artifact able to detect cross-repository drift | scheduled |
| `monitoring-experiment` | Everything under `docs/experimental/` | `core-schema` | Second target class | **parked — no position, see § 7.4** |

`docs/README.md` says the next step is *"A JSON Schema for the requirement and result
documents"*. That names `core-schema` exactly, and it stays true: it is first in dependency
order, and the other ten were always implied by it, because a schema with nothing reading it
changes nothing.

### 7.2 The dependency graph

```text
001 (this feature)
 ├─> core-schema
 │    ├─> mapping-schema ──┐
 │    ├─> object-model ────┼─> ingest ──────> target-jmeter
 │    │      ├─────────────┴─> renderer ────> target-gatling
 │    │      │                          └───> target-k6
 │    │      └─> evaluation ─┐
 │    └────────────────────  ┴─> conformance-corpus
 └─> monitoring-experiment   (parked)
```

Nothing in that graph is a schedule. `target-gatling` sits three edges deep and is still the
entry that should be started first, because it is the only one with a counterparty waiting.

### 7.3 The answer owed to the named customer

23. *(binding)* `gatling-picatinny` is removing `assertionFromYaml` in 2.0 and has recorded
    that a replacement decision is needed. The entry that serves it is `target-gatling`, and
    the answer is **two-part**, because a decision that blocks a 2.0 release on work that does
    not exist is not an answer:
    - picatinny 2.0 removes `assertionFromYaml` **without** a one-to-one replacement, and its
      migration note documents that assertions are written with Gatling's native DSL. That
      unblocks 2.0 immediately.
    - The same migration note names OpenNFR's `target-gatling` as the intended successor once
      `renderer` lands, so the removal is a deprecation with a destination rather than a hole.

    The first deliverable of `target-gatling` is the Gatling mapping that does not exist today
    — see clause 10.

### 7.4 The parked entry

24. *(proposed, unverified, dated 2026-08-18)* `monitoring-experiment` carries **no schedule
    position** — no milestone, no "after X". In its place it carries promotion conditions,
    retirement conditions and a date, all published in its own status page at
    `docs/experimental/README.md`. Promotion requires one unchanged requirement document
    assembling a valid query for **all four** named backends, each check dated and sourced.
    Three of four is not promotion; it is a narrower scope, and narrowing amends this document
    first.
