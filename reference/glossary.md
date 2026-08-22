# Glossary

> The format itself is [README.md](../README.md) and [the schema reference](../schema/README.md); how it works is [ARCHITECTURE.md](../ARCHITECTURE.md).

**The vocabulary the format carries.** Every term below appears in
[`schema/opennfr.io/v1/requirementset.schema.json`](../schema/opennfr.io/v1/requirementset.schema.json)
or in the gate that validates against it, and `scripts/verify.sh` rejects a document that
breaks one. This page says what each word means and what it displaced; the schema decides what
is legal.

Words for constructs the format does **not** have live in `docs/`, with the
argument for each intact. A term arrives here from there, never the other way round —
[LAYOUT.md](../LAYOUT.md#how-an-idea-becomes-part-of-the-format) has the route.

The most durable part of each entry is the *Rejected* line: an alternative that was considered
and dropped, with the reason. Those survive even when the preferred term changes. The reasoning
behind each choice is in [ADR-0001](adr/0001-terminology.md).

---

## The document

### RequirementSet

The root document, `kind: RequirementSet`. An envelope — `apiVersion`, `kind`, `metadata` —
over `spec.requirements`, which is a non-empty list and the only thing `spec` holds.

Rejected: `Suite` — carries a testing connotation, whereas requirements outlive tests.
`Policy` — pulls towards OPA/Rego. `Profile` — will be needed later for environments.

### Requirement

One human statement about one set of requests: *"checkout responds quickly and rarely fails"*.
It carries `selector` — which requests, once — and then everything that must be true of them:
`criteria`, and optionally `guards`.

A requirement is never checked on its own. Its predicates are.

Rejected: `Objective` — taken by OpenSLO for a target with an error budget, which this format
does not have. `NFR` — an acronym is unreadable as a field name.

### Criterion

One machine-checkable statement about the selected requests: `aggregation` + `op` +
`threshold` + `unit`, plus at most one of `metric`, `bad` or `good` saying what those four
reduce. The smallest unit of validation and the smallest unit of reporting.

A violated criterion means the system did not meet the requirement.

Rejected: `Assertion` — an assertion is a target's own artifact, generated from a criterion,
and the moment the word enters the document the format is nailed to one tool's semantics.
`Threshold` — that is the number inside a criterion, not the statement. `Check` — too generic,
and wanted for the act of checking.

### Guard

Structurally identical to a criterion; different in what a violation means. A criterion states
a property of the **system**; a guard states a condition of the **run** that the criterion
assumes.

The canonical case: *"p95 under 500 ms"* means nothing if the generator never reached 200 rps.
A run at 5 rps shows an excellent p95 and measures nothing, and that is the most common way a
load testing report lies.

The format states the condition and marks which entries are conditions of the run. It defines
no third report state for a violated guard: constitution 2.0.0 struck one, because no surveyed
target can produce a third outcome and a construct nothing can honour is a silent green of its
own. What survives is the statement, the distinction, and the obligation that such a run fail
where the target reports rather than pass quietly.

Rejected: `precondition` — verbose. `context` / `given` — fail to convey that this is a
checkable statement rather than metadata. `workload` — [reserved](#workload).
`inconclusive` as its outcome — see `docs/the-result-document.md`.

---

## What a predicate is about

### selector

Selects requests by attribute: a map of attribute name to expected value, every entry of which
must match. Written **once per requirement**, and every criterion and guard beneath it is about
that selection — [ADR-0003](adr/0003-selection-belongs-to-the-requirement.md).

- `{}` — every request, said explicitly. This replaces picatinny's `all` key.
- `error.type: "*"` — the attribute is present, with any value. Not a glob.

**Addressing a request.** `http.route` is preferred: portable across tools, and the same string
the service's production metrics carry. Almost no load generator emits it, so
`loadtest.request.name` — k6's `name` tag, Gatling's request name, JMeter's sampler label — is
the accepted fallback. It is the worse option and not an equal one: such names are arbitrary
and live inside a single tool.

A selector matches presence, never absence, which is why `bad` can be written and its mirror
image cannot.

Rejected: `filter` (Keptn) — too generic. `tags` — k6 terminology. `scope` — already means
"visibility". Holding the selection per criterion — reads fine for one criterion and duplicates
for every requirement with more than one thing to say.

### metric

The name of what to measure of the selected requests. **Borrowed from OpenTelemetry semantic
conventions** wherever one exists; where none does, the `loadtest.*`
proposal is the current thinking and is a note rather than a rule. No custom names, no aliases.

A load generator is an HTTP client, so the canonical latency metric is
`http.client.request.duration` — not the server-side one and not a tool-specific one such as
k6's `http_req_duration`. Reducing a tool's names to canonical ones is not the format's job.

The schema does not enumerate metric names and never will: enumerating them would make every
new metric a change to the format.

Rejected: an `indicator` object holding the metric and its own selection — see
`docs/not-in-the-format.md`.

### bad / good

Makes a predicate a fraction of the selected requests rather than a measurement of something
they carry. Both are selectors and both **narrow** the requirement's selection: the numerator
is the selected requests that also match, the denominator is the requirement's own selection,
so the denominator is never written twice. At most one of the two appears.

An error rate is `bad: {error.type: "*"}` — there is no invented errors metric, which is also
what OpenTelemetry does. From OpenSLO's `ratioMetric`, by way of
[ADR-0001 § D8](adr/0001-terminology.md).

Rejected: an `error_rate` metric — a derived quantity is not a metric, and a second vocabulary
is a second source of truth. `total` as an explicit denominator — it is the requirement's
selection by construction, and writing it twice invites the two to disagree.

---

## The predicate itself

### aggregation

The statistic that reduces many numbers to one:

```
avg | min | max | count | rate | sum | stddev
```

plus any percentile matching `^p\d{1,2}(\.\d+)?$` — `p50`, `p95`, `p99.9`. Still structure and
not an expression: a JSON Schema pattern validates it and no parser is needed.

`rate` reads from the shape it is applied to. Over requests it is per second —
`count / window duration`, exactly `rate(..._count[…])` in Prometheus. Over a fraction it is
the share. k6 carries the identical overload and resolves it the identical way, by the metric's
type, so the wart is borrowed rather than invented; a second word to avoid it would cost more
than it saves.

Rejected: `mean` — `avg` is the spelling in all four reference formats. A separate `throughput`
statistic — it is `rate`, and OpenTelemetry has no throughput metric either, for the same
reason.

### op

The comparison: `lt | lte | gt | gte | eq | neq`. As in OpenSLO.

Rejected: symbols (`<`, `<=`) — they validate poorly, need string parsing, and half of them
need escaping somewhere on the way.

### threshold and unit

`threshold` is a number — always, with no decimal strings and no embedded unit. `unit` is
**mandatory**, and drawn from a closed subset of UCUM given by enumeration. The list and the
conversions are in [units.md](units.md).

A mandatory unit settles the perennial *"is 0.1 a fraction or a percentage?"*. OpenSLO answers
it with two fields (`target` / `targetPercent`); this format answers it with one.

A closed list validates as a schema `enum` and is implemented as a conversion table.

Rejected: full UCUM — a grammar parser for seventeen units is the string-DSL mistake in a
different hat, and there is no serviceable library. `threshold: "500ms"` — that is string
parsing, forbidden by [ADR-0001 § D4](adr/0001-terminology.md).

### displayName

Optional on the document, on a requirement and on a predicate. Free text in any script, **1 to
200 characters**, with none of the identifier's constraints — `name` is restricted because
something has to point at it, and a person writing a requirement wants a sentence.

Inert by construction: it changes nothing selected, measured or compared, and two documents
differing only in their display names mean the same thing.

It does not restate a value the structured fields already carry. `99th percentile under 500 ms`
beside `threshold: 500` is a second source for one number, and the two diverge the first time
the threshold moves. Write `99th percentile` — the quantity, not the answer.

The 200-character bound is the same argument that rejects `description`: that is a phrase and
not a paragraph, and prose about a requirement belongs in `annotations`, where nothing pretends
it is a name.

Rejected: `label` — in JMeter a *label* is the sampler name, so the word already means an
address here. `title` — collides with the document's own title and with JSON Schema's `title`.
`description` — invites paragraphs where a phrase is wanted.

### name

The machine identifier: lowercase letters, digits and hyphens, at most 253 characters. Used for
the document, for a requirement, and — when needed — for a predicate.

Rejected: free-form strings — something downstream has to be able to point at one, in a report
line, a CI annotation or a URL fragment. Indices (`criterion: 0`) — they break whenever the
file is edited.

### criterionId

The identity of a predicate within one requirement: its `name` if set, otherwise its
`aggregation`. Two predicates in the same list may not share one.

JSON Schema cannot express that fallback, so `scripts/verify.sh` checks it. `criteria` and
`guards` are checked separately — a guard and a criterion may both be `rate`.

Rejected: requiring `name` on every predicate — a name is noise where `p99` and `max` already
distinguish two statements.

### annotations

`metadata.annotations`: a map of string to string, and the format's **only** extension point.
The `opennfr.io/` prefix is reserved.

Rejected: arbitrary extra fields anywhere — an unknown field is a typo far more often than an
extension, and treating it as an extension is how a misspelled `agregation:` turns a run green.

---

## Parsing rules

Enforced by the schema and by `scripts/verify.sh`. The reasoning is in
[ADR-0002 § D16–D17](adr/0002-compatibility.md); what the format accepts is a subset of YAML
rather than YAML in general.

- **Every object maps one-to-one onto JSON.** Anchors, aliases and merge keys (`&`, `*`, `<<`)
  are forbidden: they do not survive the trip to JSON, are supported inconsistently across
  parsers, and destroy line numbers in error messages.
- **An unknown field is an error**, at every level except inside a `selector`, whose keys are
  attribute names and cannot be enumerated. A typo such as `agregation:` would otherwise
  silently disable a criterion and turn the run green — the same silent lie as reporting
  success on missing data, and forbidden for the same reason.
- **The only extension point is `metadata.annotations`.**
- **Multi-document (`---`) is allowed** as a container for several objects in one file.

---

## Reserved words

### workload

**Reserved; currently unused.**

If an executable load profile — stages, arrival rate, duration — is ever added, that is what it
must be called. This is why a requirement's applicability conditions are named `guards` rather
than `workload` or `context`: so the name is not consumed by the wrong meaning.

A throughput requirement (*"sustains at least 200 rps"*) is an ordinary requirement with
`aggregation: rate`, and needs no special mechanism. Not to be confused with a load profile.

---

## Owed corrections

Recorded here rather than silently fixed, because both are the business of a pull request that
already exists.

| | |
|---|---|
| **Conformance level** — the retired `report` / `assert` / `abort` ladder | Constitution 2.0.0 retires it and forbids **new** citations. The existing ones, this glossary's included, are corrected by [issue #36](https://github.com/galax-io/opennfr/issues/36) and are deliberately not edited out one at a time |
| The path from requirement to outcome in [ARCHITECTURE.md](../ARCHITECTURE.md) | Contradicts constitution 2.0.0 in §§ 1–7; [issue #35](https://github.com/galax-io/opennfr/issues/35) |
