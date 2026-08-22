# What load testing tools actually emit

> **Checked facts, with dates.** Verified against each tool's own documentation as of
> **August 2026**. This page is evidence, not design: it stays useful whatever happens to the
> format. Where a claim here is out of date, the fix is to re-check it against the tool and move
> the date, never to soften the wording.

The useful finding is negative, and it is worth knowing before designing anything on top of
OpenTelemetry: **OTLP output is nearly universal and semantic convention names are not**. A tool
that "speaks OTel" is not thereby compatible with anything.

## State of the tools

Verified against documentation as of August 2026. The "semconv names" column asks whether
the tool publishes metrics under OpenTelemetry semantic convention names **without** an
adapter.

The last column, `Level`, is a **retired** vocabulary: constitution 2.1.0 keeps the citation
because retiring the ladder properly is owed to
[issue #36](https://github.com/galax-io/opennfr/issues/36), and the constitution forbids only
*new* citations. Read it as "how deeply a tool could be integrated", and read nothing normative
into it.

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