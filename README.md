# OpenNFR

**One format for load testing requirements, written once and naming no tool.**

A performance requirement — *"checkout answers within 500 ms and fewer than 5 % of its requests
fail"* — outlives every tool that ever checks it. Today it is rewritten from scratch for each one,
in that tool's grammar, with that tool's metric names and that tool's idea of failure. OpenNFR is
an attempt to write it down once, in a form a schema can check and a person can read.

## What exists

| | |
|---|---|
| **The schema** | [`schema/opennfr.io/v1/requirementset.schema.json`](schema/opennfr.io/v1/requirementset.schema.json) — one file, [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12/schema). It decides; this page explains |
| **A validated corpus** | [`examples/`](examples/) — checked against the schema on every commit, so this page cannot drift away from what the schema accepts |
| **A gate** | `bash scripts/verify.sh` — the schema, the corpus, the links and the language |

**What does not exist**: nothing reads a document yet. There is no renderer that turns a
requirement into a load generator's own assertions, and no implementation in any language. You can
write a requirement, validate it, review it and keep it in version control. You cannot yet run it.

`docs/` holds ideas — constructs the format does not have. Nothing on this page links there.

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

Three grammars, three metric vocabularies, three notions of failure — and none survives a move to
another tool.

The obvious existing answers were surveyed and none fits. OpenSLO describes a service in
production over weeks with an error budget, not one run of minutes with a pass/fail gate. Keptn
solves the CI gate with a vocabulary entirely its own. k6 thresholds, Taurus PassFail and
gatling-picatinny's `assertionFromYaml` are tool-internal by construction. SLA4OAI is about
contracts, not runs. What OpenNFR borrows from OpenSLO is deliberate — the Kubernetes-style
envelope, the `op` values, the indicator/objective split — so that the two read alike on either
side of a release.

One fact is worth knowing before designing anything on OpenTelemetry, and it is negative. **No
load generator publishes semantic convention names.** OTLP output is common — k6, Locust,
Artillery, Gatling Enterprise all have it — but it is a transport, not a vocabulary: k6 emits
`k6_http_req_duration` in milliseconds where the convention wants `http.client.request.duration`
in seconds. "The tool speaks OTel" does not mean "the tool is compatible". *(Checked against each
tool's documentation, August 2026.)*

## A document

This is [`examples/one-request-is-fast.yaml`](examples/one-request-is-fast.yaml), whole — the
smallest thing the schema accepts:

```yaml
apiVersion: opennfr.io/v1
kind: RequirementSet
metadata:
  name: checkout-perf

spec:
  requirements:
    - name: checkout
      displayName: Checkout responds quickly
      selector:
        loadtest.request.name: POST /checkout
      criteria:
        - metric: http.client.request.duration
          aggregation: p95
          op: lte
          threshold: 500
          unit: ms
```

Read it as one sentence: *of the requests the tool records as `POST /checkout`, the 95th percentile
of the duration must be at most 500 ms.*

No tool is named anywhere in it — not in a field, a value, or a metric name. That is the point, and
it is the one property the format will not trade away.

---

## How it works

```
RequirementSet          the document — an envelope and a list
└── requirement         one human sentence about one set of requests
    ├── selector        WHICH requests — written once, for everything below it
    ├── criteria[]      what must be true of them
    └── guards[]        what must have been true of the run for that to mean anything
```

Everything under `criteria` and `guards` is the same shape, a **predicate**:

```yaml
metric: http.client.request.duration   # optional — what to measure, if anything
aggregation: p95                       # how to reduce many numbers to one
op: lte                                # how to compare it
threshold: 500                         # to what
unit: ms                               # in what
```

The last four keys are always there and are the entire grammar. There is no expression language and
no `"p95 < 500ms"` string to parse.

> **Why structure and not a string.** A grammar inside a specification has to be reimplemented,
> identically, in every backend that reads it — and it never is. `{aggregation: p95, op: lte,
> threshold: 500, unit: ms}` is more verbose than `"p95 < 500ms"` and needs no parser anybody can
> get subtly wrong. This is exactly where Keptn and Taurus visibly struggle.

### A requirement says which requests once

Every criterion and every guard beneath it is about those requests.

```yaml
- name: checkout
  displayName: Checkout is fast and reliable
  selector:
    loadtest.request.name: POST /checkout      # said once
  criteria:
    - {metric: http.client.request.duration, aggregation: p99, op: lte, threshold: 500, unit: ms}
    - {bad: {error.type: "*"},               aggregation: rate, op: lte, threshold: 5,   unit: "%"}
```

One requirement, because it is one human sentence.

> **Why the selection is not on the criterion.** It used to be, inside an `indicator` object. That
> forced a requirement about one endpoint being fast *and* reliable to become two requirements
> repeating the same selector — two objects for one sentence, and two places to edit when the
> request is renamed.

### What a criterion can be about

Every criterion is those four keys. What it *reduces* depends on which optional key it carries — and
it carries at most one:

| Carries | It is about | Aggregations that mean anything |
|---|---|---|
| `metric` | a quantity the selected requests carry — their duration, their body size | `p50`…`p99.9`, `avg`, `min`, `max`, `stddev`, `sum`, `count`, `rate` |
| `bad` or `good` | a fraction of the selected requests | `rate` — the share; `count` — how many |
| neither | the selected requests themselves | `count` — how many; `rate` — how many per second |

The schema enforces it. A percentile without a `metric` is rejected: there are no values to take a
percentile of. A percentile with `bad` is rejected: a percentile of a fraction is not a number
anyone wants. `metric` together with `bad` is rejected: one measures, the other counts.

### The same run, four ways

A run made **1000 requests** recorded as `POST /checkout`, **30** carrying `error.type`, with a
99th-percentile duration of 480 ms and a slowest of 1200 ms:

| Criterion | What is reduced | Actual | Must be | |
|---|---|---|---|---|
| `p99` of the metric | the **durations** of the 1000 requests | 480 ms | ≤ 500 ms | pass |
| `max` of the metric | the same durations | 1200 ms | ≤ 1000 ms | **fail** |
| `rate` with `bad` | 30 **÷** 1000 | 3 % | ≤ 5 % | pass |
| `count` with `bad` | how many matched `bad` | 30 | ≤ 20 | **fail** |

The top two reduce values a metric carries. The bottom two reduce counts of requests, and no metric
is involved — which is why there is no `error_rate` metric and never will be.

---

## Every field

### The envelope

```yaml
apiVersion: opennfr.io/v1     # required, this exact string
kind: RequirementSet          # required, this exact string
metadata: {...}               # required
spec: {...}                   # required
```

Borrowed from Kubernetes. `apiVersion` is how a v2 is told apart from a v1 by a consumer that has to
read both, and the shape is one every ops reader already recognises.

Unknown fields are rejected here and at every level below. The single exception is `selector`, whose
keys are attribute names and cannot be enumerated in advance.

> **Why an unknown field is an error.** Under lenient parsing a misspelled `agregation:` silently
> disables a criterion and turns the run green. That is the same silent lie as reporting success on
> missing data, and it is forbidden for the same reason.

### `metadata`

| Field | | Constraint |
|---|---|---|
| `name` | **required** | matches `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`; max 253 characters |
| `displayName` | optional | 1–200 characters, any script |
| `annotations` | optional | map of string to string |

`annotations` is the **only extension point in the format**, and the `opennfr.io/` prefix is
reserved. Anything the format does not model goes there — a ticket link, an owning team, a
paragraph of prose. Nothing in the format reads it, which is the point: an escape hatch that cannot
quietly become a feature.

### `spec.requirements`

An array, `minItems: 1`. A document with no requirements states nothing, and a document that states
nothing should not validate.

### A requirement

| Field | | Constraint |
|---|---|---|
| `name` | **required** | as `metadata.name` |
| `selector` | **required** | object; `{}` is legal and means every request |
| `criteria` | **required** | array, `minItems: 1` |
| `guards` | optional | array, `minItems: 1` if present |
| `displayName` | optional | 1–200 characters |

`selector` is required rather than defaulted. Every requirement is about *some* set of requests, and
the set "all of them" is written `selector: {}` — visibly, as a decision, rather than by leaving a
line out.

### `selector` — which requests

A map of attribute name to expected value. Every entry must match.

```yaml
selector: {}                                   # every request, said explicitly
selector: {loadtest.request.name: GET /}       # one request, by the name the tool records
selector:                                      # one request inside a group
  loadtest.group.name: [MyGroup]
  loadtest.request.name: MyRequest
selector:                                      # inside Payment, inside Checkout
  loadtest.group.name: [Checkout, Payment]
  loadtest.request.name: GET /test/id
selector: {error.type: "*"}                    # present with any value — and one bar per value
selector: {http.route: /api/v1/checkout}       # one endpoint, by route
```

| | |
|---|---|
| Keys | any string. Which attribute names are **admitted** is not enumerated by the schema and never will be — enumerating them would make every new attribute a change to the format. The schema names exactly one attribute, `loadtest.group.name`, and names it only to fix the shape of its value |
| Values | string, number or boolean. `null` is rejected. `loadtest.group.name` is the one exception: an array of strings, at least one element. An array under any other attribute is rejected |
| `loadtest.group.name` | the request's enclosing groups, outermost first, at any depth. Each element is a literal recorded name, so a group actually called `Checkout / Payment` is one element and not two. Matched by equality like every other value, which makes the list the request's whole hierarchy and not a prefix of it. `"*"` is not a recorded name, so a hierarchy carrying one spells no path |
| `"*"` | presence, not a glob. `{http.route: "/api/*"}` selects the literal string `/api/*`. On a requirement's `selector` it also quantifies: each distinct value is a statement of its own, so `{loadtest.request.name: "*"}` is one bar per named request where `{}` is one bar over all of them. Inside `bad` or `good` it does not quantify — those narrow a numerator, and a numerator is one number |

A selector cannot say an attribute is **absent**. That is why `bad: {error.type: "*"}` works and the
mirror-image `good` does not — write the failed fraction and compare with `lte`.

### `criteria` and `guards` — one shape, two meanings

Structurally identical. The difference is entirely in what a violation means:

- a violated **criterion** says *the system did not hold*;
- a violated **guard** says *the run did not happen as intended*.

```yaml
guards:
  - {name: reached-target-rate, aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"}
criteria:
  - {metric: http.client.request.duration, aggregation: p95, op: lte, threshold: 500, unit: ms}
```

> **Why guards are a construct and not a comment.** The most common lie in load testing reports is
> a test that was meant to push 200 rps, pushed 5, and shows a beautiful p95. Every criterion is
> green and the run measured nothing. None of the surveyed formats catches it. A guard is an
> ordinary checkable statement, so it fails where the target reports rather than passing quietly.
>
> It was going to yield a third outcome — *inconclusive*, "the test did not happen". That was
> withdrawn: no surveyed target has a third outcome, and a construct nothing can honour is a
> silent green of its own. What survives is the statement and the distinction.

### A predicate

| Key | Required | Type | Constraint |
|---|---|---|---|
| `aggregation` | **yes** | string | `avg` `min` `max` `count` `rate` `sum` `stddev`, or a percentile matching `^p\d{1,2}(\.\d+)?$` |
| `op` | **yes** | string | `lt` `lte` `gt` `gte` `eq` `neq` |
| `threshold` | **yes** | number | any number; not a string, so `"500ms"` is rejected |
| `unit` | **yes** | string | one of the seventeen below |
| `metric` | no | string | non-empty; not enumerated |
| `bad` | no | selector | mutually exclusive with `metric` and `good` |
| `good` | no | selector | mutually exclusive with `metric` and `bad` |
| `name` | no | string | as `metadata.name` |
| `displayName` | no | string | 1–200 characters |

**Four rules the schema enforces**, each a separate branch carrying its own description:

1. A metric is measured; a fraction is counted. Not both — `metric` with `bad` or with `good` is
   rejected.
2. At most one side of a fraction — `bad` with `good` is rejected.
3. A fraction has no percentile. With `bad` or `good`, `aggregation` is held to `rate` or `count`.
4. A percentile, mean or spread needs values, so it needs a metric. With a percentile or `avg`,
   `min`, `max`, `stddev`, `sum`, `metric` becomes required.

Note what rule 4 does *not* cover: `count` and `rate` are absent from it, which is what lets a
predicate carrying neither `metric` nor `bad` count the requests themselves.

**`aggregation`.** `p50`, `p95`, `p99`, `p99.9` and `p0.1` are all valid; **`p999` is not** — the
pattern allows at most two digits before the decimal point. Write `p99.9`. `avg` rather than `mean`:
that is the spelling in every format surveyed.

`rate` reads from the shape it is applied to. Over requests it is per second — `count / window
duration`, exactly `rate(..._count[…])` in Prometheus. Over a fraction it is the share. One word,
two readings, disambiguated by whether `bad`/`good` is present. k6 carries the identical overload
and resolves it the identical way, so the wart is borrowed rather than invented; a second word to
avoid it would cost more than it saves.

**`op`.** Words, not symbols — `<=` has to be parsed out of a string, and `>` needs escaping in half
the places a document travels through.

**`metric`.** What to measure of the selected requests. Any non-empty string. See *Names*, below.

**`bad` / `good`.** Makes the predicate a fraction. Both **narrow** the requirement's selection
rather than replacing it: the numerator is the selected requests that also match, the denominator is
the requirement's own selection, so it is never written twice.

```yaml
- {bad: {error.type: "*"}, aggregation: rate, op: lte, threshold: 5, unit: "%"}
```

**`name`.** Needed only when two predicates of one requirement would otherwise be
indistinguishable. Identity is the `name` if set, and the `aggregation` otherwise:

```yaml
guards:   [{aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"}]
criteria: [{aggregation: rate, op: lte, threshold: 400, unit: "{request}/s"}]
# both identities are "rate" — one of them must be named
```

JSON Schema cannot express that fallback, so uniqueness is checked by `scripts/verify.sh`.
`criteria` and `guards` are checked separately: a guard and a criterion may both be `rate`.

### `displayName` — optional, and inert

Free text, any script, 1 to 200 characters, allowed on `metadata`, on a requirement and on a
predicate — **not** on `spec`. `name` is restricted so a machine can point at it; `displayName` is
for a person to read. Nothing selected, measured or compared depends on it.

Keep it to the quantity, never the answer:

```yaml
- {displayName: 99th percentile, aggregation: p99, op: lte, threshold: 500, unit: ms}  # yes
- {displayName: 99th percentile under 500 ms, ...}                                     # no
```

The second is a second copy of `threshold`, and it stops being true the first time the threshold
moves. 200 characters is the bound because a display name needing more than that is prose, and prose
belongs in `annotations` where nothing pretends it is a name.

---

## Units

Closed enumeration, seventeen values, a subset of UCUM. **Required on every predicate.**

| Group | Values | Canonical |
|---|---|---|
| Time | `ns` `us` `ms` `s` `min` `h` | `s` |
| Fraction | `%` `1` | `1` |
| Data | `By` `KiBy` `MiBy` `GiBy` | `By` |
| Counts | `{request}` `{request}/s` `{iteration}` `{iteration}/s` `{vu}` | — |

Thresholds are written in convenient units — `threshold: 500, unit: ms` — and comparison happens
after canonicalisation. That removes the principal source of order-of-magnitude errors: the
conventions demand seconds, every tool reports milliseconds.

Binary data prefixes only. Decimal ones (`kB`, `MB`) are deliberately absent: letting `KiBy` and
`kB` coexist invites 2.4 % discrepancies. `{request}/s` rather than `rps`: unfamiliar, but it needs
no separate dictionary of abbreviations.

> **Why the unit is mandatory, and why the list is closed.** `0.1` without a unit reads equally well
> as one tenth and one thousandth; OpenSLO answers that with two fields (`target` /
> `targetPercent`), this format answers it with one. And a closed enumeration catches `mss` in your
> editor rather than in a report — full UCUM would need a grammar parser to reject the same typo,
> which is the string-DSL mistake wearing a different hat.

**A limitation, recorded rather than implied**: the schema does **not** check that a unit fits the
aggregation. An error share written in `ms`, or a p95 of a duration in `{vu}`, validates. Part of
that is reachable — the schema knows which of the three shapes a predicate is — and part is not,
because the schema deliberately does not know that `http.client.request.duration` is a time.

---

## Names

Metric and attribute names are **borrowed from OpenTelemetry wherever an equivalent exists**, never
invented. Names of our own are permitted only under `loadtest.*`, and only where semconv has none.
Aliases and second spellings are forbidden. Derived quantities — throughput and error rate — must
not become metrics; they are computed by aggregation from metrics that already exist.

The payoff is not tidiness: a report written in borrowed names correlates with the traces of the
same run without glue, because both sides already agree on what an endpoint is called.

### Metrics

| Name | Unit | Role |
|---|---|---|
| `http.client.request.duration` | `s` | the primary latency metric. A load generator **is** an HTTP client, so the client-side metric is the correct one — not `http.server.*`, and not the tool's own `http_req_duration` |
| `http.client.request.body.size` | `By` | volume sent |
| `http.client.response.body.size` | `By` | volume received |
| `http.server.request.duration` | `s` | when a requirement is stated over the system's own data rather than the generator's |

**Vantage point is not a detail.** A load generator measures latency as a client; a production stack
usually measures it as a server. The two numbers are not comparable, and letting one stand in for
the other is the failure this format exists to prevent.

### Selection attributes

`http.request.method`, `http.route`, `url.template`, `server.address`, `server.port`,
`http.response.status_code`, `error.type`, `network.protocol.version` — all taken verbatim.

`error.type: "*"` is how "an error" is expressed, and why there is no errors metric. OpenTelemetry
does not have one either.

### Addressing a request

| | `http.route` | `loadtest.request.name` |
|---|---|---|
| Portable across tools | yes | no — the name is arbitrary |
| Correlates with production metrics | yes | no |
| Actually emitted by load generators | almost none | all of them |

`http.route` is the better answer and almost nothing emits it. `loadtest.request.name` — k6's `name`
tag, Gatling's request name, JMeter's sampler label — is the honest fallback, at the cost that such
a document does not travel between tools unchanged.

**`loadtest.request.name` and `loadtest.group.name` are not OpenTelemetry names.** They belong to a
proposed `loadtest.*` namespace that has been submitted nowhere and that nothing emits under that
spelling. Every document in [`examples/`](examples/) depends on them, because they are the only way
any real load generator lets you address a request. That is a debt, recorded here rather than
hidden: the corpus leans on a vocabulary no standard carries.

---

## Writing one

Start from [`examples/`](examples/) and validate:

```bash
bash scripts/verify.sh
```

It needs `python3` with `pyyaml` and `jsonschema`. The schema is an ordinary Draft 2020-12 file, so
any validator in any language will do, and an editor with YAML schema support will complete the
fields as you type — every definition carries `examples` for exactly that.

To validate one document without the repository:

```bash
python3 -c "
import json, sys, yaml
from jsonschema import Draft202012Validator as V
schema = json.load(open('schema/opennfr.io/v1/requirementset.schema.json'))
errors = sorted(V(schema).iter_errors(yaml.safe_load(open(sys.argv[1]))), key=lambda e: list(e.path))
for e in errors:
    print('/'.join(map(str, e.path)) or '(root)', ':', e.message)
sys.exit(1 if errors else 0)
" my-requirements.yaml
```

It exits non-zero when the document is invalid, so `… && deploy` does what you expect. A
validator that prints errors and returns success is the silent green this format argues
against, and it would be an odd thing for this page to hand you.

### What you will see when it is wrong

| You wrote | Message |
|---|---|
| `agregation:` | `'aggregation' is a required property` |
| `p95` with no `metric` | `'metric' is a required property` |
| `p95` with `bad` | `'p95' is not one of ['rate', 'count']` |
| `metric` and `bad` together | `... should not be valid under {'anyOf': ...}` |
| `unit: mss` | `'mss' is not one of ['ns', 'us', 'ms', ...]` |
| `op: "<="` | `'<=' is not one of ['lt', 'lte', 'gt', 'gte', 'eq', 'neq']` |
| `threshold: "500ms"` | `'500ms' is not of type 'number'` |
| `name: Checkout` | `does not match` the `name` pattern above |
| a requirement with no `selector` | `'selector' is a required property` |
| `criteria: []` | `[] should be non-empty` |

One mistake is usually one message. A misspelled key is the exception, and both of its messages
name the same typo: `Additional properties are not allowed ('agregation' was unexpected)` beside
`'aggregation' is a required property`. Where a mistake breaks two rules at once — `p95` with
`bad` is both a percentile over a fraction and a percentile with no metric — you get one message
per rule, and both are real.

### What the schema does not check

- **That the unit fits the aggregation.** See *Units*, above.
- **That a metric or attribute name exists**, anywhere. Deliberate.
- **That a threshold is sensible.** `threshold: -5` for a duration validates; `neq` and `gte` make a
  negative threshold meaningful in principle.
- **That two predicates have distinct identities.** The gate checks it; the schema cannot.
- **Anything about a run.** It validates a document. Nothing here executes one.

---

## What any tool can actually run

The format is deliberately wider than anything available can execute, and the gap is worth
knowing before you write a document you cannot run.

### Gatling

**Gatling** is the target with a waiting counterparty, so it is the one this repository holds its
examples to. This section is the source: `scripts/verify.sh` § *Examples are assertable by Gatling*
implements these tables and is the only implementation, and nothing else restates them.

**Sourced** to Gatling v3.15.1's `AssertionSupport.scala`, `AssertionBuilders.scala`,
`AssertionPathParts.scala` and `AssertionModel.scala`. **Checked 2026-08-20**, and re-checked
2026-08-24 for the scope rows: `AssertionSupport.scala` has three scopes and no more — `Global`,
`ForAll`, `Details(parts)` — and only `Details` carries author strings, so `ForAll` takes no path.

A predicate that is not in the **can** column may not appear in a published example. It may still
appear in a document somebody writes — the format is not narrowed.

#### Selection

Gatling's assertion scope is `Global`, `ForAll`, or `Details(parts)` where `parts` is a path of
recorded group and request names. Nothing else is addressable — not a route, not a method, not a
status code, not an error type.

A selector matches a row on its keys **and** on its values. Partitioning this axis by key set alone
leaves the value free, and the value is what a renderer emits.

`"*"` says the attribute is present and that each distinct value is a statement of its own — a
statement about the format, whose home is § `selector` above. Here it is only mapped: the
quantifier reaches `forAll()`, and `{}` stays the pooled reading. The two are different
requirements — "the average endpoint is fast" against "no endpoint is slow" — and the table keeps
them apart.

| OpenNFR selector | Gatling | |
|---|---|---|
| `{}` | `global` | **can** |
| `{loadtest.request.name: X}`, `X` a string other than `"*"` | `details("X")` | **can** — `X` is a path part, never a pattern |
| `{loadtest.group.name: [G₁, …, Gₙ], loadtest.request.name: X}`, every part a string other than `"*"` | `details("G₁" / … / "Gₙ" / "X")` | **can** — at any depth |
| `{loadtest.request.name: "*"}` | `forAll()` | **can** — the quantified reading: one assertion per observed request, not one number over all of them |
| `{loadtest.group.name: [G₁, …, Gₙ], loadtest.request.name: "*"}` | — | **cannot** — no scope both quantifies and carries a path, so "every request inside one group" has no correspondence |
| `{loadtest.group.name: [..., "*", ...], loadtest.request.name: X}` | — | **cannot** — a group at that position with any name, and no scope carries a wildcard path part |
| `loadtest.group.name` as a string, or `[]` | — | rejected by the **schema** before this table is reached: a hierarchy has one spelling, and "no enclosing group" is said by omitting the key. The gate carries the same two rejections, so each is probed |
| any path value that is not a string | — | **cannot** — a path is `AssertionPathParts(parts: List[String])`. `{loadtest.request.name: 200}` and `{loadtest.request.name: "200"}` are different documents and only the second is renderable |
| `{http.route: ...}` | — | **cannot** |
| `{http.request.method: ...}` | — | **cannot** |
| `{http.response.status_code: ...}` | — | **cannot** |
| any other attribute | — | **cannot** |

**The value is part of the correspondence, not a detail of it.** An earlier draft partitioned this
axis by key set alone, and the gate written from it approved `{loadtest.request.name: "*"}` — which
this table then rendered as a request literally named `*`, a path matching nothing, failing the run
for a reason unrelated to what was asserted. The fraction axis learned the same lesson about `bad`,
one table down.

#### Metrics

| OpenNFR `metric` | Gatling | |
|---|---|---|
| `http.client.request.duration` | `responseTime` | **can** |
| `http.client.request.body.size`, `http.client.response.body.size` | — | **cannot** — the assertion DSL reaches response time and request counts only |
| any other | — | **cannot** |

#### Aggregations

Over a metric:

| | Gatling | |
|---|---|---|
| any percentile the schema admits — `^p\d{1,2}(\.\d+)?$` | `responseTime.percentile(n)` | **can** — target is `Int` milliseconds, so a fractional millisecond is not representable |
| `max`, `min` | `responseTime.max` / `.min` | **can** |
| `avg` | `responseTime.mean` | **can** |
| `stddev` | `responseTime.stdDev` | **can** |
| `sum` | — | **cannot** — `responseTime` offers no sum and no arithmetic that would produce one |

The percentile row is the pattern and not a range, because a row is matched exactly and a range is
not something a predicate matches. `p1`, `p10` and `p99.99` are all decidable from it, and all three
are what the gate and `percentile(Double)` already accept. `p100` falls outside the pattern — the
integer part is capped at two digits — and needs no row: the quantity it names, the slowest observed
request, is `max`.

Over the requests themselves, with no `metric` and no `bad`/`good`:

| | Gatling | |
|---|---|---|
| `count` | `allRequests.count` | **can** |
| `rate` | `requestsPerSec` | **can** — a `Double` target |

Over a fraction, with `bad` or `good`:

| | Gatling | |
|---|---|---|
| `rate` with `bad: {error.type: "*"}` | `failedRequests.percent` | **can** — percent, 0..100, not a 0..1 rate |
| `count` with `bad: {error.type: "*"}` | `failedRequests.count` | **can** |
| any narrower `bad` — a status code, an error class | — | **cannot**. `failedRequests` counts KO and nothing else; a filtered numerator has no correspondence |
| `bad: {}` | — | **cannot**. Its numerator is every selected request, which is the denominator |
| `good` in any form | — | **cannot**. `successfulRequests` exists, and no OpenNFR fraction corresponds to it, for the reason § `selector` gives |
| a percentile of a fraction | — | rejected by the schema before it reaches a target |

**The numerator is part of the correspondence, not a detail of it.** An earlier draft of this
contract listed the fraction shape without constraining `bad`, and the gate written from it
accepted `bad: {}` and arbitrary status-code filters. Neither has a `failedRequests` equivalent, so
a renderer meeting one has to pick the nearest available number and has nowhere to say it picked
one. The document asks for a share of a named failure and the run reports a share of something
else.

#### Operators

| OpenNFR `op` | Gatling | |
|---|---|---|
| `lt`, `lte`, `gt`, `gte` | `lt`, `lte`, `gt`, `gte` | **can** |
| `eq` | `is` | **can** |
| `neq` | — | **cannot** — conditions are `lt`, `lte`, `gt`, `gte`, `between`, `around`, `deviatesAround`, `is`, `in`. There is no negation, and `in` over the complement of a continuous quantity is not expressible |

#### Units

Units are per statistic, not a shared pool: a unit valid for one statistic is not thereby valid
for another. A percentile in `%` is not a Gatling assertion.

| Statistic | Accepts | Native | Target |
|---|---|---|---|
| `responseTime.*` | `ms`, `s` | milliseconds | **`Int`** |
| `failedRequests.percent` | `%`, `1` | percent, 0..100 | `Double` |
| `allRequests.count`, `failedRequests.count` | `{request}` | count | **`Int`** |
| `requestsPerSec` | `{request}/s` | per second | `Double` |
| — | `ns`, `us`, `min`, `h`, `By`, `KiBy`, `MiBy`, `GiBy`, `{iteration}`, `{iteration}/s`, `{vu}` | — | not reachable through any assertable statistic |

The last row is **derived**: it is the enumeration in § *Units* above minus every unit a statistic
here reaches. Add a unit to the format and it belongs in that enumeration; whether it appears here
follows, and is not a second decision.

**Where the target is an `Int`, the threshold converted to the native unit must be a whole
number.** `threshold: 0.5, unit: ms` is unrenderable; `threshold: 0.5, unit: s` is 500 ms and is
fine. Rounding is not an option: it moves the bar the author wrote, so the document states one
limit and the run enforces another, and the report names neither.

#### Two things Gatling cannot do at all

- **Abort a run on a violated assertion.** Assertions are evaluated after the run.
- **Fail on absent data in one case.** A `forAll()` assertion — the Selection row for
  `{loadtest.request.name: "*"}` — expands to the requests observed; if none were observed it
  yields zero results and the run exits successfully, because nothing failed and nothing was
  checked. A `details(...)` path that matches nothing behaves the opposite way and fails with a
  resolution error. Both are recorded because the difference reads as an inconsistency otherwise.
  Neither is compensated for here: a document is not obliged to carry a guard and the gate does not
  require one. This is a fact about the target, and recording one is not the same as legislating
  around it.

#### How these tables are applied

**The tables partition each axis.** A predicate is assertable only if it matches a row exactly;
anything unlisted is rejected. That direction is load-bearing. The first implementation was
written as a denylist — reject `sum`, reject `neq`, accept the rest — and defaulting to *allow*
is what let four unrenderable shapes through: a filtered `bad`, an empty `bad`, a percentile in
percent, and a fractional millisecond. A gap in these tables must fail the corpus, not pass it.

**The published corpus is restricted to that. The format is not.** `http.route`, `sum` and `neq`
are valid and no example uses them, because an example nothing can execute teaches a shape nobody
can use. `scripts/verify.sh` enforces the restriction on `examples/` and never reads the schema —
narrowing the format to one tool's feature set is the thing this project exists not to do.

## What is not in the format yet

Real needs, deliberately absent. Each would add either a dependency the format cannot honour or a
knob before anyone has asked for one. Each is argued under `docs/`, which this page does not link
into.

| Idea | Why not |
|---|---|
| `window` — measure only the steady phase | Rests on a `loadtest.phase` attribute that nothing emits |
| `baseline` + `tolerance` — "no worse than last time" | Needs stored history of previous runs, which no load generator provides |
| `severity` and `gate` — which violations fail the run | A knob. Today any failed criterion fails the run |
| `defaults` — shared settings written once | Sugar. It buys brevity and costs merge semantics |
| A result document | Nothing produces one. Designing an output before something computes it is guessing, and a guess in a schema is harder to withdraw than a guess in a note |
| A target description | Arrives with the first tool that needs it |

The load profile — stages, arrival rate, duration — is not a "yet". The tools do not agree on what
an open or a closed model does under degradation, so borrowing the construct would import the
disagreement. The word `workload` is reserved and unused for exactly that.

## What is unresolved

- **Declaring "an error occurred" across tools.** k6 signals it with a separate metric, JMeter with
  a boolean column, Gatling with KO. Expressing that declaratively, without reinventing a rules DSL,
  is unsolved.
- **`good` cannot be written.** § `selector` says why; whether the format should gain a way to state an attribute's absence is open.
- **Percentiles come from histogram buckets**, so two targets asserting one criterion need not
  produce the same number. Whether the format must say anything about resolution is open.
- **Nothing renders.** Until a document becomes some tool's own assertions, tool-agnosticism is
  untested rather than true.

---

| | |
|---|---|
| [GLOSSARY.md](GLOSSARY.md) | the terms, each with the alternative that was rejected |
| [CONTRIBUTING.md](CONTRIBUTING.md) | how to propose a change |
| [`examples/`](examples/) | validated documents |
| `docs/` | ideas — constructs the format does not have |

## License

[Apache License 2.0](LICENSE)
