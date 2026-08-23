# Baseline, before 004-strip-to-schema

Recorded 2026-08-23 at commit `3080e90`. Scaffolding for the
measurement, deleted by T044.

## T001 — the gate before any change

```
== YAML sketches parse
  ok  docs/examples/checkout-perf.report.yaml
  ok  docs/examples/checkout-perf.yaml
  ok  docs/examples/mapping-jmeter.yaml
  ok  docs/examples/mapping-k6.yaml
  ok  examples/minimal.yaml
  ok  examples/six-statements.yaml
== Sketches map one-to-one onto JSON
  ok  docs/examples/checkout-perf.report.yaml
  ok  docs/examples/checkout-perf.yaml
  ok  docs/examples/mapping-jmeter.yaml
  ok  docs/examples/mapping-k6.yaml
  ok  examples/minimal.yaml
  ok  examples/six-statements.yaml
== Examples validate against the schema
  ok  examples/minimal.yaml  [RequirementSet]
  ok  examples/six-statements.yaml  [RequirementSet]
== The schema holds up its own examples, and still rejects
  ok  8 embedded examples valid, 7 closures still reject
== Internal markdown links resolve
  ok  no dangling internal links (305 checked)
== docs/ is isolated
  ok  no documentation links into docs/ (127 links checked)
== Docs are English
  ok  no non-English text in 143 files
== Examples are labelled as sketches
  ok  docs/examples/checkout-perf.report.yaml
  ok  docs/examples/checkout-perf.yaml
  ok  docs/examples/mapping-jmeter.yaml
  ok  docs/examples/mapping-k6.yaml
PASS
```

## T002 — counts, on a stated basis

Documentation = markdown outside `.git/`, `.claude/`, `.specify/`, `.github/`, `specs/`,
and excluding `CLAUDE.md` (one include line). The plan's data-model.md said 29 files; that
count had swept in the constitution, the pull-request template and `CLAUDE.md`. Corrected
here and in data-model.md rather than carried.

```
documentation markdown files              : 20
documentation bytes                       : 168591
prose describing no field of the format   : 66383  (ARCHITECTURE + LAYOUT + constitution + AGENTS)
the schema                                : 12671
```

## T003 — corpus against the Gatling contract

```
UNRUNNABLE examples/minimal.yaml orders/criteria: selector ['http.route']
UNRUNNABLE examples/six-statements.yaml checkout/criteria: selector ['http.route']
UNRUNNABLE examples/six-statements.yaml checkout/criteria: selector ['http.route']
UNRUNNABLE examples/six-statements.yaml checkout/criteria: selector ['http.route']
UNRUNNABLE examples/six-statements.yaml checkout/criteria: selector ['http.route']
UNRUNNABLE examples/six-statements.yaml checkout/criteria: selector ['http.route']
UNRUNNABLE examples/six-statements.yaml checkout/criteria: selector ['http.route']
UNRUNNABLE examples/six-statements.yaml checkout/criteria: selector ['http.route']
-- 8 unrunnable predicates
```
