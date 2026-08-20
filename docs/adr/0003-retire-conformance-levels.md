# ADR-0003. Retire the conformance levels

- **Status:** accepted for the retirement; the replacement is proposed
- **Date:** 2026-08-21
- **Supersedes:** [ADR-0002 § D13](0002-compatibility.md)
- **Requires:** the constitution amendment that inverts the admission constraint. This record
  is written to land after it and is inert before it — while the old constraint stands, the
  ladder still describes the path the format has.

> The split status is deliberate and [Principle IV](../../.specify/memory/constitution.md)
> requires it. What this record **retires** is settled: the constitution has already removed
> the constraint the ladder rested on, so the ladder no longer describes anything. What
> **replaces** it — capability declared per target — is proposed, unbuilt and unvalidated, and
> is written here as the current leaning rather than as a finding.

## Context

The conformance levels are a compatibility-sensitive surface. The constitution lists them
among the things that "MUST NOT change without an ADR", which is why retiring them needs a
record of its own rather than an edit to a note.

[ADR-0002 § D13](0002-compatibility.md) defined three cumulative levels:

| Level | What the tool can do | What it unlocks |
|---|---|---|
| `report` | emits metrics reducible to canonical names | the entire format |
| `assert` | plus rendering criteria into native assertions | inline checking |
| `abort` | plus stopping the run on violation | aborting |

The ladder's load-bearing claim was its bottom rung: *"`report` is the mandatory minimum and a
complete mode: requirements, guards, baselines and reporting all work there."* That was true
**because this project intended to evaluate runs itself.** A tool that could only emit metrics
was fully served, because everything downstream — the percentiles, the comparisons, the
verdicts — happened here.

From that rung came the compatibility rule *"the format must contain no construct expressible
only at level `assert`"*, which the constitution has now inverted: a construct enters only if
at least one surveyed target can assert it exactly.

## Decision

**The ladder is retired, not re-derived.** Nothing replaces it as an ordinal.

What a target can and cannot do is declared **per capability, in that target's own
description**, each claim carrying a source and the date it was checked. Aborting a run
survives as one such declared capability rather than as a rung.

### Why retiring rather than re-deriving

**The bottom rung now guarantees nothing anything can consume.** Emitting metrics reducible to
canonical names buys a tool nothing in a format whose output is the tool's own assertions.
A ladder whose base is empty is not a ladder with a shorter base; it is a different shape.

**The remaining difference is not one ordinal.** Between the two surveyed targets, each has
capabilities the other lacks, in both directions:

| | Gatling | k6 |
|---|---|---|
| Assert per request individually | yes, over every request observed | no |
| Abort the run on violation | no | yes |
| Threshold value | whole milliseconds | float |
| Fraction convention | percent, `0..100` | rate, `0..1` |

Checked **2026-08-20**, each against the tool's own source or documentation:

- Gatling's assertion DSL — `gatling-core/src/main/scala/io/gatling/core/assertion/` at tag
  `v3.15.1`. `AssertionSupport.scala` gives three scopes, of which one ranges over every
  request observed in the run; `AssertionBuilders.scala` types response-time thresholds as
  `Int`, and offers no abort.
- k6 thresholds — Grafana's k6 documentation, `results-output` and `thresholds`. A threshold's
  right-hand side is a float, `Rate` is `0..1`, there is no per-request-individually
  quantifier, and `abortOnFail` exists.

No total order puts these two tools on rungs. Any number assigned to either would have to be
argued rather than observed, which is what
[Principle IV](../../.specify/memory/constitution.md) exists to prevent.

**A single number hides the thing a reader needs.** Someone deciding whether their requirement
will be checked needs to know *which of their predicates render and which do not*, and a level
cannot answer that. A description that partitions each axis into what the target supports and
what it does not can.

## Consequences

**A tool that cannot host assertions has no path in this format.** This is a real loss against
the previous design, in which such a tool was served completely after the run. It is recorded
here rather than absorbed, and it is the direct cost of the constitution's inverted admission
rule. The architecture amendment landing alongside this record states the same thing where a
reader of `ARCHITECTURE.md` will meet it; until that lands, this record is the only place it
is written down.

**A capability claim now costs more to make.** Under the ladder, one word covered a tool. A
description must cite a source and a date for every claim, in both directions — what the target
can assert and what it cannot. That is deliberate: an undeclared gap becomes a defect of the
description rather than a surprise at render time.

**Existing citations are not retroactively invalid.** The constitution forbids only *new*
ones. Four documents carry old references — `ARCHITECTURE.md`, `docs/GLOSSARY.md`,
`LAYOUT.md`, and [ADR-0002](0002-compatibility.md) itself — and each is corrected by the pull
request that owns it. `specs/` is a record of what was decided when: it is read as history and
left as written.

**`target-jmeter` loses its schedule.** It was planned on the strength of level `report`.
Whether that tool can host an assertion of the shape this format renders needs a fresh dated
check before it returns.

## Rejected alternatives

**Re-derive a two-rung ladder — "asserts" and "asserts and aborts".** Tempting, and wrong for
the same reason as the first: it puts one axis in a total order and leaves every other
difference — statistics, comparisons, selection, numeric domain, behaviour on an empty
selection — outside the model, where a reader will assume they do not exist. Aborting is one
capability among several and gets no special status.

**Keep `report` for tools that only emit metrics, and mark it dormant.** This preserves a rung
that describes a path the format no longer has, so that a tool can appear supported when
nothing can be rendered for it. That is the silent green
[Principle III](../../.specify/memory/constitution.md) forbids, dressed as compatibility.

**Retire the ladder silently, by deleting the note.** The levels are a compatibility-sensitive
surface. Removing one without a record is exactly the change the constitution requires an ADR
for, and a reader meeting the word in an older document would have nowhere to go.

## Open questions

1. **What a target description may declare is itself now the compatibility-sensitive surface**,
   in the ladder's place. Its shape is proposed by the assertion-first specification and
   nothing validates it yet; no schema for it exists in this repository at the time of writing.
2. **Whether a description scales.** The proposed shape enumerates capability per combination,
   which is roughly 330 lines for a target with one metric family and grows as *metrics ×
   path-kinds*. Generating it would make the file's honesty a generator's honesty. No answer.
3. **Whether two targets are enough to know the shape is neutral.** Any shape drawn while
   looking at two targets fits those two. The honest next probe is a third with native
   assertions of a different shape.

## References

- [ADR-0002 § D13](0002-compatibility.md) — the ladder this record retires
- [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) — Compatibility
  Constraints; the inverted admission rule, and the requirement that this record exist
- [`ARCHITECTURE.md`](../../ARCHITECTURE.md) — its targets section cites a level today, and is
  corrected by the amendment that accompanies this record
- The dated tool evidence behind the table above is cited inline, in *Why retiring rather than
  re-deriving*. It is repeated there rather than referenced out, so this record stays readable
  on its own.
