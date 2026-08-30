# Glossary

The terms the format carries. Every one appears in
[`schema/opennfr.io/v1/requirementset.schema.json`](schema/opennfr.io/v1/requirementset.schema.json)
or in the gate that validates against it.

What each term *does* is in [README.md](README.md). This page says what it **means** and what it
displaced — the *Rejected* line is the durable part, because it outlives the term it protects.

Words for constructs the format does not have are in `docs/`, not here.

---

### RequirementSet

The root document, `kind: RequirementSet`. An envelope — `apiVersion`, `kind`, `metadata` — over
`spec.requirements`, a non-empty list and the only thing `spec` holds.

*Rejected*: `Suite` — carries a testing connotation, and requirements outlive tests. `Policy` —
pulls towards OPA/Rego. `Profile` — will be wanted later for environments.

### Requirement

One human statement about one set of requests. Carries `selector` once, then everything that must
be true of those requests. Never checked on its own; its predicates are.

*Rejected*: `Objective` — taken by OpenSLO for a target with an error budget, which this format
does not have. `NFR` — an acronym is unreadable as a field name.

### Criterion

One machine-checkable statement about the selected requests. A violated criterion means the system
did not meet the requirement.

*Rejected*: `Assertion` — that is a target's own generated artifact, and the moment the word enters
the document the format is nailed to one tool's semantics. `Threshold` — the number inside a
criterion, not the statement. `Check` — too generic, and wanted for the act of checking.

### Guard

Structurally identical to a criterion, different in what a violation means. A criterion states a
property of the **system**; a guard states a condition of the **run** that the criterion assumes.
A test that was meant to push 200 rps, pushed 5, and shows a beautiful p95 has green criteria and
measured nothing.

The format defines no third report state for a violated guard. No surveyed target can produce one,
and a construct nothing can honour is a silent green of its own.

*Rejected*: `precondition` — verbose. `context` / `given` — fail to convey that this is a checkable
statement rather than metadata. `workload` — reserved, see below. `inconclusive` as its outcome —
struck in constitution 2.0.0 for the reason above.

### selector

Selects requests by attribute; a map where every entry must match, by equality. Written once per
requirement. `{}` is every request, said explicitly, and reads as one statement about all of them
together.

`loadtest.group.name` is the request's enclosing groups as an ordered list, outermost first, at any
depth: `{loadtest.group.name: [Checkout, Payment], loadtest.request.name: GET /test/id}` is that
request inside `Payment` inside `Checkout`. Each element is a literal recorded name — `"*"`
excepted, which is presence there as everywhere: a group at that position with any name, never a
group whose recorded name is `*` — so a group actually called `Checkout / Payment` is one element
and not two. The list is matched by equality
like every other value, which makes it the request's whole hierarchy and not a prefix of it.
`"*"` means the attribute is present with any value — it is presence, not a glob. On a
**requirement's** selector it also quantifies: the requirement is stated once of each **request
position** the selector admits — a position being a request's enclosing groups, in order, then its
name, as the run records it. Not once per distinct value, and not once per occurrence: one name
recorded under two different hierarchies is two positions and two statements — while that same
name nested inside `[Checkout, Payment]` is one position however deep it sits — and one position
hit a thousand times is one. So `{loadtest.request.name: "*"}` is one statement per recorded position where `{}`
is one statement over all of them, and because `"*"` is not a name, no hierarchy is claimed and the
quantifier reaches every position at any depth. Inside `bad` or `good` it does not quantify — those
narrow a numerator, and a numerator is one number.

One rule governs an absent hierarchy, and it is the only rule a selector has beyond equality:
**where a selector names a request, an absent `loadtest.group.name` means the empty hierarchy** —
the request has no enclosing group. So `{loadtest.request.name: POST /checkout}` is that request at
the root, and the request of the same name inside `Checkout` is a different request, written
`{loadtest.group.name: [Checkout], loadtest.request.name: POST /checkout}`. The rule fires only
where a request is named: `{}` names none, and `"*"` is not a name. Everything here reads the same
inside `bad` and `good`, and reads inertly: the only numerator any surveyed target renders is
`{error.type: "*"}`, which names no request.

A selector otherwise matches presence, never absence. That is why `bad` can be written and its
mirror image cannot; the hierarchy is the exception because it is not a filter but a position, and
a position is complete or it is not one.

*Rejected*: a **scalar** `loadtest.group.name` — what this entry carried until #53. It stopped at
one group, so a request nested deeper was unwritable, and the spelling reached for instead,
`"Checkout / Payment"`, denotes a group whose recorded name is those eighteen characters. A separate
`loadtest.group.path` key beside it — two keys for one attribute, which Principle II forbids as a
second spelling; the name was never what was missing, the arity was. A scalar-or-array **union**
keeping the old spelling at depth one — two spellings of one hierarchy, and every row that renders
would then have to say which it meant. `loadtest.group.name: []` for "no enclosing group" — a third
spelling of what omitting the key already says, and one that reads as "unconstrained" to whoever
meets it first. `filter` (Keptn) — too generic. `tags` — k6 terminology. `scope` — already means
visibility. Holding the selection per criterion — reads fine for one criterion and duplicates for
every requirement with more than one thing to say. Quantifying over each **distinct attribute value** — what #55 and #56 wrote, retracted by #70: it
counts names while the run counts positions, so one name recorded under two hierarchies was one
statement here and two assertions there, and a document could pass on a pooled number while one of
its positions failed. Quantifying over each **occurrence** — a third granularity, and one no target
has: a position observed a thousand times yields one assertion. Reading `"*"` as presence alone,
pooled the way
`{}` is — what this entry said until #55 and #56: it settled that the attribute must be there and
left the quantifier unstated, so the only honest reading of `{loadtest.request.name: "*"}` was one
`{}` already had, and the value was a longer spelling of something else. "The average endpoint is
fast" and "no endpoint is slow" are different requirements; the format now writes both. Reading a
`"*"` **element** literally, as a group whose recorded name is `*` — what this entry said until
#77. It gave one valid document two published meanings, and it makes the token's meaning depend on
arity: presence in a scalar value, a literal name in a list element, with one selector able to
carry both at once. The argument for it is recorded because it is the strongest one and is what
would revive the reading: an element of a list is not a value of the attribute. What the reading
kept costs is stated where it falls — a group whose recorded name is literally `*` is unnameable,
as a request of that name already is.

### metric

The name of what to measure of the selected requests. Borrowed from OpenTelemetry wherever an
equivalent exists; never invented. The schema does not enumerate metric names and never will —
enumerating them would make every new metric a change to the format.

*Rejected*: an `indicator` object holding the metric and its own selection — it forced a
requirement about one endpoint being fast *and* reliable to become two requirements with the same
selector written twice. A name for **a span an author bracketed** — a business transaction across
several requests, which no semantic convention names. Declined in v0.6.0 rather than minted: a name
of our own is permitted only under `loadtest.*` and only where semconv has none, and a `loadtest.*`
name nothing emits is a vocabulary of one. The bar it did not clear is the durable part — **a name is minted only where something
outside this repository already records the quantity under one**, and one target's feature is never
sufficient grounds. A name for **what a group scope measures**, a cumulated response time, declined
for the same reason and for a second one: it would not make the shape renderable, because no scope
denotes the requests a path encloses.

### bad / good

Makes a predicate a fraction of the selected requests rather than a measurement of something they
carry. Both narrow the requirement's selection: the numerator is the selected requests that also
match, the denominator is the requirement's own selection, so the denominator is never written
twice. At most one of the two appears.

*Rejected*: an `error_rate` metric — a derived quantity is not a metric, and a second vocabulary is
a second source of truth. `total` as an explicit denominator — it is the requirement's selection by
construction, and writing it twice invites the two to disagree.

### aggregation

The statistic that reduces many numbers to one. `rate` reads from the shape it is applied to, and a
predicate has three: over the requests themselves it is per second, over a fraction it is the share,
over a `metric` it is that metric's observations per second.

*Rejected*: `mean` — `avg` is the spelling in every format surveyed. A separate `throughput`
statistic — it is `rate`, and OpenTelemetry has no throughput metric either, for the same reason.

### op

The comparison.

*Rejected*: symbols (`<`, `<=`) — they validate poorly, need string parsing, and half of them need
escaping somewhere on the way.

### threshold and unit

`threshold` is a number, always — no decimal strings, no embedded unit. `unit` is mandatory and
drawn from a closed enumeration. A mandatory unit settles "is 0.1 a fraction or a percentage?",
which OpenSLO answers with two fields and this format answers with one.

*Rejected*: full UCUM — a grammar parser for seventeen units is the string-DSL mistake in a
different hat. `threshold: "500ms"` — that is string parsing.

### displayName

Free human text beside the machine identifier. Inert: nothing selected, measured or compared
depends on it, and two documents differing only in their display names say the same thing.

*Rejected*: `label` — in JMeter a *label* is the sampler name, so the word already means an address
here. `title` — collides with JSON Schema's own. `description` — invites paragraphs where a phrase
is wanted.

### name

The machine identifier: lowercase letters, digits and hyphens. Restricted because something
downstream — a report line, a CI annotation, a URL fragment — has to be able to point at it.

*Rejected*: free-form strings — nothing could point at one reliably. Indices (`criterion: 0`) —
they break whenever the file is edited.

### criterionId

The identity of a predicate within one requirement: its `name` if set, otherwise its `aggregation`.
Two predicates in the same list may not share one. JSON Schema cannot express that fallback, so the
gate checks it.

*Rejected*: requiring `name` on every predicate — a name is noise where `p99` and `max` already
distinguish two statements.

### annotations

A map of string to string on `metadata`, and the format's only extension point. The `opennfr.io/`
prefix is reserved.

*Rejected*: arbitrary extra fields anywhere — an unknown field is a typo far more often than an
extension, and treating it as an extension is how a misspelled `agregation:` turns a run green.

---

## Reserved

### workload

**Reserved; unused.** If an executable load profile — stages, arrival rate, duration — is ever
added, that is what it must be called. This is why a requirement's applicability conditions are
`guards` and not `workload`: so the name is not consumed by the wrong meaning first.

A throughput requirement ("sustains at least 200 rps") is an ordinary requirement with
`aggregation: rate`, and needs no special mechanism. Not to be confused with a load profile.
