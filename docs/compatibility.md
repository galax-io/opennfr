# Compatibility

> The format itself is [README.md](../README.md) and [the schema reference](../schema/README.md); how it works is [ARCHITECTURE.md](../ARCHITECTURE.md).

Two different things live in this document, and they deserve different amounts of trust:

- **The state of the tools** — checked against their documentation in August 2026. Facts.
  Useful regardless of whether any of the format ideas survive. This is the part to read.
- **Conformance levels and the Go notes** — proposals, and both have been overtaken. See
  below and [ADR-0002](adr/0002-compatibility.md).

## Conformance levels (retired)

> **Retired by constitution 2.0.0, and left standing here rather than edited out.** The ladder
> was rungs on a path ending in post-run evaluation, which is out of scope; with evaluation
> gone the bottom rung guarantees nothing anything can consume. Retiring it properly needs an
> ADR superseding [ADR-0002 § D13](adr/0002-compatibility.md), which is
> [issue #36](https://github.com/galax-io/opennfr/issues/36); until that lands, no **new**
> artifact may cite a level. The reasoning is kept in
> [ideas/tool-support.md](ideas/tool-support.md#conformance-level). Last true as written:
> 2026-08-18.

Cumulative. A tool conforms to a level *through an adapter* — no tool publishes canonical
metric names on its own.

| Level | What the adapter does | What it unlocks |
|---|---|---|
| **`report`** | maps metrics and attributes to canonical names | `enforcement: post` — **the entire format**: requirements, guards, baselines, reporting |
| **`assert`** | also renders criteria into the tool's native assertions | `enforcement: inline`, `both` |
| **`abort`** | also stops the run on violation | `onViolation: abort` |

`report` is not a degraded mode but a complete one. `assert` and `abort` shorten the
feedback loop (no waiting out a thirty-minute run) but add no expressiveness.

Hence the design rule: **no construct may appear in OpenNFR that is expressible only at
level `assert`.**

## State of the tools

Verified against documentation as of August 2026. The "semconv names" column asks whether
the tool publishes metrics under OpenTelemetry semantic convention names **without** an
adapter.

| Tool | OTLP output | semconv names | Native assertions | Abort | Level |
|---|---|---|---|---|---|
| [k6](https://grafana.com/docs/k6/latest/results-output/real-time/opentelemetry/) | yes, built-in and experimental (`--out experimental-opentelemetry`); all k6 tags become OTel attributes | no — k6 names with the `K6_OTEL_METRIC_PREFIX` prefix (`k6_http_req_duration`) | yes, `thresholds` | yes, `abortOnFail` + `delayAbortEval` | `abort` |
| [Artillery](https://www.artillery.io/docs/reference/extensions/publish-metrics/opentelemetry) | yes, `publish-metrics` with `type: open-telemetry`; OTLP HTTP/JSON, HTTP/protobuf, gRPC | no | yes, `ensure` | not verified | `assert` |
| [Locust](https://docs.locust.io/en/stable/telemetry.html) | yes, official integration configured by environment variables | no | Python code only | code only | `report` |
| [Gatling](https://docs.gatling.io/integrations/apm-tools/otel/) | **Enterprise Edition only**; the OSS build goes through `simulation.log` | no | yes, `assertions` | no | `assert` |
| [JMeter](https://github.com/vdaburon/otel-apm-jmeter-plugin) | none official; third-party plugins target traces. The practical path is JTL or a custom listener | no | plugins and post-processing only | no | `report` |

### What follows from this

1. **An adapter is always required.** A built-in OTLP output spares you writing metric
   collection, but not the renaming. This refutes the intuition that "the tool speaks OTel,
   therefore it is compatible".
2. **Units have to be converted.** k6 reports durations in milliseconds; semconv requires
   seconds. An error here is three orders of magnitude wide, so unit conversion is a
   separately tested part of the adapter rather than a detail of the mapping.
3. **Gatling OSS and JMeter go through files.** For those the adapter reads
   `simulation.log` and JTL. That is level `report`, and it is sufficient.
4. **JMeter is the most expensive case.** Neither an OTLP output nor a stable notion of a
   route: the sampler label is an arbitrary string. Hence `loadtest.request.name`
   ([ADR-0002 § D14](adr/0002-compatibility.md)).

## Mapping is data, not code

Name correspondence is described by a [`kind: MetricMapping`](examples/mapping-k6.yaml)
object rather than baked into the implementation. Supporting a new tool is a YAML file,
not a fork of the Go code. Without that, "works with any tool" stays a slogan: the tool
list is capped by maintainer bandwidth.

## Requirements for the Go implementation

> **Overtaken in part.** No implementation exists, in Go or otherwise. The `Indicator` type
> below was removed from the format by
> [ADR-0003](adr/0003-selection-belongs-to-the-requirement.md), and `EvaluationReport` is
> [out of scope](ideas/the-result-document.md). What survives unchanged is the *technique* —
> pointers for mutually exclusive variants, `KnownFields(true)`, `float64` throughout, a
> conversion table rather than a UCUM parser — which is why the section is kept rather than
> deleted. Last true as written: 2026-08-18.

Constructs were selected so that decoding needs no custom code
([ADR-0002 § D19](adr/0002-compatibility.md)).

### Decoding

```go
// Mutually exclusive variants: pointers plus a single "exactly one non-nil" check.
// No custom UnmarshalYAML required.
type Indicator struct {
    Distribution *Distribution `yaml:"distribution,omitempty"`
    Ratio        *Ratio        `yaml:"ratio,omitempty"`
}
```

A discriminator (`type: distribution`) would require two-pass decoding through
`yaml.Node` — which is why the format uses nested keys instead. The same technique covers
`indicator`/`indicatorRef` and `threshold` vs `baseline`+`tolerance`.

The only place with string parsing is `aggregation`: `type Aggregation string` with a
`Quantile() (float64, bool)` method.

### Mandatory decoder settings

```go
dec := yaml.NewDecoder(r)
dec.KnownFields(true)          // an unknown field is an error, see ADR-0002 § D17
```

Lenient parsing is unacceptable: a typo in a field name would silently disable a criterion
and turn the run green.

### Everything else

- `threshold`, `tolerance.value` and all observed values are `float64`. The format has no
  decimal strings.
- Units are a closed enum ([units.md](units.md)); in Go that is a `map[Unit]conversion`,
  not a UCUM parser.
- camelCase in YAML matches ordinary struct tags and the k8s convention.
- `apiVersion: opennfr.io/v1` maps onto `pkg/apis/opennfr/v1` and gives a natural path for
  conversion between format versions.

### Layering

The format's layers define package boundaries. The intended split (nothing is implemented
yet):

| Layer | Responsibility |
|---|---|
| types and parsing | the `RequirementSet`, `Indicator`, `MetricMapping`, `EvaluationReport` structs; schema validation |
| evaluation | criteria + guards → verdicts; `gate` → outcome. Pure functions over time series, no I/O |
| data sources | OTLP, Prometheus, JTL, `simulation.log` → normalised series. Injected from outside, see [ADR-0002 § D18](adr/0002-compatibility.md) |
| adapters | applying a `MetricMapping`; rendering assertions for levels `assert` and `abort` |

The crucial part: the evaluation layer knows nothing about tools or sources. It operates on
canonical names — and that is the only reason the format can promise compatibility with an
arbitrary tool.
