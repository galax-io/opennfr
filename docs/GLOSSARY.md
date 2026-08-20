# Glossary

> **These are notes, not rules.** Ideas about the format, kept for the arguments in them.
> The format itself is [FORMAT.md](../FORMAT.md); how it works is [ARCHITECTURE.md](../ARCHITECTURE.md).

Candidate vocabulary. The aim is one concept, one word — but these are proposals, not
settled terms, and several are still contested.

The most durable part of each entry is the *Rejected* note: an alternative that was
considered and dropped, with the reason. Those survive even when the preferred term
changes.

The reasoning behind each choice is in [ADR-0001](adr/0001-terminology.md).

> **Two kinds of entry live here, and they are not equally settled.** Some define terms the
> schema already carries, and `scripts/verify.sh` enforces those on every commit. Others argue
> for constructs the format does not have; nothing enforces them and they may be wrong. Where
> an entry sounds prescriptive, check whether the schema carries it — **the schema decides, not
> this file.**

---

## Layers

The organising idea: layers, each with its own vocabulary, with words never reused across
them. This is where the surveyed formats visibly break down, so it seems worth being strict
about — though the boundaries below are drawn by argument, not by experience.

```
       source of truth                        runtime
    ┌────────────────────┐      ┌──────────────────────────────┐
    │ Requirement        │──────│  the Target's own Assertion  │
    │   └─ Criterion     │ render                               the target
    │   └─ Guard         │──────│  + every predicate it could  │ runs it and
    └────────────────────┘      │    not render, named         │ decides
                                └──────────────────────────────┘
```

**There were three layers.** The third — verdicts, outcomes, a result document — described what
happened after the measurements arrived, and nothing in scope produces measurements any more.
Its vocabulary is parked at `docs/experimental/post-run-evaluation.md`, with the arguments
intact. The separation itself survives and is the reason the word *assertion* stays out of
Layer 1: see [Assertion](#assertion), and [ADR-0001 § D2](adr/0001-terminology.md).

The runtime box faces a [Target](#target) — a load generator. A monitoring backend hosts no
assertion, so it has no path here; that direction is parked.

---

## Layer 1. Requirements (what a human writes)

### RequirementSet

The root document, `kind: RequirementSet`. Holds a set of requirements.

A shared-`defaults` section is an idea the format does not have: it buys brevity and costs
merge semantics, and nobody has asked for it. The `gate` policy it used to hold is parked with
post-run evaluation.

Rejected: `Suite` — carries a testing connotation, whereas requirements outlive tests.
`Policy` — pulls towards OPA/Rego. `Profile` — will be needed later for environments.

### Requirement

A single human statement about the system ("checkout responds quickly under target load").
A container: it declares *what* is measured (`indicator`), *when* that is meaningful
(`guards`), and *which predicates* must hold (`criteria`).

A requirement is never rendered on its own — its criteria and guards are.

Rejected: `Objective` — taken by OpenSLO for a target with an error budget, which we do
not have. `NFR` — an acronym is unreadable as a field name.

### Criterion

One machine-checkable predicate over an indicator: aggregation + operator + threshold +
unit. The smallest unit of validation and the smallest unit of reporting.

A criterion becomes **exactly one entry** in the rendering: either the target's own assertions
for it, or a named statement that this target cannot express it. Never neither, and never both.
It may become more than one native assertion — a range a target spells as two comparisons, or a
companion assertion that stops the target passing on an empty selection — and that is not a
breach of the counting rule, which relates a criterion to a *bucket* and not to an assertion.

Rejected: `Assertion` — that is the runtime layer (see below). `Threshold` — that is just
the number inside a criterion, not the predicate. `Check` — too generic, and reserved for
the act of checking.

### Guard

Syntactically the same as a criterion; semantically a precondition — a statement that the
run happened in the intended regime at all.

A guard renders like a criterion, into the same kind of native assertion, and the target fails
the run on it like any other. **There is no third outcome**: no surveyed target has one, and a
construct nothing can honour would be a silent green of its own.

What tells a guard apart from a criterion is its entry in the rendering, which records both
that the entry is a guard and the identity the target derives its own report line from. It is
not told apart by a name in the target's report — see [criterionId](#criterionid) for why no
target has anywhere to put one.

The canonical case: "p95 < 500 ms" is only meaningful if the generator actually reached
200 rps. A run at 5 rps yields a green p95 and a false pass — a guard catches that. This is the
failure mode the whole project exists to address, which is why the construct stayed when the
outcome that used to express it went.

Rejected: `precondition` — verbose; `context` / `given` — fail to convey that this is a
checkable statement rather than metadata; `workload` — [reserved](#workload).

### Indicator

The definition of the measured quantity: metric name + selector + shape (`distribution`
or `ratio`). The counterpart of an SLI in OpenSLO. Declared inline. Reuse by reference (`indicatorRef`) is an idea the format does not have — it
is sugar, and it is unscreened against the admission rule.

Two shapes:

| Shape | When | Allowed aggregations |
|---|---|---|
| `distribution` | measuring the distribution of one metric's values | `p*`, `avg`, `min`, `max`, `count`, `rate`, `sum`, `stddev` |
| `ratio` | measuring a fraction: `bad`/`total` or `good`/`total` | `rate` (the fraction), `count` |

Rejected: `Metric` — the word is needed for the metric *name*. `SLI` — an acronym, and it
drags error-budget semantics along. `thresholdMetric` (OpenSLO) — collides with the
threshold value.

### metric

The metric name. **Strictly from OpenTelemetry semantic conventions**, or from our own
[`loadtest.*`](semconv/loadtest.md) registry. No custom names, no aliases.

A load generator is an HTTP client, so the canonical latency metric is
`http.client.request.duration` — not the server-side one and not a tool-specific one
(`http_req_duration` in k6 and friends). The correspondence between a target's names and the
document's is declared as data, outside the requirement, and consumed **outward** when the
document is rendered — see [Target description](#target-description). Not the format's job, and
no longer a step that reads a target's output.

### selector

Selects time series by OTel attributes. A map of attribute → value.

- `selector: {}` (empty) — all requests. This replaces picatinny's `all` key, explicitly.
- `error.type: "*"` — the attribute is present with any value.

**Addressing a request.** `http.route` is preferred: it is portable across tools and
correlates with the production metrics of the same service. Almost no load generator
emits it, however, so `loadtest.request.name` is an accepted fallback — the human-readable
request name (k6's `name` tag, Gatling's request name, JMeter's sampler label). It is the
worse option, not an equal one: such names are arbitrary and live inside a single tool.

**A request inside a group** is addressed by carrying both attributes on the same selection —
`loadtest.group.name` together with `loadtest.request.name`. This needs no second kind of
address and no new term, which matters because targets that nest requests in groups reach them
by a path, and a path parsed out of one string would be exactly the string DSL ADR-0001 § D4
forbids.

Rejected: `filter` (Keptn) — too generic; `tags` — k6 terminology; `scope` — already means
"visibility".

### aggregation

The statistic that reduces a series to a single number. A string enum:

```
avg | min | max | count | rate | sum | stddev
```

plus percentiles matching `^p\d{1,2}(\.\d+)?$` — `p50`, `p95`, `p99.9`.

This is still structure, not an expression: the pattern is validated by JSON Schema and
needs no parser.

`rate` over a `distribution` is throughput, derived rather than measured: there is no separate
"throughput" metric here and none in OTel either. The analogy is `rate(..._count[…])` in
Prometheus, and a surveyed target confirms the shape natively — Gatling asserts on mean
requests per second without a metric of that name existing (checked 2026-08-20).

**Not every member is screened.** The admission rule requires a surveyed target that can assert
a construct exactly, and `sum` has not been checked against one. It is in the enum because it
was there before the rule existed, which is a reason to check it rather than a reason to keep
it.

`avg` rather than `mean`: that is the spelling in all four reference formats.

### op

The comparison operator: `lt | lte | gt | gte | eq | neq`. As in OpenSLO.

Symbols (`<`, `<=`) are rejected: they validate poorly and require string parsing.

**Screening against the admission rule**, checked 2026-08-20: `lt`, `lte`, `gt`, `gte` and `eq`
each have an exact counterpart in both surveyed targets. **`neq` has one in neither** and is
unresolved — it predates the rule. In the other direction, range and set membership are
assertable by one target and are *admissible* on that strength, but admissibility is a floor,
not a licence, and neither is admitted.

### threshold and unit

`threshold` is a number (always `float64`; there are no decimal strings). `unit` is
**mandatory**.

The set of units is closed: a subset of UCUM given by enumeration — `ms`, `s`, `%`, `1`,
`By`, `{request}/s` and a few more. The full list and conversion rules are in
[units.md](units.md). A closed list validates as a schema `enum` and is implemented as a
conversion table rather than a UCUM grammar parser.

A mandatory unit settles the perennial "is 0.1 a fraction or a percentage?". OpenSLO
answers it with two separate fields (`target` / `targetPercent`); we answer it with one.

### Parked, and where the arguments went

Six entries left this file on 2026-08-21. None was rejected; each described something the
format cannot deliver, and the reasoning was worth more than the words.

| Term | Why it left | Where it is |
|---|---|---|
| `baseline` + `tolerance` | needs stored history of previous runs, which no load generator keeps | `docs/experimental/inadmissible-constructs.md` |
| `window` | `phase` rests on an attribute nothing emits; `rolling` was never screened and is recorded as unscreened | `docs/experimental/inadmissible-constructs.md` |
| `severity` | grades a violation for a policy that no longer exists | `docs/experimental/post-run-evaluation.md` |
| `enforcement` | its default, `post`, is unreachable; only one value would remain | `docs/experimental/post-run-evaluation.md` |
| `onViolation` | depends on `enforcement`. Its admission floor **is** met — one target aborts — so it waits on the field, not on a tool | `docs/experimental/post-run-evaluation.md` |
| `gate` | turns verdicts into an outcome, and nothing in scope produces either | `docs/experimental/post-run-evaluation.md` |

The paths are written as text rather than as links on purpose: nothing outside the experimental
area may link into it, or the one-operation removal test stops working.

**What did not leave:** [Guard](#guard). Preconditions stay in the format. Only the third
outcome that used to express a violated one went.

---

## Layer 2. Runtime

### Assertion

The projection of a criterion into a specific tool: a threshold in k6, an assertion in
Gatling, a post-processor in JMeter.

**The argument for keeping the word `assertion` out of the document itself:** an assertion
is a generated artifact, not a source of truth. The moment it enters the format, the format
is nailed to one tool's semantics. This is the single strongest constraint the notes have
produced so far, and the one most likely to hold.

**The tension with the admission rule, stated as an argument rather than a rule.** A construct
now enters the format only if some target can assert it exactly — so the format is bounded by
what assertions can express, while its words must still not be spelled the way any one target
spells them. Those pull in opposite directions and both are right: the first stops the format
promising what nothing can check, the second stops it becoming one tool's file with a different
extension.

### Target

The external product an adapter faces. Support is added by adding data, never by adding code.

A **load generator** produces the traffic, asserts against what it measured, reports, and
decides the run. It is the only class this format serves: a **monitoring backend** holds
telemetry and answers a query, but hosts no assertion, so it has no path here and that
direction is parked.

A target never reads a requirement document. It is reached through a
[Target description](#target-description), and *what* it can assert is declared there per
capability, each claim dated and sourced — never as a single level. The ladder that used to
grade targets is retired: see [ADR-0003](adr/0003-retire-conformance-levels.md).

A target faces **outward**: it receives rendered assertions. The opposite direction — a *data
source* facing inward — belonged to the withdrawn evaluation role and is parked with it. What
survives unconditionally is the rule that kept them two words:
[ADR-0002 § D18](adr/0002-compatibility.md), a requirement carries neither a target nor a
source, which the constitution's Principle VI now states directly.

`monitoring backend` is defined here rather than in an entry of its own because `backend`
already carried a different sense in this glossary — the thing that evaluated after the run.
That sense is parked, and the collision is recorded so it is not recreated.

Rejected: `consumer` — [AGENTS.md](../AGENTS.md) uses it for everything downstream of the
format, CI backends and human readers included, which is far wider than this. `tool` — it
excluded the monitoring class, which mattered when both were served; it is now the *narrower*
word and would be a fair name, but renaming a term to track a scope change is how a vocabulary
churns. `backend` on its own — collides, as above.

### Adapter

The component that binds the format to a specific target. It **renders**: it turns predicates
into that target's own assertions, and names every predicate it could not.

It used to do four things. Three of them — renaming metrics to canonical names, converting a
target's tags into attributes, collecting output — served the withdrawn ingest role and are
parked with it. Renaming and unit conversion survive only inasmuch as rendering needs them to
write an assertion the target will accept, which is why this entry is **narrowed rather than
replaced by a new word**: a rival term for a component that still exists would cost a reader
two names for one thing.

An adapter is **always** required, including for targets with built-in OTLP output: OTLP is a
transport, not a vocabulary, and no load generator publishes semconv names.

The **artifact** it produces is a [Rendering](#rendering); the component is this entry. Both
words are needed because the corpus pins the artifact while the architecture binds the
component.

### Rendering

What an adapter produces for one document and one target: the target's own assertions, plus
**every predicate it could not render, named, with a reason**. It is the format's output, and
the path stops there.

Two properties make it worth a word of its own:

- **It counts.** Every predicate lands in exactly one of the two lists. No third bucket, no
  silent remainder — that is where "nothing reports success by omission" is enforced now that
  no outcome vocabulary exists.
- **It attributes.** Each entry records the identity the target will derive its own report line
  from, and whether the entry states a condition of the run rather than a property of the
  system. That is the only way to tell a failed guard from a failed criterion in a target that
  has no field for a name.

Not a new concept: this repository already calls the act *render*, in the layer diagram above,
in `ARCHITECTURE.md`'s R2 role and in the specification. This names its output.

Rejected: `output` — says nothing about what it contains. `report` — belongs to the target,
which writes one, and using it here would put two documents under one word at the exact
boundary this format is drawn along.

### Target description

The data that says everything about one target: how it names things, **what it can assert and
what it cannot**, how its units convert, and where it can report success on absent data. Adding
a target is adding one of these — no change to the format, the schema, or any existing
document.

Two properties are load-bearing:

- **Capability and gaps partition each axis.** A combination declared in neither is a *defect
  of the description*, catchable mechanically. A description silent about a capability is not
  claiming the target has it.
- **Every claim carries a source and the date it was checked.** A capability claim is an
  assertion about somebody else's software; undated, it rots without anyone noticing.

It supersedes `kind: MetricMapping`, which named name-correspondence rather than capability and
whose ingest sections described a role the format no longer has.
[ADR-0002 § D12](adr/0002-compatibility.md) carries a dated note; its argument — that a target
list only maintainers can extend is not tool-agnostic — is why this exists at all.

Rejected: `capabilities` — names one of the four things it declares and silently demotes the
other three, and a file called *capabilities* that is mostly unit conversions reads as
misfiled. `tool profile` — names the tool rather than the description of it, which invites a
second file per tool and then a question about which is authoritative.

### Unrenderable criterion

A predicate the target cannot express **exactly**, carried by name and reason rather than
dropped.

The word exists to make one thing unspellable: a criterion that quietly produced nothing. Every
predicate is rendered or unrenderable, the two lists cover the document, and the report arrives
**before the run starts** rather than as a result.

Rejected: dropping it silently — a dropped criterion is a check that never ran and a run that
looks clean, which is the failure this project was founded on. Substituting the nearest thing
the target does have — an approximation is a silent green with a plausible number in it, and it
is worse than a gap because nobody goes looking for it.

### Display name

Free human-readable text, in any script, beside the machine identifier. On the document, on a
requirement, on a predicate. Optional everywhere.

It is **inert**: it changes nothing selected, measured, compared or rendered, and stripping
every display name from a document must leave every rendering byte-identical. An inert field
that is not *provably* inert acquires meaning.

Two things it must not do. It must not **restate a value the structured fields already carry** —
a name reading "99th percentile under 500 ms" beside `threshold: 500` is a second source for
one number, and they diverge the first time the threshold moves. And it does **not reach the
target's own report**: no surveyed target has a field for an author-chosen string, and a field
named this invitingly will otherwise be assumed to.

Rejected: `label` — in one surveyed tool a label *is* the sampler name, i.e. a selector value,
so the word already means an address here. `title` — collides with the document's own title and
with JSON Schema's `title`. `description` — invites paragraphs where a phrase is wanted.

---

## Layer 3 is gone

Verdicts, outcomes and a result document described what happened after the measurements
arrived. Nothing in scope produces measurements now — the target does, and it reports for
itself. The vocabulary is parked at `docs/experimental/post-run-evaluation.md`, with the
`noData` argument intact, because "missing data is an outcome in its own right" is the sentence
the whole project turns on and it outlived the enum it was written in.

### criterionId

A stable identifier for a predicate within a requirement. Equals the predicate's `name` if set,
otherwise its `aggregation`.

It is what a [Rendering](#rendering) points at, and it is the reason the counting rule can be
checked: two predicates sharing an identity would make the arithmetic meaningless before it was
ever evaluated. Uniqueness is required across a requirement's criteria **and** its guards
together, not per section — a guard and a criterion that both reduce by `rate` collide, and
that is the case a per-section check misses.

Indices (`criterion: 0`) are rejected: they break whenever the file is edited.

## Parsing rules

Proposed constraints on the input, should this get as far as a schema. The reasoning is in
[ADR-0002 § D16–D17](adr/0002-compatibility.md); the sketch is a subset of YAML rather than
YAML in general.

- **Every object maps one-to-one onto JSON.** Anchors, aliases and merge keys
  (`&`, `*`, `<<`) are forbidden: they do not survive the trip to JSON, are supported
  inconsistently across parsers, and destroy line numbers in error messages. Reuse would go through the `defaults` and `indicatorRef` ideas — neither of which the
  format has, and the bet that they cover the loss of anchors is untested
  ([ADR-0002 § D16](adr/0002-compatibility.md)).
- **An unknown field is an error.** A typo such as `agregation:` would, under lenient
  parsing, silently disable a criterion and turn the run green. That is the same silent
  lie as treating `noData` as success, and it is forbidden for the same reason.
- **The only extension point is `metadata.annotations`.** The `opennfr.io/` prefix is
  reserved for the format itself.
- **Multi-document (`---`) is allowed** as a container for several objects in one file.

---

## Reserved words

### workload

**Reserved; currently unused.**

If an executable load profile description (stages, arrival rate, duration) is added later,
that is what it must be called. This is why a requirement's applicability conditions are
named `guards` rather than `workload`/`context` — so the name is not consumed by the wrong
meaning.

A throughput requirement ("sustains ≥ 200 rps") is an ordinary `Requirement` with
`aggregation: rate` and needs no special mechanism. Not to be confused with a load profile.
