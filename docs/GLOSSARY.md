# Glossary

Candidate vocabulary. The aim is one concept, one word — but these are proposals, not
settled terms, and several are still contested.

The most durable part of each entry is the *Rejected* note: an alternative that was
considered and dropped, with the reason. Those survive even when the preferred term
changes.

The reasoning behind each choice is in [ADR-0001](adr/0001-terminology.md).

> Where an entry sounds prescriptive ("mandatory", "forbidden"), read it as the shape the
> rule would take if this design is kept — none of it is enforced by anything, because
> there is no schema and no implementation.

---

## Layers

The organising idea: three layers, each with its own vocabulary, with words never reused
across them. This is where the surveyed formats visibly break down, so it seems worth being
strict about — though the boundaries below are drawn by argument, not by experience.

```
       source of truth                runtime                      result
    ┌────────────────────┐      ┌──────────────┐      ┌────────────────────────┐
    │ Requirement        │──────│  Assertion   │      │ Verdict → Outcome      │
    │   └─ Criterion     │ render               evaluate                        │
    │   └─ Guard         │──────│ (k6/Gatling) │──────│ EvaluationReport       │
    └────────────────────┘      └──────────────┘      └────────────────────────┘
```

---

## Layer 1. Requirements (what a human writes)

### RequirementSet

The root document, `kind: RequirementSet`. Holds a set of requirements, shared `defaults`
and the `gate` policy.

Rejected: `Suite` — carries a testing connotation, whereas requirements outlive tests.
`Policy` — pulls towards OPA/Rego. `Profile` — will be needed later for environments.

### Requirement

A single human statement about the system ("checkout responds quickly under target load").
A container: it declares *what* is measured (`indicator`), *when* that is meaningful
(`guards`), and *which predicates* must hold (`criteria`).

A requirement is never evaluated on its own — its criteria are.

Rejected: `Objective` — taken by OpenSLO for a target with an error budget, which we do
not have. `NFR` — an acronym is unreadable as a field name.

### Criterion

One machine-checkable predicate over an indicator: aggregation + operator + threshold +
unit. The smallest unit of validation and the smallest unit of reporting.

A violated criterion means the system does not meet the requirement → `fail`.

Rejected: `Assertion` — that is the runtime layer (see below). `Threshold` — that is just
the number inside a criterion, not the predicate. `Check` — too generic, and reserved for
the act of checking.

### Guard

Syntactically the same as a criterion; semantically a precondition — a statement that the
run happened in the intended regime at all.

A violated guard means **no conclusion about the system was reached** → `inconclusive`,
neither `fail` nor `pass`.

The canonical case: "p95 < 500 ms" is only meaningful if the generator actually reached
200 rps. A run at 5 rps yields a green p95 and a false verdict — a guard catches that.

Rejected: `precondition` — verbose; `context` / `given` — fail to convey that this is a
checkable statement rather than metadata; `workload` — [reserved](#workload).

### Indicator

The definition of the measured quantity: metric name + selector + shape (`distribution`
or `ratio`). The counterpart of an SLI in OpenSLO. Declared inline (`indicator`) or reused
by reference (`indicatorRef`).

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
(`http_req_duration` in k6 and friends). Reducing tool-specific names to canonical ones is
the adapter's job, not the format's.

### selector

Selects time series by OTel attributes. A map of attribute → value.

- `selector: {}` (empty) — all requests. This replaces picatinny's `all` key, explicitly.
- `error.type: "*"` — the attribute is present with any value.

**Addressing a request.** `http.route` is preferred: it is portable across tools and
correlates with the production metrics of the same service. Almost no load generator
emits it, however, so `loadtest.request.name` is an accepted fallback — the human-readable
request name (k6's `name` tag, Gatling's request name, JMeter's sampler label). It is the
worse option, not an equal one: such names are arbitrary and live inside a single tool.

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

`rate` over a `distribution` equals `count / window duration`, i.e. exactly
`rate(..._count[…])` in Prometheus. There is no separate "throughput" metric — OTel has
none either, because it is always derived.

`avg` rather than `mean`: that is the spelling in all four reference formats.

### op

The comparison operator: `lt | lte | gt | gte | eq | neq`. As in OpenSLO.

Symbols (`<`, `<=`) are rejected: they validate poorly and require string parsing.

### threshold and unit

`threshold` is a number (always `float64`; there are no decimal strings). `unit` is
**mandatory**.

The set of units is closed: a subset of UCUM given by enumeration — `ms`, `s`, `%`, `1`,
`By`, `{request}/s` and a few more. The full list and conversion rules are in
[units.md](units.md). A closed list validates as a schema `enum` and is implemented as a
conversion table rather than a UCUM grammar parser.

A mandatory unit settles the perennial "is 0.1 a fraction or a percentage?". OpenSLO
answers it with two separate fields (`target` / `targetPercent`); we answer it with one.

### baseline and tolerance

Comparison against a previous run instead of an absolute threshold. Mutually exclusive
with `threshold`.

```yaml
- aggregation: p95
  op: lte
  baseline: { source: previousPassed }
  tolerance: { value: 10, unit: "%" }
```

Reads as "p95 is no more than 10 % worse than the baseline". The direction of the
tolerance follows from `op` (`lte` — upwards, `gte` — downwards), so strings like
`"<=+10%"` (Keptn) are unnecessary.

`tolerance.unit` may be `%` (relative) or the metric's own unit (absolute, e.g. `50 ms`).

### window

Where in time the measurement is taken.

```yaml
window:
  phase: steady     # rampUp | steady | rampDown | full
  rolling: 1m       # optional — a rolling window instead of one aggregate per phase
```

`phase` rests on the `loadtest.phase` attribute and solves the everyday nuisance: not
counting ramp-up and ramp-down.

Rejected: `timeWindow` (OpenSLO) — redundant; `interval`, `period` — vague.

### severity

How serious a criterion violation is: `blocker | warning | info`. Feeds the outcome
through `gate`.

Three levels, not four: in practice nobody distinguishes a `critical` sitting between
`blocker` and `warning`.

### enforcement

Where a criterion is checked:

| Value | Meaning |
|---|---|
| `post` | computed by the backend after the run from collected metrics (**default**) |
| `inline` | rendered into the tool's assertion and checked during the run |
| `both` | both of the above |

`post` is the default because it is achievable for every tool. `inline` is an adapter
capability: k6 and Taurus have it, Gatling and JMeter only partly.

### onViolation

For `enforcement: inline` only: `continue` (default) | `abort` — stop the run. Maps to
k6's `abortOnFail` and Taurus's `stop as failed`.

### gate

The policy that turns many verdicts into a single run outcome.

```yaml
gate:
  onBlocker: fail
  onWarning: warn
  onInfo: ignore
  onNoData: fail              # silence is not success
  onGuardViolation: inconclusive
```

---

## Layer 2. Runtime

### Assertion

The projection of a criterion into a specific tool: a threshold in k6, an assertion in
Gatling, a post-processor in JMeter.

**The argument for keeping the word `assertion` out of the document itself:** an assertion
is a generated artifact, not a source of truth. The moment it enters the format, the format
is nailed to one tool's semantics. This is the single strongest constraint the notes have
produced so far, and the one most likely to hold.

### Adapter

The component that binds the format to a specific tool. It does four things: renames
metrics to canonical names, converts units, renames the tool's tags into OTel attributes,
and — at level `assert` and above — renders criteria into native assertions.

An adapter is **always** required, including for tools with built-in OTLP output: OTLP is
a transport, not a vocabulary, and no load generator publishes semconv names. See
[compatibility.md](compatibility.md).

### MetricMapping

`kind: MetricMapping` — the declarative table mapping a tool's names onto canonical ones.
Data, not code: supporting a new tool means adding a YAML file.

Contains `metrics` (with unit conversion), `attributes`, `errorSignal` and — for the
`assert`/`abort` levels — an `assertions` section. Examples:
[k6](examples/mapping-k6.yaml), [JMeter](examples/mapping-jmeter.yaml).

### Conformance level

How deeply a tool is integrated. Cumulative levels:

| Level | What the adapter does | What it unlocks |
|---|---|---|
| `report` | maps metrics and attributes to canonical names | `enforcement: post` — **the entire format** |
| `assert` | also renders native assertions | `enforcement: inline`, `both` |
| `abort` | also stops the run | `onViolation: abort` |

`report` is not a degraded mode but a complete one: `assert` and `abort` merely shorten
the feedback loop. Hence the rule: no construct is added to the format if it is
expressible at `assert` and above only.

---

## Layer 3. Result

### Verdict

The result of checking **one** criterion or guard.

`status`: `pass | warn | fail | noData | skipped`

`noData` is mandatory and is not a success: missing data is an outcome in its own right,
not a silent green.

### criterionId

A stable identifier for a criterion within a requirement, used for references from the
report. Equals the criterion's `name` if set, otherwise its `aggregation` value (in which
case two criteria with the same aggregation and no `name` are forbidden).

Indices (`criterion: 0`) are rejected: they break whenever the file is edited.

### Outcome

The aggregated result of the whole run: `pass | warn | fail | inconclusive`.

`inconclusive` is a first-class outcome, not a special case of `fail`. It means "the test
did not happen", which is a fundamentally different engineering decision from "the system
does not hold".

### EvaluationReport

The format's second normative schema, `kind: EvaluationReport`. Without it the promise
"parses into any backend" is unmet — a backend needs a standard output, not only an input.

Run identity is described by **existing** OTel attributes — `test.suite.name`,
`cicd.pipeline.run.id`, `service.name`, `service.version`,
`deployment.environment.name` — which is what lets a report correlate with the traces of
that run without glue.

---

## Parsing rules

Proposed constraints on the input, should this get as far as a schema. The reasoning is in
[ADR-0002 § D16–D17](adr/0002-compatibility.md); the sketch is a subset of YAML rather than
YAML in general.

- **Every object maps one-to-one onto JSON.** Anchors, aliases and merge keys
  (`&`, `*`, `<<`) are forbidden: they do not survive the trip to JSON, are supported
  inconsistently across parsers, and destroy line numbers in error messages. Reuse goes
  through `defaults` and `indicatorRef`.
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
