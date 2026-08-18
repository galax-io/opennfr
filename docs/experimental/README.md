# Experimental area

**Status: experimental. Last true: 2026-08-18.**

Nothing here is part of the format. Nothing here is on a compatibility-sensitive surface.
Everything here can be deleted in one operation without changing anything outside this
directory — and if that ever stops being true, this area has failed at the one thing it exists
to do.

## Rules for this directory

1. **Nothing outside this directory may link into it.** Outside references name a path in
   prose, inside a code span, never as markdown link syntax. `scripts/verify.sh` fails the
   build on any dangling internal link, so a single inbound link would turn the removal test
   red.
2. **Markdown only, no YAML.** This keeps the area clear of the sketch-label check, which is
   hardcoded to `docs/examples/*.yaml`.
3. **Every file states its own status**, what would promote it, what would retire it, and the
   date the statement was last true.

The removal test, which is a command rather than an aspiration:

```bash
git rm -r docs/experimental && bash scripts/verify.sh
```

Expected: `PASS`.

---

## What is parked here

### The monitoring direction

**Status**: experimental, unverified, unscheduled. **Owner**: the `monitoring-experiment`
follow-up specification. **Last true**: 2026-08-18.

The claim: one requirement document, unchanged in every character, can be turned into both a
query that returns the canonical measurement and a native monitoring definition, for Datadog,
Prometheus, VictoriaMetrics and InfluxDB — four query languages, one markup.

**Nothing in this repository verifies any part of that.** No committed file mentions any of the
four products. The claim is stated so it can be argued with, not because it is believed.

Three unknowns are why it is parked rather than scheduled:

- **Four percentile machineries.** Prometheus and VictoriaMetrics interpolate from fixed
  histogram buckets, Datadog uses a sketch, InfluxDB depends on how the data was written. The
  same criterion can pass on one and fail on another with identical underlying traffic.
- **A change of vantage point.** A load generator measures latency as a client; a production
  stack usually measures it as a server. The two numbers are not comparable, and letting one
  stand in for the other is the failure the whole format exists to prevent.
- **Constructs that do not cross.** A guard about the load generator has no meaning against
  production traffic, and run phases do not exist there.

**Promotion conditions** — all must hold before any part of this leaves this directory:

1. One requirement document, unchanged, assembles a query the backend's own documentation
   confirms is valid, for **all four** backends. Three of four is not promotion; it is a
   narrower scope, and narrowing amends the architecture first.
2. Each of those four checks is dated and sourced, per Principle IV.
3. The query-assembly vocabulary is declared as structure, validatable without a bespoke
   parser, and does not embed a backend's query language as free text — Principle V.
4. Every construct that cannot cross is listed by name, with what happens when it is
   encountered.
5. Supporting the direction adds at most one new document kind to the format.

**Retirement conditions** — any one is sufficient:

- No conforming query can be assembled for two or more of the four backends without an embedded
  query string, which Principle V forbids.
- The vocabulary needed to serve all four turns out to be a per-backend template set, in which
  case it is not one markup and the premise is dead.
- Twelve months pass with no promotion condition met.

Deleting this direction requires changing nothing in the normative core, nothing in any tool
mapping, and nothing in the conformance corpus. That property is the point of the area, and it
is checked by the command above.
