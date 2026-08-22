# How the format would reach a tool

> The format itself is [README.md](../README.md) and [the schema reference](../schema/README.md); how it works is [ARCHITECTURE.md](../ARCHITECTURE.md).

**Notes, not rules.** Nothing here is in the schema and nothing here is implemented. No
document in this repository describes a target, and no code turns a requirement into anything a
tool can run. The claim *"works with any tool"* is currently a design intention with an argument
behind it, and no evidence.

The one settled part is the direction: **support for a target is added as data, never as code.**
That is [ADR-0002 § D12](../reference/adr/0002-compatibility.md), and the constitution restates it as a
binding constraint — *"A target list that only maintainers can extend is not tool-agnostic."*

---

## Assertion

The projection of a criterion into one target's own form: a threshold in k6, an assertion in
Gatling, a post-processor in JMeter.

**The word stays out of the document.** An assertion is a generated artifact, not a source of
truth, and the moment it enters the format the format is nailed to one tool's semantics. This
is the single strongest constraint the notes have produced, and the one that has survived every
change of direction so far.

Rejected: writing assertions directly and calling that portable — that is what every surveyed
tool already offers, and it is the problem rather than the solution.

## Target

The external product an adapter faces. A load generator produces the traffic and reports what
happened; k6, Gatling and JMeter are the three the survey covers in depth.

A target never reads a requirement document. It is reached through a description of itself.

A target faces **outward**: it receives a rendered artifact. That is the opposite direction from
a *data source*, which faces inward and supplies measurements, and which
[ADR-0002 § D18](../reference/adr/0002-compatibility.md) keeps a parameter of evaluation rather than a
property of a requirement.

Constitution 2.0.0 narrowed the word: only a target that can host assertions has a path in this
format today. The monitoring-backend class named in 1.1.0 — Prometheus, Datadog and the rest —
keeps no path in scope and is parked; its status page, promotion conditions and retirement
conditions live in the experimental area under `docs/experimental/`.

Rejected: `consumer` — [AGENTS.md](../AGENTS.md) uses it for everything downstream of the
format, CI backends and human readers included, which is far wider. `tool` — reads as
load generator only, and the boundary has moved once already.

## Adapter

The component that binds the format to one target: it renames metrics to canonical names,
converts units, renames the tool's own labelling into attributes, and renders criteria into
that target's native assertions.

An adapter is **always** required, including for tools with built-in OTLP output. OTLP is a
transport, not a vocabulary, and no load generator publishes semantic convention names — see
[compatibility.md](../reference/compatibility.md). This refutes the intuition that *"the tool speaks OTel,
therefore it is compatible"*, and it is the most useful negative finding in this repository.

Units are where an adapter is most dangerous. Tools report milliseconds where the conventions
require seconds; an error there is three orders of magnitude wide and produces a confident,
wrong, green result. Which is why the conversion is declared in data rather than left to
whoever implements the adapter.

Rejected: `reader` for the part that reads a target's output files — in this repository's
documents `reader` means a human. `interpreter` — the vocabulary already has `Adapter`, and a
second decomposition of one pipeline is what [Principle I](../.specify/memory/constitution.md)
prices.

## MetricMapping

`kind: MetricMapping` — the declarative table binding one tool's names to canonical ones.
Sketched, never schema'd. Examples: [k6](examples/mapping-k6.yaml),
[JMeter](examples/mapping-jmeter.yaml), both of them sketches that validate against nothing.

It would carry the name correspondence with its unit conversion, the attribute correspondence,
how the target signals a failed request, how it derives percentiles, and — load-bearing — **the
list of constructs the target cannot honour**. An undeclared gap is a defect of the mapping, not
of the format.

The open problem is the failure signal. k6 signals a failed request with a separate metric,
JMeter with a boolean column, Gatling with KO. Expressing that declaratively, without
reinventing a rules DSL inside a format whose argument is that it has no DSL, is unsolved. The
`errorSignal` sketch in `mapping-k6.yaml` is one attempt and carries its own notice.

Rejected: `binding` — collides with the adjective this repository already uses to mean
normative. Support as code — the tool list is then capped by maintainer bandwidth, which is the
thing being argued against.

---

## Conformance level

**Retired by constitution 2.0.0. Recorded here unedited, because retiring it properly is owed to
[issue #36](https://github.com/galax-io/opennfr/issues/36) and an ADR superseding
[ADR-0002 § D13](../reference/adr/0002-compatibility.md).**

The ladder, as it stood — cumulative levels describing how deeply a tool is integrated:

| Level | What the adapter does | What it unlocks |
|---|---|---|
| `report` | maps metrics and attributes to canonical names | `enforcement: post` — **the entire format** |
| `assert` | also renders native assertions | `enforcement: inline`, `both` |
| `abort` | also stops the run | `onViolation: abort` |

`report` was not a degraded mode but a complete one: `assert` and `abort` merely shortened the
feedback loop. From that came the design rule *"no construct is added to the format if it is
expressible at `assert` and above only"*.

**Why it is retired.** The rungs were steps on a path that ended in post-run evaluation. With
evaluation out of scope, the bottom rung — mapping names — guarantees nothing anything can
consume, so the ladder does not survive being edited into the new shape. The design rule it
produced was also **inverted** by the same amendment: a construct now enters the format only if
at least one surveyed target can assert it exactly.

What replaces it is not an ordinal. The difference between two targets is not one number in
either direction: what a target can assert, what it cannot, how it names things, how its units
convert and where it can pass on absent data are declared per capability, each claim dated and
sourced. Aborting a run survives as one such declared capability rather than as a rung.

**No new artifact may cite a conformance level.** Existing citations —
[ARCHITECTURE.md](../ARCHITECTURE.md), [LAYOUT.md](../LAYOUT.md),
[ADR-0002](../reference/adr/0002-compatibility.md), and this page — are corrected by the pull request
issue #36 owes, and are deliberately not edited out one at a time.


---

## Requirements for the Go implementation

> **Overtaken in part.** No implementation exists, in Go or otherwise. The `Indicator` type
> below was removed from the format by
> [ADR-0003](../reference/adr/0003-selection-belongs-to-the-requirement.md), and `EvaluationReport` is
> [out of scope](the-result-document.md). What survives unchanged is the *technique* —
> pointers for mutually exclusive variants, `KnownFields(true)`, `float64` throughout, a
> conversion table rather than a UCUM parser — which is why the section is kept rather than
> deleted. Last true as written: 2026-08-18.

Constructs were selected so that decoding needs no custom code
([ADR-0002 § D19](../reference/adr/0002-compatibility.md)).

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
- Units are a closed enum ([units.md](../reference/units.md)); in Go that is a `map[Unit]conversion`,
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
| data sources | OTLP, Prometheus, JTL, `simulation.log` → normalised series. Injected from outside, see [ADR-0002 § D18](../reference/adr/0002-compatibility.md) |
| adapters | applying a `MetricMapping`; rendering assertions for levels `assert` and `abort` |

The crucial part: the evaluation layer knows nothing about tools or sources. It operates on
canonical names — and that is the only reason the format can promise compatibility with an
arbitrary tool.
