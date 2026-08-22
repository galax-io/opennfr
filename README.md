# OpenNFR

**One format for load testing requirements, written once and naming no tool.**

A performance requirement — *"checkout answers within 500 ms and fewer than 5 % of its
requests fail"* — outlives every tool that ever checks it. Today it is rewritten from
scratch for each one, in that tool's grammar, with that tool's metric names and that tool's
idea of failure. OpenNFR is an attempt to write it down once, in a form a schema can check
and a person can read.

## What exists today

| | |
|---|---|
| **The container** | One JSON Schema: [`schema/opennfr.io/v1/requirementset.schema.json`](schema/opennfr.io/v1/requirementset.schema.json). It fixes the shape a requirement is written in, and validates |
| **A validated corpus** | [`examples/`](examples/) — every document there is checked against the schema on every commit, so this page cannot drift away from what the schema accepts |
| **A gate** | `bash scripts/verify.sh` — the schema, the corpus, the links and the language, run in CI |
| **The reference** | [`schema/README.md`](schema/README.md) — every field, every constraint, every allowed value |

**What does not exist**: nothing reads a document yet. There is no renderer that turns a
requirement into a load generator's own assertions, no implementation in any language, and no
tool description. The format is usable — you can write a requirement, validate it, review it
and keep it in version control — and it is not yet *runnable*. That gap is the next piece of
work, and it is named as such rather than implied.

Two directories, and the difference between them is the point.
[`reference/`](reference/) is what is true of the format today — the vocabulary, the units, the
names, the dated tool survey and the decision records behind them. `docs/` holds **ideas**:
constructs the format does not have, each of which will be built, reworked or dropped. Nothing
outside `docs/` links into it, so it can be deleted whole without touching anything real.

---

## The problem

Every load testing tool can assert a threshold. No two agree on how to say so:

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

Three grammars, three metric vocabularies, three notions of failure — and none of them
survives a move to another tool. The survey behind that claim is
[`reference/prior-art.md`](reference/prior-art.md); the check of what the tools actually emit is
[`reference/compatibility.md`](reference/compatibility.md). The short version of the second one is
negative and worth knowing before you start: OTLP output is nearly universal, and **no tool
publishes OpenTelemetry semantic convention names**. k6 emits `k6_http_req_duration` in
milliseconds where the convention wants `http.client.request.duration` in seconds. "The tool
speaks OTel" does not mean "the tool is compatible".

## A document

This is [`examples/minimal.yaml`](examples/minimal.yaml), whole. It is the smallest thing the
schema accepts, and `scripts/verify.sh` validates it on every commit:

```yaml
apiVersion: opennfr.io/v1
kind: RequirementSet
metadata:
  name: example

spec:
  requirements:
    - name: orders
      selector:
        http.route: /api/v1/orders
      criteria:
        - metric: http.client.request.duration
          aggregation: p95
          op: lte
          threshold: 500
          unit: ms
```

Read it as one sentence: *of the requests to `/api/v1/orders`, the 95th percentile of the
duration must be at most 500 ms.*

No tool is named anywhere in it — not in a field, a value, or a metric name. That is the
whole point, and it is the one property the format will not trade away.

---

## How the format works

The whole shape, and there is no more of it:

```
RequirementSet          the document — an envelope and a list
└── requirement         one human sentence about one set of requests
    ├── selector        WHICH requests — written once, for everything below it
    ├── criteria[]      what must be true of them
    └── guards[]        what must have been true of the run for that to mean anything
```

Everything under `criteria` and `guards` is the same four-key shape, called a **predicate**:

```yaml
metric: http.client.request.duration   # optional — what to measure, if anything
aggregation: p95                       # how to reduce many numbers to one
op: lte                                # how to compare it
threshold: 500                         # to what
unit: ms                               # in what
```

The last four keys are always there and are the entire grammar. There is no expression
language, no `"p95 < 500ms"` string to parse, and nothing a consumer has to reimplement — which
is exactly where the surveyed formats struggle.

### The one idea worth understanding

**A requirement says which requests once.** Every criterion and every guard beneath it is
about those requests.

This sounds like a detail and is not. Before [ADR-0003](reference/adr/0003-selection-belongs-to-the-requirement.md),
selection lived on each criterion, and stating that one endpoint was both *fast* and
*reliable* meant two requirements repeating the same selector — two objects for one sentence,
and two places to edit when the route changes. Now:

```yaml
- name: checkout
  displayName: Checkout is fast and reliable
  selector:
    http.route: /api/v1/checkout          # said once
  criteria:
    - {metric: http.client.request.duration, aggregation: p99, op: lte, threshold: 500, unit: ms}
    - {bad: {error.type: "*"},               aggregation: rate, op: lte, threshold: 5,   unit: "%"}
```

One requirement, because it is one human sentence.

### What a criterion can be about

Every criterion is those same four keys. What it *reduces* depends on which optional key it
carries — and it carries at most one of them:

| Carries | It is about | Aggregations that mean anything |
|---|---|---|
| `metric` | a quantity the selected requests carry — their duration, their body size | `p50`…`p99.9`, `avg`, `min`, `max`, `stddev`, `sum`, `count`, `rate` |
| `bad` or `good` | a fraction of the selected requests | `rate` — the share; `count` — how many |
| neither | the selected requests themselves | `count` — how many; `rate` — how many per second |

The three rows are three different things, and the schema knows it. A percentile without a
`metric` is rejected: there are no values to take a percentile of. A percentile with `bad` is
rejected: a percentile of a fraction is not a number anyone wants. `metric` together with
`bad` is rejected: one measures, the other counts.

### The same run, seen four ways

Say a run made **1000 requests** to `/api/v1/checkout`, **30** of them carrying `error.type`,
with a 99th-percentile duration of 480 ms and a slowest of 1200 ms:

```yaml
- name: checkout
  selector: {http.route: /api/v1/checkout}
  criteria:
    - {metric: http.client.request.duration, aggregation: p99,   op: lte, threshold: 500,  unit: ms}
    - {metric: http.client.request.duration, aggregation: max,   op: lte, threshold: 1000, unit: ms}
    - {bad: {error.type: "*"},               aggregation: rate,  op: lte, threshold: 5,    unit: "%"}
    - {bad: {error.type: "*"},               aggregation: count, op: lte, threshold: 20,   unit: "{request}"}
```

| Criterion | What is reduced | Actual | Must be | |
|---|---|---|---|---|
| `p99` of the metric | the **durations** of the 1000 requests | 480 ms | ≤ 500 ms | pass |
| `max` of the metric | the same durations | 1200 ms | ≤ 1000 ms | **fail** |
| `rate` with `bad` | 30 **÷** 1000 | 3 % | ≤ 5 % | pass |
| `count` with `bad` | how many matched `bad` | 30 | ≤ 20 | **fail** |

The top two reduce values a metric carries. The bottom two reduce counts of requests, and no
metric is involved — which is why there is no `error_rate` metric and never will be.

---

## Every field

### The envelope

```yaml
apiVersion: opennfr.io/v1     # required, and this exact string
kind: RequirementSet          # required, and this exact string
metadata: {...}               # required
spec: {...}                   # required
```

Borrowed from Kubernetes, deliberately. `apiVersion` is how a v2 will be told apart from a v1
by a consumer that has to read both, and the shape is one every ops reader already recognises.

Unknown fields are rejected here and at every level below. The single exception is `selector`,
whose keys are attribute names and therefore cannot be enumerated in advance.

### `metadata`

| Field | | |
|---|---|---|
| `name` | **required** | The document's identifier: lowercase letters, digits and hyphens, up to 253 characters. Restricted because something has to be able to point at it |
| `displayName` | optional | Free text for a person, in any script, up to 200 characters. See below |
| `annotations` | optional | String-to-string map. **The only extension point in the format.** The `opennfr.io/` prefix is reserved |

`annotations` is where anything the format does not model goes — a ticket link, an owning
team, a paragraph of prose. Nothing in the format reads it, which is the point: it is an
escape hatch that cannot quietly become a feature.

### `spec.requirements`

A list, and it may not be empty. A document with no requirements states nothing, and a
document that states nothing should not validate.

### A requirement

| Field | | |
|---|---|---|
| `name` | **required** | Identifier, same rules as the document's |
| `selector` | **required** | Which requests this requirement is about |
| `criteria` | **required** | At least one. What must hold |
| `guards` | optional | If present, at least one. What must have been true of the run |
| `displayName` | optional | The human sentence this requirement encodes |

`selector` is required rather than defaulted. Every requirement is about *some* set of
requests, and the set "all of them" is written `selector: {}` — visibly, as a decision, rather
than by leaving a line out.

### `selector` — which requests

A map of attribute to value. Every key must match.

```yaml
selector: {}                                   # every request, said explicitly
selector: {http.route: /api/v1/checkout}       # one endpoint
selector: {loadtest.request.name: GET /}       # one request, by the name the tool records
selector:                                      # a request inside a group
  loadtest.group.name: MyGroup
  loadtest.request.name: MyRequest
selector: {error.type: "*"}                    # the attribute is present, with any value
```

Attribute names are **not enumerated by the schema**, and never will be. They are borrowed
from OpenTelemetry where an equivalent exists; which names to use is
[`reference/names.md`](reference/names.md).

**On addressing a request.** `http.route` is the portable way: it is the same string the
service's own production metrics carry, so a requirement written against it can be compared
across tools and against reality. Almost no load generator emits it. `loadtest.request.name`
— k6's `name` tag, Gatling's request name, JMeter's sampler label — is the honest fallback,
and it is the worse option rather than an equal one: those names are arbitrary, they live
inside one tool, and a document written against them does not travel. The format takes no
position beyond saying which is which.

### `criteria` and `guards` — the same shape, different meaning

Both are lists of predicates and they are structurally identical. The difference is entirely
in what a violation means:

- a violated **criterion** says *the system did not hold*;
- a violated **guard** says *the run did not happen as intended*.

The distinction earns its keep on the most common lie in load testing reports: a test that was
supposed to push 200 rps, pushed 5, and shows a beautiful p95. Every criterion is green and
the run measured nothing.

```yaml
guards:
  - {name: reached-target-rate, aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"}
criteria:
  - {metric: http.client.request.duration, aggregation: p95, op: lte, threshold: 500, unit: ms}
```

A guard is an ordinary, checkable statement — not metadata, not a comment. The format states
the condition and says which entries state a condition of the run rather than a property of
the system; what a tool does with that is the tool's business.

### A predicate

```yaml
- name: reached-target-rate        # optional
  displayName: Target rate reached # optional
  metric: http.client.request.duration   # at most one of metric / bad / good
  aggregation: p95                 # required
  op: lte                          # required
  threshold: 500                   # required
  unit: ms                         # required
```

**`aggregation`** — how many numbers become one. `avg`, `min`, `max`, `sum`, `stddev`,
`count`, `rate`, and any percentile written `p` followed by up to two digits and an optional
decimal: `p50`, `p95`, `p99`, `p99.9`.

`rate` reads from the shape it is applied to. Over requests it is per second; over a fraction
it is the share. That overload is borrowed from k6, which resolves it the same way and for the
same reason — and inventing a second word to avoid it would cost a term to save a wart.

**`op`** — `lt`, `lte`, `gt`, `gte`, `eq`, `neq`. Words rather than symbols: `<=` validates
poorly and has to be parsed out of a string.

**`threshold`** — a number. Not a string, so `"500ms"` is not expressible; the unit is a
field of its own.

**`unit`** — **required, always**, and from a closed list: `ns`, `us`, `ms`, `s`, `min`, `h`,
`%`, `1`, `By`, `KiBy`, `MiBy`, `GiBy`, `{request}`, `{request}/s`, `{iteration}`,
`{iteration}/s`, `{vu}`. The reasoning and the conversions are in
[`reference/units.md`](reference/units.md).

Two arguments hold that list closed. A bare `500` is three orders of magnitude away from
unambiguous — every tool reports milliseconds, every semantic convention wants seconds. And a
closed enumeration catches `mss` in your editor rather than in a report; full UCUM would need
a grammar parser to reject the same typo, which is the string-DSL mistake in a different hat.

**`metric`** — what to measure of the selected requests. Any non-empty string; the schema will
never enumerate metric names, because enumerating them would make every new metric a change to
the format. Borrow from OpenTelemetry where a name exists: a load generator is an HTTP client,
so its latency metric is `http.client.request.duration` — the client-side one, not the server
one and not the tool's own.

**`bad` / `good`** — makes the predicate a fraction. Both are selectors, and both **narrow**
the requirement's selection rather than replacing it: the numerator is the selected requests
that also match, and the denominator is the requirement's own selection, so it is never
written twice. At most one of the two appears.

```yaml
- {bad: {error.type: "*"}, aggregation: rate, op: lte, threshold: 5, unit: "%"}
```

> **A known limitation, recorded rather than hidden.** A selector can say an attribute is
> *present* (`error.type: "*"`); it cannot say the attribute is *absent*. So `bad` has
> something to select and `good` does not. Write the failed fraction and compare it with
> `lte`.

**`name`** — needed only when two predicates of one requirement would otherwise be
indistinguishable. Identity is the `name` if set, and the `aggregation` otherwise:

```yaml
guards:   [{aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"}]
criteria: [{aggregation: rate, op: lte, threshold: 400, unit: "{request}/s"}]
# both identities are "rate" — one of them must be named
```

With different aggregations — `p99` beside `max` — no name is needed and adding one is noise.

### `displayName` — optional, and inert

Free text, any script, 1 to 200 characters, allowed on the document, on a requirement, and on
a predicate. `name` is restricted so a machine can point at it; `displayName` is for a person
to read.

It is inert by construction: nothing selected, measured or compared depends on it, and two
documents differing only in their display names say the same thing.

Keep it to the quantity, never to the answer:

```yaml
- {displayName: 99th percentile, aggregation: p99, op: lte, threshold: 500, unit: ms}  # yes
- {displayName: 99th percentile under 500 ms, ...}                                     # no
```

The second is a second copy of `threshold`, and it stops being true the first time the
threshold moves. 200 characters is the bound because a display name that needs more than that
is prose, and prose belongs in `annotations` where nothing pretends it is a name.

---

## Writing one yourself

Start from [`examples/minimal.yaml`](examples/minimal.yaml), and validate:

```bash
bash scripts/verify.sh
```

It needs `python3` with `pyyaml` and `jsonschema`. The schema is an ordinary
[Draft 2020-12](https://json-schema.org/draft/2020-12/schema) file, so any validator in any
language will do, and an editor with YAML schema support will complete the fields as you type
— every definition in the schema carries `examples` for exactly that.

**The schema is strict on purpose.** Unknown fields are rejected everywhere, at every depth.
A typo like `agregation:` is a parse error rather than a silently skipped criterion, because a
silently skipped criterion is a check that never ran and a report that looks clean.

[`examples/six-statements.yaml`](examples/six-statements.yaml) is the fuller example: three
requirements, eleven criteria, an endpoint addressed by route and another addressed by name,
and `selector: {}` for the run as a whole.

The exact constraints — every pattern, every enumerated value, every combination the schema
rejects and the message it rejects it with — are in [`schema/README.md`](schema/README.md).

---

## What the format deliberately does not define

**Metric names.** `metric` is a string. Enumerating names would make every new metric a change
to the format. Where OpenTelemetry has a name, use it — [`reference/names.md`](reference/names.md)
lists which. Where it has none, the `loadtest.*` namespace is a proposal submitted nowhere, and
`reference/names.md` says so in the one place the validated corpus already leans on it.

**Attribute names.** Same reasoning, same answer.

**Derived quantities.** Throughput is `aggregation: rate` over requests. An error rate is
`rate` with `bad: {error.type: "*"}`. Neither is a metric, neither gets a name, and a second
vocabulary would be a second source of truth.

So: to measure something new, write a different `metric` string. The schema does not change.

## What is not in it yet

Real needs, deliberately absent. Each would add either a dependency the format cannot honour
or a knob before anyone has asked for one.

| Idea | Why it is not here |
|---|---|
| `window` — measure only the steady phase | Rests on a `loadtest.phase` attribute that nothing emits |
| `baseline` + `tolerance` — "no worse than last time" | Needs stored history of previous runs, which no load generator provides |
| `severity` and `gate` — which violations fail the run | A knob. Today any failed criterion fails the run, and that is enough until someone needs otherwise |
| `defaults` — write shared settings once | Sugar. It buys brevity and costs merge semantics |
| A result document | Nothing produces one yet. Designing an output before anything computes it is guessing, and a guess in a schema is harder to withdraw than a guess in a note |
| A target description — what binds the format to a tool | Arrives with the first tool that needs it |

The load profile — stages, arrival rate, duration — is not on that list, because it is not a
"yet". The tools do not agree on what an open or a closed model does under degradation, so
borrowing the construct would import the disagreement. The word `workload` is reserved and
unused for exactly that reason.

Each of these is argued under `docs/`, which this page deliberately does not link into, and the
route from an argument to a field in the schema is in
[LAYOUT.md](LAYOUT.md#how-an-idea-becomes-part-of-the-format).

## What is unresolved

Not a roadmap — open problems, some of which may sink the approach:

- **Declaring "an error occurred" across tools.** k6 signals failure with a separate metric,
  JMeter with a boolean column, Gatling with KO. Expressing that declaratively, without
  reinventing a rules DSL, is unsolved.
- **`good` cannot be written.** A selector matches presence, not absence — see the limitation
  above. One of the two sides of a fraction is expressible and the other is not.
- **Percentiles come from histogram buckets**, so accuracy depends on bucket boundaries, and
  two tools asserting one criterion need not produce the same number. Whether the format has
  to say anything about resolution is open.
- **Nothing renders.** Until a document becomes some tool's own assertions, the claim that it
  is tool-agnostic is untested rather than true.
- **One shape drawn while looking at a handful of tools fits that handful.** The honest test
  is the next tool, not the last one.

---

## Where everything lives

| | |
|---|---|
| [`schema/`](schema/) | the schema, and [`schema/README.md`](schema/README.md) — the field-by-field reference |
| [`examples/`](examples/) | validated documents; the gate fails if one stops validating |
| [ARCHITECTURE.md](ARCHITECTURE.md) | how a requirement would become an outcome, and what each part may not know |
| [LAYOUT.md](LAYOUT.md) | where every kind of file lives, who may change it, and what changing it obliges |
| [`reference/glossary.md`](reference/glossary.md) | the vocabulary the format carries, each term with a rejected alternative |
| [`reference/units.md`](reference/units.md) | the closed unit list, and how the units convert |
| [`reference/names.md`](reference/names.md) | which OpenTelemetry metric and attribute names to write |
| [`reference/compatibility.md`](reference/compatibility.md) | what load testing tools actually emit — checked and dated |
| [`reference/prior-art.md`](reference/prior-art.md) | the survey of OpenSLO, Keptn, k6, Taurus, SLA4OAI and picatinny |
| [`reference/adr/`](reference/adr/) | why the format is the way it is |
| `docs/` | **ideas** — constructs the format does not have. Deliberately not linked from here |

## Where this sits relative to OpenSLO

Not a competitor. If this goes anywhere it is the counterpart of
[OpenSLO](https://github.com/OpenSLO/OpenSLO) on the other side of the release.

| | OpenSLO | OpenNFR |
|---|---|---|
| Subject | a service in production | a single load test run |
| Time frame | rolling window, weeks | one run, minutes |
| Core concept | error budget | pass / fail gate for CI |
| Answers | "are we spending reliability too fast?" | "may this build ship?" |

The Kubernetes-style envelope, the `op` values and the indicator/objective split are borrowed
deliberately, so that the two read alike.

## Contributing

Arguments are as welcome as pull requests. Particularly useful: a real requirement the format
cannot express, a reason one of the decisions above is wrong, and better names — the
vocabulary is deliberately narrow and every added word is a cost paid by every reader.

Two things to know before opening a pull request: [LAYOUT.md](LAYOUT.md) says where a change
belongs and what it obliges, and [AGENTS.md](AGENTS.md) says how changes travel — one concern
per pull request, and every one linked to an issue in a milestone.

## License

[Apache License 2.0](LICENSE)
