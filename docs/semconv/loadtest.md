# Sketch: a `loadtest.*` registry

> **These are notes, not rules.** Ideas about the format, kept for the arguments in them.
> **An idea, not a rule.** This is a proposal written in semantic-convention style and nothing
> more. It is not an OpenTelemetry standard, it has been submitted nowhere, and **nothing emits
> these names today**. The `loadtest.` namespace merely appeared to be unclaimed upstream at the
> time of writing. Last true as written: 2026-08-18.

What an OpenTelemetry semantic conventions extension for load testing might contain — the part
this format would have to coin, because semconv covers everything else already.

The names OpenTelemetry does cover, and which a document should actually use, are reference
rather than proposal and live outside this directory, in `reference/names.md`. What remains
here is only what has no upstream equivalent.

Two names below — `loadtest.request.name` and `loadtest.group.name` — are already used by the
validated corpus at `examples/six-statements.yaml`, which makes them the one place the format
leans on something no standard carries. That debt is recorded in `reference/names.md`.

## Principles

1. **Look in OTel first.** A name of our own is coined only when semconv has no equivalent.
   Everything OTel covers is used verbatim, without renaming or aliases.
2. **No derived quantities.** Throughput, error rate, apdex — all computed from existing
   metrics by aggregation. They exist neither in OTel nor here.
3. **semconv style.** Dotted namespaces, UCUM units, annotated units in braces, metrics as
   nouns, attributes ordered general to specific.

---

## Defined here

### Metrics

| Name | Type | Unit | Description |
|---|---|---|---|
| `loadtest.vus` | UpDownCounter | `{vu}` | active virtual users |
| `loadtest.iterations` | Counter | `{iteration}` | completed scenario iterations |
| `loadtest.iteration.duration` | Histogram | `s` | duration of one scenario iteration |
| `loadtest.dropped_iterations` | Counter | `{iteration}` | iterations not started because the generator ran out of resources — the signal that the generator itself became the bottleneck |

`loadtest.dropped_iterations` is a textbook `guards` candidate: if the generator could not
keep up, no conclusion about the system may be drawn.

#### HTTP request phases

OTel provides only the total duration. Breaking it down by phase is a standard diagnostic
in load testing (slow TTFB and slow body transfer are different diagnoses), so we define
our own. All are Histograms with unit `s`.

| Name | What it measures |
|---|---|
| `loadtest.http.connect.duration` | establishing the TCP connection |
| `loadtest.http.tls.duration` | the TLS handshake |
| `loadtest.http.request.send.duration` | sending the request |
| `loadtest.http.response.wait.duration` | waiting for the first response byte (TTFB) |
| `loadtest.http.response.receive.duration` | receiving the response body |

Support is partial and tool-dependent: k6 provides all five; JMeter's JTL yields only
`Latency` (≈ TTFB) and `Connect`.

### Attributes

| Attribute | Type | Values | Description |
|---|---|---|---|
| `loadtest.phase` | string | `rampUp` \| `steady` \| `rampDown` | the run phase. The foundation of `window.phase` — it lets you exclude ramp-up and ramp-down |
| `loadtest.request.name` | string | | the human-readable request name: k6's `name` tag, Gatling's request name, JMeter's sampler label. **Fallback addressing** when `http.route` is unavailable — see below |
| `loadtest.scenario.name` | string | | the scenario within the run |
| `loadtest.group.name` | string | | a logical group of requests (Gatling group, k6 group) |
| `loadtest.tool.name` / `.version` | string | `k6`, `gatling`, `jmeter` | the generator tool |
| `loadtest.injector.id` | string | | the generator node in a distributed run |

### Addressing: `http.route` versus `loadtest.request.name`

`loadtest.request.name` is the direct replacement for picatinny's `MyGroup / MyRequest` keys and
k6's `{name:...}` tag — the human-readable name of a request, for the case where no route exists
in principle.

The rule for choosing between the two is settled and is reference rather than proposal:
`reference/names.md` carries it, and it is not repeated here.

---

## Deliberately absent

| Not defined | Why |
|---|---|
| `loadtest.throughput` / `rps` | derived: `aggregation: rate` over a histogram's `count`, exactly like `rate(..._count[…])` in Prometheus |
| `loadtest.error_rate` | derived: a `bad: {error.type: "*"}` fraction over requests that already exist |
| `loadtest.response_time` | a duplicate of `http.client.request.duration` |
| `loadtest.apdex` | a composite metric, expressible as a set of criteria |
| `loadtest.run.id` | `cicd.pipeline.run.id` and `test.suite.name` already exist |

---

## Mapping from tools

Reduction to canonical names is the adapter's job, and it is declared through a
[`kind: MetricMapping`](../examples/mapping-k6.yaml) object rather than baked into code.

**No tool publishes semconv names by itself.** The OTLP output in k6, Locust, Artillery and
Gatling Enterprise is a transport, not a vocabulary: k6 emits `k6_http_req_duration` with a
configurable prefix. An adapter is therefore always required. Details and the full matrix
are in `reference/compatibility.md`.

For orientation:

| OpenNFR (canonical) | k6 | Gatling | JMeter (JTL) |
|---|---|---|---|
| `http.client.request.duration` | `http_req_duration` (**ms**) | response time | `elapsed` (**ms**) |
| `loadtest.http.response.wait.duration` | `http_req_waiting` | — | `Latency` |
| `loadtest.request.name` | the `name` tag | request name | `label` |
| `http.route` | reconstructed by the adapter | reconstructed by the adapter | manual only |
| `error.type: "*"` | `http_req_failed == 1` | KO | `success == false` |
| `loadtest.vus` | `vus` | active users | `allThreads` |
| `loadtest.iteration.duration` | `iteration_duration` (**ms**) | — | transaction controller |
| `loadtest.dropped_iterations` | `dropped_iterations` | — | — |

Bold marks the places needing unit conversion: tools report milliseconds, semconv requires
seconds. An error there is three orders of magnitude wide, so the conversion is tested
separately.
