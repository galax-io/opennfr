# Quickstart — validating this feature

**Feature**: [003-assertion-first-format](spec.md) | **Date**: 2026-08-20

How to check that the feature does what it claims. Every scenario below is runnable and each one maps
to a success criterion, so a green run is evidence rather than a feeling.

## Prerequisites

```bash
pip install pyyaml jsonschema
```

Both are already required by the gate and already installed by CI. Nothing else is needed — this
repository ships no code to build.

```bash
bash scripts/verify.sh
```

Expected on a clean tree: `PASS`. If it reports `jsonschema not installed`, the line above was
skipped — and note that this is the gate behaving **correctly**: a check that cannot run fails, and
never reports `ok`. Every section behaves that way now; four of them did not until recently, and
scenario 5 is what stops that returning.

---

## Scenario 1 — a valid document is accepted, an invalid one is named (SC-003, FR-029)

```bash
python3 scripts/check-conformance.py conformance/parse/
```

Expected: every case in `accept/` validates, every case in `reject/` is rejected, and each rejection
matches its sidecar expectation **at the exact path**.

The check that matters is the second half. Break it deliberately:

```bash
cp conformance/parse/reject/missing-unit.yaml /tmp/probe.yaml
python3 scripts/check-conformance.py --one /tmp/probe.yaml
```

A rejection that names the wrong path is a failure, not a pass. "It got rejected somehow" is the
weaker claim the corpus exists to stop anyone making.

---

## Scenario 2 — the sum rule holds, exactly (SC-017, FR-033)

```bash
python3 scripts/check-conformance.py conformance/render/
```

For every case, `SUM` reports `rendered + unrenderable = predicates in document`. Not "approximately",
not "all accounted for" — the arithmetic, per case.

To see it bite, delete one entry from any `rendering.gatling.yaml` and re-run. The suite must go red
naming the missing predicate by identity. **A silently dropped criterion is a check that never ran
and a run that looks clean**, and this is the scenario that proves the corpus catches it.

---

## Scenario 3 — one document, two targets, different results (SC-002, FR-016)

```bash
ls conformance/render/ratio-not-assertable/
# document.yaml  rendering.gatling.yaml  rendering.k6.yaml
diff <(grep -c 'unrenderable' conformance/render/ratio-not-assertable/rendering.gatling.yaml) \
     <(grep -c 'unrenderable' conformance/render/ratio-not-assertable/rendering.k6.yaml)
```

Expected: the two renderings differ, and `document.yaml` is byte-identical for both — there is no
per-tool section, override or conditional in it. That is the whole claim of user story 2, reduced to
one `diff`.

---

## Scenario 4 — a threshold that does not convert is refused, not rounded (SC-008, FR-013)

```bash
cat conformance/render/threshold-does-not-convert/rendering.gatling.yaml
```

Expected: the predicate appears under `unrenderable`, with a reason citing the numeric-domain gap. A
value of `0.4995 s` has no exact representation in a target that takes whole milliseconds.

Rounding it would move the bar by half a millisecond and nobody would ever know. **The corpus fails
if the rendering rounds**, which is the only way this rule is worth having.

---

## Scenario 5 — the gate can actually fail (SC-014, SC-015, FR-034, FR-035)

```bash
python3 scripts/test-gate.py
```

This plants, one at a time, each defect the gate exists to catch, and requires the build to go red.
Expected output distinguishes two groups:

- **pins** — the check works; the case stops a refactor from losing it;
- **known-red** — the check is broken today, and the case is the specification of the fix.

Four cases exist because the checks they guard were **broken and then repaired** while this feature
was being specified — see [spec Appendix B](spec.md#appendix-b-four-checks-that-could-not-fail-and-what-they-cost-to-find).
They are pins now, and they are the most valuable pins in the suite: each guards a check that was
green for the life of the project without ever executing.

The sharpest single check:

```bash
python3 scripts/test-gate.py --case no-skip-anywhere
```

Runs the gate with a required library shimmed away and asserts that **no line matches `skip`**. It
asserts on the word rather than the exit code, because other sections already turn the run red and
would mask the one that quietly passes.

---

## Scenario 6 — the six statements are expressible (SC-001, FR-022, FR-023)

```bash
ls conformance/render/six-statements/
```

Expected: one document expressing all six statements the prior format could express, and the
assertions each becomes. Six for six. If one cannot be expressed, the format is narrower than the
thing it replaces, and that is a finding rather than a rounding error.

---

## Scenario 7 — no tool name leaked into the format (SC-004)

```bash
grep -riE 'gatling|k6|jmeter|locust|artillery' schema/ examples/ conformance/*/*/document.yaml
```

Expected: **no output**. A tool name is legitimate in exactly two places — `mappings/<target>.yaml`,
whose whole subject is one tool, and the dated evidence in the specification's appendices.

Note the shape of this command: it is a `grep` whose *absence* of output is the pass. That is the
silent-green shape spec Appendix B is about, so the corpus form of this check counts what it scanned
and fails when that is zero.

---

## Scenario 8 — display names are inert (SC-013, FR-007)

```bash
python3 scripts/check-conformance.py --strip-display-names conformance/render/
```

Strips every `displayName` from every document, re-derives each rendering, and requires
**byte-identical** output. A field that is documented as inert and not proved inert is a field that
quietly acquires meaning — and this one is named invitingly enough that someone will try to make the
target print it. It cannot: no surveyed target has anywhere to put an author-chosen string
([spec Appendix D](spec.md#appendix-d-why-a-precondition-cannot-be-named-in-the-targets-report)).

---

## What a green run does not prove

Worth reading before quoting a passing build. The full statement is
[spec Appendix C](spec.md#appendix-c-what-the-corpus-will-not-establish); the short version:

- **Nothing here renders.** The corpus is an oracle, unfalsified until an implementation elsewhere
  runs against it.
- **It can be uniformly wrong about a target.** If a description and a case agree and both are wrong,
  every check passes. Only a dated human-checked source stands behind that, and a machine can verify
  the date exists — never that the claim is true.
- **Display names prove nothing.** Scenario 8 checks they are inert; nothing checks they are
  accurate. A display name that contradicts its own criterion passes every check here.
