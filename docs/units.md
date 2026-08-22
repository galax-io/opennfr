# Units

> The format itself is [README.md](../README.md) and [the schema reference](../schema/README.md); how it works is [ARCHITECTURE.md](../ARCHITECTURE.md).

**Half of this page is enforced and half is a design.** The list of allowed units below **is**
the `unit` enumeration in
[`schema/opennfr.io/v1/requirementset.schema.json`](../schema/opennfr.io/v1/requirementset.schema.json):
a document using a unit that is not on it fails `scripts/verify.sh`. The canonicalisation and
the conversion rules are a design, and nothing implements them, because nothing yet compares a
threshold to a measurement.

`unit` is mandatory wherever there is a number ([ADR-0001 § D5](adr/0001-terminology.md)), and
the schema requires it on every predicate.

The set of units is **closed**: a subset of UCUM, not UCUM in full
([ADR-0002 § D15](adr/0002-compatibility.md)). A closed list validates as a JSON Schema
`enum` and is implemented as a conversion table rather than a grammar parser.

## Allowed units

### Time

| Unit | Meaning | Canonicalises to |
|---|---|---|
| `ns` | nanoseconds | `s` |
| `us` | microseconds | `s` |
| `ms` | milliseconds | `s` |
| `s` | seconds — **canonical**, matching semconv for `*.duration` | — |
| `min` | minutes | `s` |
| `h` | hours | `s` |

Thresholds are written in convenient units (`threshold: 500, unit: ms`); comparison happens
after canonicalisation. This removes the principal source of order-of-magnitude errors:
semconv demands seconds while every tool reports milliseconds.

### Fractions

| Unit | Meaning |
|---|---|
| `%` | percent; `0.1` means one thousandth |
| `1` | dimensionless fraction; `0.001` means one thousandth |

Both are allowed, `1` is canonical. This pair is the reason the unit is mandatory: `0.1`
without a unit reads equally well as "one thousandth" and "one tenth". OpenSLO resolves it
with two separate fields (`target` / `targetPercent`); we resolve it with one `unit`.

### Data volume

| Unit | Meaning | Canonicalises to |
|---|---|---|
| `By` | bytes — **canonical** | — |
| `KiBy` | kibibytes (1024 `By`) | `By` |
| `MiBy` | mebibytes | `By` |
| `GiBy` | gibibytes | `By` |

Binary prefixes, as in semconv. Decimal ones (`kB`, `MB`) are deliberately absent: letting
`KiBy` and `kB` coexist invites 2.4 % discrepancies.

### Counts and derived units

| Unit | Meaning |
|---|---|
| `{request}` | requests |
| `{request}/s` | requests per second — throughput |
| `{iteration}` | scenario iterations |
| `{iteration}/s` | iterations per second |
| `{vu}` | virtual users |

Annotated units in braces follow semconv style. `{request}/s` rather than `rps`:
unfamiliar, but it needs no separate dictionary of abbreviations.

## Rules

1. **The unit is mandatory.** Numbers without a `unit` are invalid, counts included.
2. **The unit must be compatible with the aggregation.** `p95` over
   `http.client.request.duration` requires a time unit; `rate` over requests requires
   `{request}/s`; `rate` over a fraction requires `%` or `1`.

   **Nothing checks this today** — an error share written in `ms` validates, which is
   [issue #39](https://github.com/galax-io/opennfr/issues/39). Part of it is reachable by the
   schema, which knows whether a predicate carries `metric`, `bad`/`good`, or neither; the
   `metric` row is not, because the schema deliberately does not know that
   `http.client.request.duration` is a time.
3. **Comparison happens after canonicalisation.** The observed value and the threshold are
   converted to the canonical unit of their group, then `op` is applied.
4. **The report preserves the original unit.** An `EvaluationReport` shows values in the
   same units the requirement used — the reader should not have to convert seconds in their
   head.
5. **Extending the list requires a format version bump.** A new unit changes the set of
   allowed `enum` values, which is a schema change.

## Deliberately unsupported

| Not supported | Why |
|---|---|
| Full UCUM | no serviceable Go library; a grammar parser for 17 units is the same mistake as a string DSL |
| Compound expressions (`By/s/{vu}`) | combinatorial explosion in the `enum`; needed combinations are added explicitly |
| Decimal volume prefixes (`kB`, `MB`) | coexisting with binary ones causes silent discrepancies |
| Units inside the value (`threshold: "500ms"`) | that is string parsing, forbidden by [ADR-0001 § D4](adr/0001-terminology.md) |
