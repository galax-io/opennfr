# Contract: the delta to Principle II, and to the argument it left behind

**Feature**: `010-constitution-catches-up` | **Issue**: [#75](https://github.com/galax-io/opennfr/issues/75)

Two edits, in two files, on one subject. `README.md` **does not change** — its sentence is the
correct one and is what Principle II's first clause is being brought to. The schema, the corpus, the
gate and `GLOSSARY.md` do not change.

## What does not change, and why that is the decision

**`README.md:424`.** After #64 it reads *"Derived quantities — throughput and error rate — must not
become metrics; they are computed by aggregation from metrics that already exist."* That is the
target of the correction, not a subject of it. It gains no counterpart to the composite clause:
§ *Names* tells an author what they may write, and a class of quantity the format cannot express is
not something an author can write. It is refused by the reach tables' `any other` Metrics row and
parked under `docs/`, which § *What is not in the format yet* already points at (FR-021).

**`GLOSSARY.md`.** No term is added, renamed or redefined. The word *composite* classifies a quantity
the format does not carry — it is not a field, a value, or a name a document may hold — and Principle I
requires a term to reach `GLOSSARY.md` before it reaches an example, a schema or an implementation.
The constitution is none of the three, and `docs/ideas.md:86` already uses the word of apdex in the
sentence being corrected (FR-026).

**The mint bar.** v0.6.0 put *"a name is minted only where something outside this repository already
records the quantity under one"* in `GLOSSARY.md` § *metric*, and the Development Workflow's *"A PR
that contradicts a decision recorded in `GLOSSARY.md` MUST amend that entry instead"* is what makes it
binding. It stays there. The new clause says which quantities are not metrics; it does not restate the
bar for minting the ones that are (FR-020).

## Delta 1 — Principle II, one bullet becomes two

`.specify/memory/constitution.md:83-84`. **Before:**

```text
- Derived quantities (throughput, error rate, apdex) MUST NOT become metrics. They are
  computed by aggregation from metrics that already exist.
```

**After:**

```text
- Derived quantities (throughput, error rate) MUST NOT become metrics. They are computed by
  aggregation from metrics that already exist.
- Composite quantities MUST NOT become metrics either, for the opposite reason: they reduce to
  no construct the format has. apdex is the case on the record, and `docs/ideas.md` carries what
  would have to become true before it could enter.
```

**Why the reason has to change with the name.** The clause is read by someone deciding whether apdex
is reachable — `APDEX` is a literal key in the NFR-YAML documents this format replaces, so the
question gets asked. The old clause told them an aggregation the format has computes it. It does not:
apdex needs a banded classification carrying a second threshold, and an aggregation weighting the
bands, and the format has neither. Throughput and an error rate each reduce to one construct that
exists — `aggregation: rate`, and a `bad` fraction. That is the difference the two bullets carry.

**Mirroring `README.md`'s deletion alone was the alternative and was rejected**: it makes the two
documents agree by making the higher-authority one silent, and Principle II is the only place the
constitution says what may not become a metric name.

**The clause states the rule, not the argument** (FR-019). Why apdex reduces to nothing stays in
`docs/ideas.md`. Copying an argument into the constitution is the mechanism both issues in this
milestone are made of.

**`docs/ideas.md` is named in a code span, never as a markdown link.** Principle VIII permits the
first and the isolation gate fails on the second.

## Delta 2 — the parked argument passes its own check

`docs/ideas.md:81`, inside the existing `**apdex**` entry. **Before:**

> And no aggregation the format has — `p*`, `max`, `min`, `avg`, `stddev`, `count`, `rate` — takes a
> weighted sum of counts.

**After** it must list the seventh name and stay true with it there (FR-022, FR-023): `sum` joins the
enumeration, and the sentence says why `sum` is not the aggregation apdex needs — it adds up the
values a metric carries, and nothing in the format classifies a request into a band or gives a band a
weight, so there is no weighted sum of counts for it to take.

**The set is checked, not remembered.** `$defs/aggregation` is a string with an `anyOf` of two
branches: an enum of seven names — `avg`, `min`, `max`, `count`, `rate`, `sum`, `stddev` — and the
pattern `^p\d{1,2}(\.\d+)?$`. `sum` was the single omission. It is not a name the repository has
forgotten: `README.md:150` and `:309` both list it and `README.md:647` carries a `cannot` row for it.

## The one gate this delta can break

`scripts/verify.sh` § *docs/ is isolated* counts ideas with `^\*\*(.+?)\*\*` and conditions with
`text.count("*Would need*")`, and fails when the two differ. The apdex entry opens at `docs/ideas.md:75`
and carries its `*Would need*` at `:88`.

**The edit must add no line-initial bold and no second `*Would need*`** (FR-024). Both counts stay at
**16** — the `26` the gate prints on that line is the number of links it scanned, not the number of
ideas it found. `bash scripts/verify.sh` and `git rm -r docs && bash scripts/verify.sh` both stay green.

## What a reviewer checks

1. Every quantity the derived clause names has one aggregation, and a reader can say which.
2. apdex is named, in the composite clause, under a reason that is true of it.
3. Principle II and `README.md` § *Names* say the same thing about every name they both mention.
4. The enumeration in `docs/ideas.md` equals the schema's aggregation enum.
5. `docs/ideas.md` has the same number of entries and conditions as before, and the gate is green.
