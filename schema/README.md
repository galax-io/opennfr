# The schema — reference

One file: [`opennfr.io/v1/requirementset.schema.json`](opennfr.io/v1/requirementset.schema.json).
It is an ordinary [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12/schema)
document, so any validator in any language will read it.

**This page states the constraints. The schema decides.** Where the two disagree the schema is
right and this page is a bug — say so in an issue.

If you have not written a document before, start with the
[README](../README.md#how-the-format-works), which explains what the fields are *for*. This
page is what you come back to when you want to know exactly what is allowed.

---

## The tree

```
RequirementSet                        object, closed
├── apiVersion    "opennfr.io/v1"     required, const
├── kind          "RequirementSet"    required, const
├── metadata                          required, object, closed
│   ├── name                          required — name
│   ├── displayName                   optional — displayName
│   └── annotations                   optional — map of string to string
└── spec                              required, object, closed
    └── requirements                  required, array, minItems 1
        └── requirement               object, closed
            ├── name                  required — name
            ├── selector              required — selector
            ├── criteria              required, array, minItems 1 — predicate
            ├── guards                optional, array, minItems 1 — predicate
            └── displayName           optional — displayName
```

**Closed** means `additionalProperties: false`: an unknown key is an error, not an ignored
one. `criteria` and `guards` close the same way, through `unevaluatedProperties: false` over
the shared `predicate` definition.

The one open object is `selector`, whose keys are attribute names. Enumerating those would
mean the format had to change every time somebody measured something new.

---

## `predicate`

The shape shared by every entry of `criteria` and every entry of `guards`. Four keys are
always required; the rest describe what the four reduce.

| Key | Required | Type | Constraint |
|---|---|---|---|
| `aggregation` | **yes** | string | one of `avg` `min` `max` `count` `rate` `sum` `stddev`, or a percentile matching `^p\d{1,2}(\.\d+)?$` |
| `op` | **yes** | string | one of `lt` `lte` `gt` `gte` `eq` `neq` |
| `threshold` | **yes** | number | any number; not a string, so `"500ms"` is rejected |
| `unit` | **yes** | string | one of the 17 units below |
| `metric` | no | string | non-empty; not enumerated |
| `bad` | no | selector | mutually exclusive with `metric` and with `good` |
| `good` | no | selector | mutually exclusive with `metric` and with `bad` |
| `name` | no | string | same pattern as any other `name` |
| `displayName` | no | string | 1–200 characters |

### The three shapes, and what each may aggregate

A predicate carries **at most one** of `metric`, `bad`, `good`. Which one it carries decides
what the aggregation is allowed to be.

| Carries | Reduces | `aggregation` may be |
|---|---|---|
| `metric` | the values of that metric, over the selected requests | anything: percentiles, `avg`, `min`, `max`, `stddev`, `sum`, `count`, `rate` |
| `bad` or `good` | a fraction of the selected requests | `rate` or `count` only |
| neither | the selected requests themselves | `count` or `rate` in practice; the schema does not narrow this case |

Four rules enforce it, and each is a separate `allOf` branch carrying its own description:

1. **A metric is measured; a fraction is counted. Not both.** `metric` with `bad`, or `metric`
   with `good`, is rejected.
2. **At most one side of a fraction.** `bad` with `good` is rejected.
3. **A fraction has no percentile.** With `bad` or `good` present, `aggregation` is held to
   `rate` or `count`.
4. **A percentile, mean or spread needs values, so it needs a metric.** With `aggregation` set
   to a percentile or to `avg`, `min`, `max`, `stddev` or `sum`, `metric` becomes required.

Note what rule 4 does *not* cover: `count` and `rate` are absent from it, which is what lets a
predicate carrying neither `metric` nor `bad` count the requests themselves.

### `rate` reads from the shape it is applied to

Over requests it is per second. Over a fraction it is the share. One word, two readings,
disambiguated by whether `bad`/`good` is present — the same overload k6 carries and resolves
the same way. It is a borrowed wart, and a second word to avoid it would cost more than it
saves.

### When a predicate needs a `name`

A predicate's identity is its `name` if set, and its `aggregation` otherwise. Two predicates in
the same list may not share an identity:

```yaml
guards:   [{aggregation: rate, op: gte, threshold: 200, unit: "{request}/s"}]
criteria: [{aggregation: rate, op: lte, threshold: 400, unit: "{request}/s"}]
# both identities are "rate" — one of them must be named
```

**JSON Schema cannot express that fallback**, so uniqueness is checked by
`scripts/verify.sh` rather than by the schema. `criteria` and `guards` are checked separately:
a guard and a criterion may both be `rate`.

---

## `selector`

An object mapping attribute name to expected value. Every entry must match; an empty object
matches everything.

| | |
|---|---|
| Keys | any string — attribute names are borrowed from OpenTelemetry, never enumerated here |
| Values | string, number or boolean. `null` is rejected |
| `{}` | every request |
| `"*"` | the attribute is present, with any value |

```yaml
selector: {}
selector: {http.route: /api/v1/checkout}
selector: {loadtest.group.name: MyGroup, loadtest.request.name: MyRequest}
selector: {error.type: "*"}
```

`"*"` is presence, not a glob: there is no pattern matching in a selector, and
`{http.route: "/api/*"}` selects the literal string `/api/*`.

A selector cannot say an attribute is **absent**. That is why `bad: {error.type: "*"}` works
and the mirror-image `good` does not — write the failed fraction and compare with `lte`.

---

## `name`

```
pattern     ^ [a-z0-9] ( [a-z0-9-]* [a-z0-9] )? $     # spaces added for legibility
maxLength   253
```

Lowercase letters, digits and hyphens; no leading or trailing hyphen. The schema's pattern has
no spaces in it — they are here only because a bare `]` followed by `(` reads as a markdown
link to the repository's own link checker. The same definition is
used for `metadata.name`, a requirement's `name` and a predicate's `name`. It is restrictive
because something — a report line, a CI annotation, a URL fragment — has to be able to point
at it.

## `displayName`

String, 1 to 200 characters, any script. Allowed on `metadata`, on a requirement and on a
predicate; **not** on `spec`.

It is inert: nothing selected, measured or compared depends on it, and two documents differing
only in their display names say the same thing.

It should not restate a value the structured fields already carry. `99th percentile under
500 ms` beside `threshold: 500` is a second source for one number, and the two diverge the
first time the threshold moves.

## `annotations`

`metadata.annotations` only. A map of string to string, and the format's only extension point.
The `opennfr.io/` prefix is reserved.

## `unit`

A closed enumeration of 17, a subset of UCUM. Conversions and the argument for closing the
list are in [`docs/units.md`](../docs/units.md).

| Group | Values | Canonical |
|---|---|---|
| Time | `ns` `us` `ms` `s` `min` `h` | `s` |
| Fraction | `%` `1` | `1` |
| Data | `By` `KiBy` `MiBy` `GiBy` | `By` |
| Counts | `{request}` `{request}/s` `{iteration}` `{iteration}/s` `{vu}` | — |

Closed rather than parsed: `mss` is then a validation error in your editor rather than a
disagreement three orders of magnitude wide between two consumers. Full UCUM would need a
grammar, which is the string-DSL mistake wearing a different hat.

## `op`

`lt` `lte` `gt` `gte` `eq` `neq`. Words, not symbols — `<=` has to be parsed out of a string,
and `>` needs escaping in half the places a document travels through.

## `aggregation`

`avg` `min` `max` `count` `rate` `sum` `stddev`, plus any percentile matching
`^p\d{1,2}(\.\d+)?$`.

So `p50`, `p95`, `p99`, `p99.9` and `p0.1` are all valid, and **`p999` is not** — the pattern
allows at most two digits before the decimal point. Write `p99.9`.

`avg` rather than `mean`: that is the spelling in every format the survey covers.

---

## What the schema rejects, and what you will see

Every message below is what a Draft 2020-12 validator actually emits today.

| You wrote | Message |
|---|---|
| `agregation:` | `'aggregation' is a required property` |
| `p95` with no `metric` | `'metric' is a required property` |
| `p95` with `bad` | `'p95' is not one of ['rate', 'count']` |
| `metric` and `bad` together | `... should not be valid under {'anyOf': ...}` |
| `bad` and `good` together | `... should not be valid under {'required': ['bad', 'good']}` |
| `unit: mss` | `'mss' is not one of ['ns', 'us', 'ms', ...]` |
| `op: "<="` | `'<=' is not one of ['lt', 'lte', 'gt', 'gte', 'eq', 'neq']` |
| `threshold: "500ms"` | `'500ms' is not of type 'number'` |
| `name: Checkout` | `'Checkout' does not match` — followed by the `name` pattern above |
| a requirement with no `selector` | `'selector' is a required property` |
| `criteria: []` | `[] should be non-empty` |

> **A wart worth knowing.** When a predicate is wrong for any reason, the closure over it
> fails too, and you get a second message alongside the useful one:
> `Unevaluated properties are not allowed ('aggregation', 'metric', 'op', 'threshold', 'unit'
> were unexpected)` — listing keys that are all perfectly valid. It is noise from how
> `unevaluatedProperties` composes with a failed `$ref`. Read the other message.

---

## What the schema does **not** check

Published rather than implied, because a constraint people believe in and nothing enforces is
worse than one nobody claims.

- **That the unit fits the aggregation.** `{metric: http.client.request.duration,
  aggregation: p95, unit: "{vu}"}` validates. So does an error share in `ms`. This is
  [issue #39](https://github.com/galax-io/opennfr/issues/39).
- **That a metric name exists**, anywhere. `metric` is any non-empty string, deliberately —
  see [README § What the format deliberately does not define](../README.md#what-the-format-deliberately-does-not-define).
- **That an attribute name exists.** Same, for selector keys.
- **That a threshold is sensible.** `threshold: -5` for a duration validates. There is no
  minimum, because `neq` and `gte` make a negative threshold meaningful in principle.
- **That two predicates have distinct identities.** `scripts/verify.sh` checks it; the schema
  cannot.
- **Anything about a run.** The schema validates a document. Nothing in this repository yet
  executes one.

---

## Running it

```bash
bash scripts/verify.sh
```

Needs `python3` with `pyyaml` and `jsonschema`. It validates every document in
[`examples/`](../examples/), checks that the schema's own embedded `examples` still satisfy the
definitions that carry them, checks predicate identity uniqueness, and — separately from all of
that — checks the repository's links and language.

To validate a document of your own without the repository:

```bash
python3 -c "
import json, sys, yaml
from jsonschema import Draft202012Validator as V
schema = json.load(open('schema/opennfr.io/v1/requirementset.schema.json'))
for e in V(schema).iter_errors(yaml.safe_load(open(sys.argv[1]))):
    print('/'.join(map(str, e.path)) or '(root)', ':', e.message)
" my-requirements.yaml
```

**In an editor.** Every definition in the schema carries `examples`, so an editor with YAML
schema support completes the fields and offers a shape as you type. Point it at
`schema/opennfr.io/v1/requirementset.schema.json`; the schema's `$id` is
`https://opennfr.io/schema/v1/requirementset.schema.json`, which is an identifier and not yet a
URL that resolves.
