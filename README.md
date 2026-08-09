# OpenNFR

**A design notebook, not a specification.**

An attempt to work out what an open, tool-agnostic format for load testing requirements
*could* look like. Right now this repository contains notes: a survey of existing
solutions, a pile of naming arguments, and sketches of what a document might look like.

> Nothing here is decided. There is no schema, no validator, no implementation, and no
> stable vocabulary. Every YAML block below is an illustration of an idea, not syntax —
> field names change between sessions of thinking about them. Do not build anything on it
> yet.

If you have opinions about any of this, that is exactly what the repository is for.

---

## The question being explored

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

So: could the requirement be written once, independently of whatever runs it? What would
it have to look like to be checkable both as an assertion inside a tool and afterwards in a
backend?

That question is open. What follows is how far the thinking has gotten.

## What has actually been done

The genuinely finished part is the survey — [docs/references.md](docs/references.md).
[OpenSLO](https://github.com/OpenSLO/OpenSLO), [Keptn quality
gates](https://v1.keptn.sh/docs/1.0.x/reference/files/slo/), [k6
thresholds](https://grafana.com/docs/k6/latest/using-k6/thresholds/), [Taurus
PassFail](https://gettaurus.org/docs/PassFail/),
[SLA4OAI](https://github.com/isa-group/SLA4OAI-Specification),
[gatling-picatinny](https://github.com/galax-io/gatling-picatinny), plus the adjacent SLO
tooling — with notes on what each got right and where each hurts.

Short version: nothing found covers "requirements for a single load test run,
tool-agnostic, strictly parseable, OTel-compatible". OpenSLO solves production SLOs with
error budgets; Keptn solves CI gates with a vocabulary of its own; the rest are
tool-internal DSLs.

Also finished, and also just facts: a [check of what load testing tools actually
emit](docs/compatibility.md) as of August 2026. The useful finding there is negative —
OTLP output is nearly universal, yet **no tool publishes OpenTelemetry semantic convention
names**. k6 emits `k6_http_req_duration` in milliseconds where semconv would want
`http.client.request.duration` in seconds. So "the tool speaks OTel" turns out not to mean
"the tool is compatible", which quietly invalidates the obvious approach.

Everything else in `docs/` is thinking out loud.

## Ideas that keep surviving

These are the ones that have held up so far. None is settled; each is written up with its
cost and its counterarguments.

**Don't invent metric names.** A load generator *is* an HTTP client, so its latency metric
arguably already has a name: `http.client.request.duration`. Same for selection
(`http.route`, `error.type`) and run identity (`test.suite.name`, `cicd.pipeline.run.id`).
The appeal is that a result report would correlate with the traces of the same run without
glue. The cost is that every tool then needs a name-mapping layer — see the negative
finding above. Whether that trade is worth it is not obvious.

**A run that under-delivered load is not a pass.** If the generator never reached 200 rps,
a latency threshold goes green and the verdict is a lie. This seems to be the most common
failure mode in load testing reports, and none of the surveyed formats catches it. The
sketch: preconditions that are checked like criteria but yield a third outcome —
*inconclusive*, "the test did not happen" — rather than pass or fail. Whether it deserves
to be a separate outcome or is just a fancy `fail` is arguable.

**Tool support as data, not code.** If integrating a tool means writing a mapping file
rather than forking an implementation, the list of supported tools stops being capped by
maintainer bandwidth. Sketched as a separate document kind. Unproven — the hard part is
expressing "an error happened" declaratively across tools that all signal it differently,
and that is an open problem, not a solved one.

**Structure over string DSLs.** `{aggregation: p95, op: lte, threshold: 500, unit: ms}`
rather than `"p95 < 500ms"`. More verbose, but no bespoke grammar has to be reimplemented
in every backend. This is where Keptn and Taurus visibly struggle.

## What a document might look like

Illustrative sketch. Field names are unstable.

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

## Known holes

Not a roadmap — a list of things that are unresolved, some of which may sink the whole
approach:

- **Nothing is validated.** No JSON Schema exists, so the examples are prose that happens
  to parse as YAML. The schema is the next thing to write, and it will expose whatever the
  vocabulary leaves unsaid.
- **Declaring "an error occurred" across tools.** k6 signals failure with a separate metric,
  JMeter with a boolean column, Gatling with KO. Expressing that declaratively without
  reinventing a rules DSL is unsolved.
- **Percentiles come from histogram buckets**, so accuracy depends on bucket boundaries.
  Whether the format has to say anything about resolution is unclear.
- **Whether load profiles belong here at all.** Describing the requirement is one thing;
  describing the load that has to be generated is another, and it overlaps with what the
  tools already do well. Currently out of scope, mostly out of caution.
- **Baselines, time windows, streaming evaluation** — sketched, not thought through.

## Documents

Read them as notes, not as normative text. The [glossary](docs/GLOSSARY.md) is the most
useful entry point: it is essentially a list of candidate terms with the rejected
alternatives and the reasons.

| | |
|---|---|
| [docs/GLOSSARY.md](docs/GLOSSARY.md) | candidate vocabulary, with rejected synonyms |
| [docs/adr/0001-terminology.md](docs/adr/0001-terminology.md) | naming arguments, in ADR form (status: proposed) |
| [docs/adr/0002-compatibility.md](docs/adr/0002-compatibility.md) | notes on a Go implementation and tool compatibility |
| [docs/compatibility.md](docs/compatibility.md) | what tools actually emit — checked, factual |
| [docs/references.md](docs/references.md) | the survey — the most finished part of the repo |
| [docs/semconv/loadtest.md](docs/semconv/loadtest.md) | sketch of a `loadtest.*` attribute registry |
| [docs/units.md](docs/units.md) | notes on units |
| [docs/examples/](docs/examples/) | sketches, not validated |

## Where this sits relative to OpenSLO

Not a competitor — if this goes anywhere, it is the counterpart of
[OpenSLO](https://github.com/OpenSLO/OpenSLO) on the other side of the release.

| | OpenSLO | this |
|---|---|---|
| Subject | a service in production | a single load test run |
| Time frame | rolling window, weeks | one run, minutes |
| Core concept | error budget | pass / fail gate for CI |
| Answers | "are we spending reliability too fast?" | "may this build ship?" |

The k8s-style envelope, `op` values and the SLI/SLO split are borrowed deliberately, so
that the two would read alike.

## Contributing

Arguments are more useful than pull requests at this stage. Particularly welcome: reasons
why an idea above is wrong, cases from real load testing that the sketches cannot express,
and better names — the vocabulary is deliberately narrow, and every added word is a cost.

## License

[Apache License 2.0](LICENSE)
