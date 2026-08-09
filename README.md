# OpenNFR

**An open format for non-functional requirements in load testing.**
Tool-agnostic, strictly parseable, built on OpenTelemetry semantic conventions.

> **Status: design stage.** Terminology and compatibility requirements are settled.
> There is no JSON Schema, validator or adapter yet — the examples illustrate naming and
> are not validated. Names may still change before `v1`.

---

## The problem

Every load testing tool can assert thresholds. None of them agree on how to express them:

```javascript
// k6
thresholds: { 'http_req_duration{name:checkout}': ['p(95)<500'] }
```
```yaml
# Taurus
- "p95 of Checkout>500ms, stop as failed"
```
```yaml
# Keptn
objectives: [{ sli: response_time_p95, pass: [{ criteria: ["<500"] }] }]
```

Three tools, three grammars, three metric vocabularies, three notions of "failure" — and
none of them survives a migration to another tool. Meanwhile the requirement itself
("checkout responds within 500 ms at 200 rps") outlives every tool you will ever use.

OpenNFR separates the requirement from the tool that happens to verify it.

## What it looks like

```yaml
apiVersion: opennfr.io/v1
kind: RequirementSet
metadata:
  name: checkout-perf
spec:
  requirements:
    - name: checkout-latency
      displayName: "Checkout responds quickly under target load"
      indicator:
        distribution:
          metric: http.client.request.duration    # OTel semconv name, not ours
          selector:
            http.request.method: POST
            http.route: /api/v1/checkout
      guards:                                     # violated -> inconclusive
        - { aggregation: rate, op: gte, threshold: 190, unit: "{request}/s" }
      criteria:                                   # violated -> fail
        - { aggregation: p95, op: lte, threshold: 500,  unit: ms, severity: blocker }
        - { aggregation: p99, op: lte, threshold: 1500, unit: ms, severity: warning }
```

The same document drives an assertion inside k6 *and* a post-run check in your backend.

## Three ideas that make it different

### 1. Metric names are not invented

A load generator **is** an HTTP client, so its latency metric is
`http.client.request.duration` — the name OpenTelemetry already gives it. Requests are
selected by OTel attributes (`http.route`, `http.request.method`, `error.type`), and run
identity uses `test.suite.name`, `cicd.pipeline.run.id`, `service.version`.

The payoff: a result report correlates with the traces of the very same run, with no glue.

### 2. `inconclusive` is a first-class outcome

A run that never reached its target load produces green thresholds and a false verdict.
This is the most common lie in load testing reports, and no existing format catches it.

`guards` are syntactically identical to criteria, but a violated guard yields
**`inconclusive`** — *"the test did not happen"* — rather than `fail` — *"the system does
not hold"*. Those are different engineering decisions, so they are different outcomes.
`noData` is likewise never silently green.

### 3. A new tool is a YAML file, not a fork

Tool integration is declared as data (`kind: MetricMapping`), not hardcoded. Note that
this is required **even for tools that already speak OTLP**: OTLP is a transport, not a
vocabulary — k6 emits `k6_http_req_duration` in milliseconds, while semconv wants
`http.client.request.duration` in seconds.

```yaml
kind: MetricMapping
metadata: { name: k6 }
spec:
  conformance: abort
  metrics:
    - from: k6_http_req_duration
      to: http.client.request.duration
      unit: { from: ms, to: s }
  attributes:
    - { from: name, to: loadtest.request.name }
```

## Conformance levels

Tools are not equal, and pretending otherwise promises what cannot be delivered.

| Level | What the adapter does | What it unlocks |
|---|---|---|
| `report` | maps metrics and attributes to canonical names | `enforcement: post` — **the entire format** |
| `assert` | also renders criteria into the tool's native assertions | `enforcement: inline` |
| `abort` | also stops the run on violation | `onViolation: abort` |

`report` is not a degraded mode: requirements, guards, baselines and reports all work
there. `assert` and `abort` only shorten the feedback loop. Hence the design rule —
**no construct may be expressible at `assert` and above only.**

| Tool | OTLP out | semconv names | Native assertions | Level |
|---|---|---|---|---|
| k6 | built-in (experimental) | no — `k6_*`, ms | `thresholds` | `abort` |
| Artillery | `publish-metrics` | no | `ensure` | `assert` |
| Gatling | Enterprise only | no | `assertions` | `assert` |
| Locust | official integration | no | code only | `report` |
| JMeter | none — JTL / listener | no | plugins only | `report` |

See [docs/compatibility.md](docs/compatibility.md) for details and sources.

## Documentation

Start with the [glossary](docs/GLOSSARY.md) — one concept, one word, with the rejected
synonyms spelled out.

| | |
|---|---|
| [docs/GLOSSARY.md](docs/GLOSSARY.md) | normative vocabulary |
| [docs/adr/0001-terminology.md](docs/adr/0001-terminology.md) | why each name was chosen |
| [docs/adr/0002-compatibility.md](docs/adr/0002-compatibility.md) | Go implementation and tool compatibility |
| [docs/semconv/loadtest.md](docs/semconv/loadtest.md) | the `loadtest.*` registry |
| [docs/units.md](docs/units.md) | the closed unit list |
| [docs/compatibility.md](docs/compatibility.md) | conformance levels, tool matrix |
| [docs/references.md](docs/references.md) | what was taken from OpenSLO, Keptn, k6, Taurus, SLA4OAI |
| [docs/examples/](docs/examples/) | `RequirementSet`, `EvaluationReport`, `MetricMapping` |

## Relation to OpenSLO

OpenNFR is not a competitor to [OpenSLO](https://github.com/OpenSLO/OpenSLO) — it is its
counterpart on the other side of the release.

| | OpenSLO | OpenNFR |
|---|---|---|
| Subject | a service in production | a single load test run |
| Time frame | rolling window, weeks | one run, minutes |
| Core concept | error budget | pass / fail gate for CI |
| Answers | "are we spending reliability too fast?" | "may this build ship?" |

The k8s-style envelope, `op` values and the SLI/SLO split are deliberately borrowed so
that the two read alike.

## Status and open questions

Nine open questions are tracked in the ADRs — baseline modes, histogram resolution,
`errorSignal` expressiveness, and whether an executable `workload` block belongs in scope
at all. The next artifact is the JSON Schema for `RequirementSet` and `EvaluationReport`;
it will force several of them shut.

Naming discussions belong in issues. The vocabulary is deliberately narrow, and adding a
word is a change to the format.

## License

[Apache License 2.0](LICENSE)
