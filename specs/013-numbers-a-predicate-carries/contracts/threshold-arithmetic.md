# Contract: the conversion is exact decimal arithmetic (#59)

**Feature**: [spec.md](../spec.md) | **Plan**: [plan.md](../plan.md) | **Commit 3 of 4**

Closes [#59](https://github.com/galax-io/opennfr/issues/59). Satisfies FR-007 … FR-017f.

**Files**: `README.md` § *Units* (under § *Gatling*), `GLOSSARY.md` § *threshold and unit*, and
`scripts/verify.sh`. The schema is read and **not** written.

---

## What is wrong today

Three things, in one paragraph of one table.

**1. The whole-number rule has no arithmetic model.** It forbids rounding on the ground that
rounding moves the bar, and then leaves undecided the question of whether a value *is* whole:

| document | exact decimal | IEEE-754 double |
|---|---|---|
| `1.001 s` | `1001` → renders | `1000.9999999999999` → refused |
| `1.003 s` | `1003` → renders | `1002.9999999999999` → refused |
| `1.005 s` | `1005` → renders | `1004.9999999999999` → refused |

Neither renderer is wrong under the published text.

**2. The `Target` column attributes the `Int` to the target.** It is the type of the DSL entry
point; the `Assertion` a renderer may construct itself carries a `double`
([research.md](../research.md) R3, re-read 2026-09-01 at 3.13.5 / 0.0.11).

**3. One cell in that column is wrong.** `AssertionWithPathAndCountMetric.count` returns
`AssertionWithPathAndTarget[Long]`; the table says `Int`.

## The change — `README.md` § *Units*

**1. The arithmetic, stated** — a new paragraph immediately before the whole-number rule:

> **The conversion is exact decimal arithmetic on the value the threshold denotes**, never binary
> floating-point multiplication: `threshold: 1.001, unit: s` is 1001 ms and renders, where a
> double would compute 1000.9999999999999 and refuse. A renderer that has already parsed the
> threshold into a binary float conforms by recovering the shortest decimal that round-trips that
> float and computing exactly from there — that decimal is the literal's value for any threshold
> of at most fifteen significant digits. Keeping the document's source text is **not** required;
> JSON and YAML parsers discard it.

**2. The `Target` column** becomes the DSL entry point's type, and says so. One cell changes:

| Statistic | Target, before | Target, after |
|---|---|---|
| `responseTime.*`, `groupCumulatedResponseTime.*` | `Int` | `Int` |
| `failedRequests.percent` | `Double` | `Double` |
| `allRequests.count`, `failedRequests.count` | `Int` | **`Long`** |
| `requestsPerSec` | `Double` | `Double` |

with a sourcing line naming `AssertionBuilders.scala` at `gatling-core` **3.13.5**,
`gatling-core-java` **3.13.5** and `gatling-shared-model_2.13` **0.0.11**, **checked 2026-09-01** —
its own versions and its own date, not § *Gatling*'s 3.15.1 header.

**3. The whole-number rule** stops naming a Scala type:

> **Where the target is integral, the threshold converted to the native unit must be a whole
> number.** `threshold: 0.5, unit: ms` is unrenderable; `threshold: 0.5, unit: s` is 500 ms and is
> fine; `aggregation: count, threshold: 20.5` is unrenderable for the same reason. Rounding is not
> an option: it moves the bar the author wrote, so the document states one limit and the run
> enforces another, and the report names neither.

**4. A recorded non-relaxation**, so the next reader meets the argument rather than reopening it:
the `Int` and the `Long` are the types of the two DSL entry points, a renderer constructing the
assertion model itself does not pass through them, and the rule is **not** relaxed for it —
reach is a property of the target, not of how a renderer is built.

## The change — `GLOSSARY.md` § *threshold and unit*

The entry's existing *Rejected* line gains one sentence, naming both grounds (FR-012):

> A **precision bound on `threshold`** — `multipleOf`, or a stated significant-digit limit. It
> narrows the schema to one target's reach, which § *aggregation* already refused in these words
> when #57 proposed it for `count` and `rate`; and it does not work, because `multipleOf` is
> itself evaluated in binary floating point — `multipleOf: 0.001` rejects `1.001`, `1.003` and
> `1.005` under `jsonschema` 4.26.0, the very values the bound was proposed to admit.

**Why here and not in § *Units*.** An earlier draft of this contract put it in the reach section.
That is a **target description** — Principle VI defines one as what a renderer reads to turn a
requirement document into that target's assertions — and why the format declined to constrain its
own schema is not something a renderer reads. `GLOSSARY.md` is where this repository records a
rejected alternative, § *threshold and unit* is the entry that owns the field, and its *Rejected*
line already carries the two neighbouring decisions: full UCUM, and `threshold: "500ms"`. A
contributor proposing a bound is editing `$defs/threshold` and reading the term that defines it.

**No entry is added, renamed or redefined**, which is what [spec.md](../spec.md) FR-027 requires:
*"Where a decision above bears on an existing entry, it is recorded at the entry's own Rejected
line rather than as a new term."* The spec provided for this from the start; this contract had
narrowed it.

## The change — `scripts/verify.sh`

**1. A comment on the round-trip**, so replacing it reads as a change to the rule:

```python
# Exact decimal arithmetic on the value the threshold denotes -- README > Gatling > Units states
# it, and this is not an accident of Python. str() of a float is its shortest round-tripping
# decimal, which is the literal's value for any threshold of at most 15 significant digits; a
# plain `p["threshold"] * factor` would refuse 1.001 s, which the rule admits.
value = Fraction(str(p["threshold"])) * factor
```

**2. One rendering probe** in `PREDICATE_RENDERS` — the disagreement itself:

```python
{**RENDERABLE, "threshold": 1.001, "unit": "s"},
```

Two keys and no more. `threshold` and `unit` move together because the subject is the conversion —
`1.001 ms` is not whole and would test the wrong thing — and nothing else moves, because
`scripts/verify.sh:863` states the convention this table is written to: a probe is *"a mutation of
one renderable predicate so a probe differs from a passing one in exactly the thing it tests."*
An aggregation override here would test nothing.

**3. Two rejection probes** in `PREDICATE_PROBES` — the count rows' integral flag, which no probe
reaches today:

```python
({"aggregation": "count", "op": "lte", "threshold": 20.5, "unit": "{request}"},
 "threshold 20.5 {request} is 41/2 for allRequests.count, whose target is an integer"),
({"bad": BAD, "aggregation": "count", "op": "lte", "threshold": 20.5, "unit": "{request}"},
 "threshold 20.5 {request} is 41/2 for failedRequests.count, whose target is an integer"),
```

**One per count row, and this contract said one probe until implementation.** The two rows sit in
different shapes — `allRequests.count` under `requests`, `failedRequests.count` under `fraction` —
so a single probe reaches one row and leaves the other exactly as unguarded as it was. The revert
set below is what caught it.

**4. Floors**: rejection `16` → `20`, rendering `16` → `18`.

## What must NOT change

- **No message string.** The count refusal's existing wording — *"whose target is an integer"* —
  stays true and correct under `Long`. The gate reasons over an `integral` flag and never over the
  word `Int`, which is why the gate was right and only the page was wrong.
- **No document changes renderability.** `20.5 {request}` is unrenderable before and after;
  `1.001 s` renders before and after. The rule's bite is identical (FR-017b).
- **The schema gains no precision bound** (FR-011), and the reason it does not lands in
  `GLOSSARY.md` rather than here (FR-012) — see the section above.
- **`GLOSSARY.md` gains no entry and loses none.** One sentence joins an existing *Rejected* line;
  no term changes, so Development Workflow's same-PR obligation is not triggered by a rename. The
  entry's existing rejection of `threshold: "500ms"` stays and is not contradicted: this rule is
  about the value a number denotes, not about admitting a decimal string.
- **The `0.1 ms` rejection probe and its message survive byte-identical** (FR-015). T017 rewords
  the whole-number rule and the tempting companion edit is to reword the gate's message to match;
  it must not be made. The floors do not protect this probe — a deletion plus two additions still
  clears them — so it is checked directly.

## Acceptance

```bash
bash scripts/verify.sh
```

`20 predicate probes still rejected, 18 still rendered`, whole gate **PASS**.

| revert | expected failure |
|---|---|
| `Fraction(str(...))` → `p["threshold"] * factor` | the `1.001 s` rendering probe |
| the `0.1 ms` probe's message reworded to match T017 | nothing — which is why FR-015 is checked by diff, not by the gate |
| `allRequests.count`'s `True` → `False` in `TABLE` | the plain `20.5 {request}` probe |
| `failedRequests.count`'s `True` → `False` in `TABLE` | the `bad: BAD` `20.5 {request}` probe |
| any probe deleted | the floor |

And by diff: `git diff main -- scripts/verify.sh` shows the `0.1 ms` probe and its message
untouched (FR-015), and `git diff main -- GLOSSARY.md` shows exactly one added sentence inside an
existing *Rejected* line — no heading added, none removed (FR-027).

And by reading: § *Units* answers "how is the conversion computed?" without opening
`scripts/verify.sh`; every cell of the `Target` column matches `AssertionBuilders.scala`; the
whole-number rule names no Scala type; and § *Units* carries no statement about the schema.
