# ADR-0002. Compatibility: the Go implementation and load testing tools

- **Status:** proposed
- **Date:** 2026-08-09
- **Extends:** [ADR-0001](0001-terminology.md)

> Notes, not decisions — see the preamble of [ADR-0001](0001-terminology.md). The one part
> here that is checked rather than argued is the survey of what tools actually emit, and it
> is worth reading even if everything else turns out wrong.

## Context

Two forward-looking requirements were added to the format:

1. **A reference implementation in Go** — a parsing and evaluation library, with a service
   on top.
2. **Compatibility with load testing tools** — k6, Gatling, JMeter, Locust, Artillery and
   beyond.

Both affect the *format*, not merely the future code: the implementation language dictates
which constructs are cheap, and the tools dictate what is achievable at all. We fix this
before the schema, while changing it is still cheap.

A survey of tool support as of August 2026 (details and sources in
[compatibility.md](../compatibility.md)) produced an unexpected result:

> OTLP transport is nearly universal, yet **no tool publishes semconv names**. k6 emits
> `k6_http_req_duration` with a configurable prefix; Artillery and Locust use their own
> names. Gatling speaks OTel only in the Enterprise Edition; JMeter only through
> third-party plugins or JTL.

This refutes the initial assumption that "turn on the tool's OTel output and everything
lines up".

## Working conclusions

### D11. An adapter is a semantic mapper, not a transport

Since no tool publishes semconv names, an adapter is **always** required — including for
tools with built-in OTLP output. Its work is:

1. renaming metrics to canonical names ([ADR-0001 § D3](0001-terminology.md));
2. converting units (k6 reports durations in `ms`, semconv requires `s`);
3. renaming the tool's tags into OTel attributes;
4. rendering criteria into native assertions — at conformance level `assert` and above (D13).

A built-in OTLP output reduces the adapter's work (no collection to write) but does not
remove it.

### D12. Mapping is data, not code: `kind: MetricMapping`

The correspondence between a tool's names and canonical ones is declared as a separate
object of the format rather than hardcoded in Go.

```yaml
apiVersion: opennfr.io/v1
kind: MetricMapping
metadata:
  name: k6
spec:
  metrics:
    - from: k6_http_req_duration
      to: http.client.request.duration
      unit: { from: ms, to: s }
  attributes:
    - { from: name,   to: loadtest.request.name }
    - { from: method, to: http.request.method }
```

The consequence: **supporting a new tool means adding a YAML file, not forking the Go
code.** This is what operationalises "works with any tool" — otherwise the phrase stays a
slogan and the tool list is capped forever by maintainer bandwidth.

The fourth and final kind of the format: `RequirementSet`, `Indicator`, `MetricMapping`,
`EvaluationReport`.

### D13. Conformance levels: `report` / `assert` / `abort`

Tools are not equal, and pretending they are means promising what cannot be delivered.
Instead of a binary "supported / not supported", three cumulative levels:

| Level | What the tool can do (through an adapter) | What it unlocks |
|---|---|---|
| `report` | emits metrics reducible to canonical names | `enforcement: post` — the entire format |
| `assert` | plus rendering criteria into native assertions | `enforcement: inline`, `both` |
| `abort` | plus stopping the run on violation | `onViolation: abort` |

`report` is the mandatory minimum and a complete mode: requirements, guards, baselines and
reporting all work there. `assert` and `abort` optimise the feedback loop; they do not
extend expressiveness.

Hence the compatibility rule: **the format must contain no construct expressible only at
level `assert`.** Anything checkable on the fly must also be checkable afterwards.

### D14. `loadtest.request.name` is the canonical addressing fallback

Practically no tool emits `http.route`: k6 has a `name` tag, Gatling a request name,
JMeter a sampler label — all arbitrary strings rather than routes.

We introduce `loadtest.request.name` with an explicit precedence rule:

- `http.route` is **preferred**: portable across tools and correlated with the production
  metrics of the same service;
- `loadtest.request.name` is a pragmatic fallback for when no route exists.

This directly replaces picatinny's `MyGroup / MyRequest` keys and k6's `{name:...}`, but
states honestly that it is the worse option rather than an equal one.

### D15. Units are a closed enum, not full UCUM

[ADR-0001 § D5](0001-terminology.md) said "UCUM". Refined: **a subset of UCUM given by a
closed list**.

The reason is implementability: there is no serviceable UCUM library for Go, and writing a
parser for the UCUM grammar for the sake of a dozen-and-a-half units is disproportionate —
the same mistake as the string DSL in [D4](0001-terminology.md).

A closed list validates as a JSON Schema `enum` and becomes a `map[Unit]conversion` in Go.
The list is in [units.md](../units.md).

### D16. A normative subset of YAML

Every object must map one-to-one onto JSON. Forbidden:

- anchors, aliases and merge keys (`&`, `*`, `<<`) — not portable to JSON, supported
  inconsistently across parsers, and destructive to line numbers in error messages;
- non-string mapping keys;
- implementation-specific tags (`!!python/…` and the like).

Reuse is provided by the `defaults` section and `indicatorRef`, not by YAML anchors.

Multi-document (`---`) is allowed as a container for several objects in one file.

### D17. Strict parsing: an unknown field is an error

A typo such as `agregation:` would, under lenient parsing, be silently ignored, the
criterion would go unchecked, and the run would turn green. This is the same class of
silent lie as treating `noData` as success ([ADR-0001 § D6](0001-terminology.md)), and it
is forbidden the same way.

The single extension point is `metadata.annotations`. In Go this means
`yaml.Decoder.KnownFields(true)` and `json.Decoder.DisallowUnknownFields()`.

### D18. The data source is not part of `RequirementSet`

Unlike OpenSLO, there is no `DataSource` object and no `metricSource` inside an indicator.

Requirements must outlive a change of observability stack: the same `RequirementSet` is
checked against an OTLP stream, against Prometheus, and against a JTL file. The source is a
parameter of evaluation (runner configuration, a CLI flag), not a property of the
requirement.

### D19. Go-friendliness as a construct-selection criterion

The rule: **no construct of the format may require a custom unmarshaler.** The sole
exception is `aggregation` (enum plus percentile pattern).

The accepted decisions, checked against that criterion:

| Construct | Effect in Go |
|---|---|
| Nested keys `distribution:` / `ratio:` | a pair of pointers in a struct plus one "exactly one non-nil" check. A discriminator (`type: distribution`) would require two-pass decoding via `yaml.Node` — **hence nested keys, not a discriminator** |
| `indicator` / `indicatorRef` | likewise, a pair of pointers |
| `threshold` vs `baseline` + `tolerance` | likewise |
| `aggregation: p95` | `type Aggregation string` with a `Quantile() (float64, bool)` method. The only place with string parsing |
| camelCase | matches the k8s convention and ordinary struct tags |
| `threshold`, `tolerance.value` | always `float64`; the format has no decimal strings |
| `apiVersion: opennfr.io/v1` | maps naturally onto `pkg/apis/opennfr/v1` and onto version conversion |

Here Go ergonomics and unambiguity happened to coincide: the constructs that are easiest to
decode turned out to be the most explicit for humans too. Should the two criteria ever
diverge, unambiguity of the format wins.

## Consequences

**Positive**

- The list of supported tools grows by YAML files, not by code.
- `report` as the mandatory minimum makes the format applicable even to tools with no
  assertion support whatsoever — JMeter via JTL included.
- Strict parsing and a closed unit list remove two classes of silent false greens.
- The absence of `DataSource` keeps `RequirementSet` a portable artifact.

**Negative / cost**

- `MetricMapping` is one more object to specify, validate and maintain. It has to be
  hand-verified per tool.
- Unit conversion (`ms` → `s`) puts arithmetic on the data path; errors there are three
  orders of magnitude wide and therefore need dedicated tests.
- Dropping anchors hurts ergonomics in large files. The bet that `defaults` and
  `indicatorRef` cover it is untested at real scale.
- JMeter remains the most expensive case: neither an OTLP output nor a stable notion of a
  route.

## Open questions

1. **Defining an error inside `MetricMapping`.** How is "set `error.type` when
   `k6_http_req_failed == 1`" expressed declaratively? Conditional mapping is required, and
   its expressiveness slides easily into the very DSL we rejected.
2. **Histograms.** Percentiles are computed from buckets, and accuracy depends on their
   boundaries. Should the required resolution (exponential histogram, bucket count) be
   declared — and where: in `MetricMapping` or in `RequirementSet`?
3. **Streaming for `enforcement: inline`.** Does the Go library expose a streaming
   evaluation interface, or does inline stay entirely on the adapter side?
4. **`dataSourceRef`** (see D18) — will an exception be needed for indicators physically
   inseparable from their source?

## References

- [Tool compatibility matrix](../compatibility.md)
- [Units](../units.md)
- The `loadtest.*` registry — a proposal, and a note rather than reference: `docs/semconv/loadtest.md`
- The `MetricMapping` sketch for k6, which validates against nothing: `docs/examples/mapping-k6.yaml`
