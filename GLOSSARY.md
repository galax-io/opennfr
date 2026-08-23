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

Selects requests by attribute; a map where every entry must match. Written once per requirement.
`{}` is every request, said explicitly. `"*"` means the attribute is present with any value — it
is presence, not a glob.

A selector matches presence, never absence. That is why `bad` can be written and its mirror image
cannot.

*Rejected*: `filter` (Keptn) — too generic. `tags` — k6 terminology. `scope` — already means
visibility. Holding the selection per criterion — reads fine for one criterion and duplicates for
every requirement with more than one thing to say.

### metric

The name of what to measure of the selected requests. Borrowed from OpenTelemetry wherever an
equivalent exists; never invented. The schema does not enumerate metric names and never will —
enumerating them would make every new metric a change to the format.

*Rejected*: an `indicator` object holding the metric and its own selection — it forced a
requirement about one endpoint being fast *and* reliable to become two requirements with the same
selector written twice.

### bad / good

Makes a predicate a fraction of the selected requests rather than a measurement of something they
carry. Both narrow the requirement's selection: the numerator is the selected requests that also
match, the denominator is the requirement's own selection, so the denominator is never written
twice. At most one of the two appears.

*Rejected*: an `error_rate` metric — a derived quantity is not a metric, and a second vocabulary is
a second source of truth. `total` as an explicit denominator — it is the requirement's selection by
construction, and writing it twice invites the two to disagree.

### aggregation

The statistic that reduces many numbers to one. `rate` reads from the shape it is applied to: over
requests it is per second, over a fraction it is the share.

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
