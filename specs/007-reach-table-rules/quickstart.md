# Quickstart: validating milestone v0.4.0

**Feature**: `007-reach-table-rules` | **Date**: 2026-08-24

Every success criterion in the specification is checkable by a command or by reading one table.
This is how, in the order the commits land. Run from the repository root.

## Prerequisites

```bash
python3 -m pip install --user --break-system-packages pyyaml jsonschema
```

(`--break-system-packages` is only needed on a Homebrew-managed `python3`. Nothing new is required
beyond what `specs/004-strip-to-schema/quickstart.md` already asks for.)

## 0. The baseline, before anything changes

```bash
bash scripts/verify.sh
```

Expected today: `PASS`, with `ok    9 predicates, all assertable by Gatling` and
`ok    24 embedded examples valid, 54 closures still reject`. Every command below is a change to
what those two lines cover, so record them first.

The two link counts this section used to pin are deliberately not baselines: they rise with every
markdown file added, including the files of this feature, so a moved count says nothing.

## 1. Three sentences that are not true (#64, commit 1)

**SC-005 — the percentile row is a row.** There is no command; the check is a reading. Take the
three percentiles the schema admits and the published table does not name, and confirm each matches
exactly one row:

```bash
python3 -c 'import re; p=re.compile(r"^p\d{1,2}(\.\d+)?$"); print([(a, bool(p.match(a))) for a in ["p1","p10","p99.99","p50","p100"]])'
```

Expected: every one but `p100` matches. After the fix, the contract's row admits exactly this set
and says so by quoting the pattern; `p100` needs no row because its quantity is `max`.

**SC-006 — no citation resolves to nothing.**

```bash
grep -n 'Principle III' specs/004-strip-to-schema/contracts/gatling-reach.md
```

Expected today: two hits, at lines 67-68 and 92-93. Expected after: zero. Then confirm both rules
still give their reason:

```bash
sed -n '/numerator is part of the correspondence/,/^$/p;/Where the target is an .Int./,/^$/p' specs/004-strip-to-schema/contracts/gatling-reach.md
```

**SC-007 — apdex.**

```bash
grep -n -i 'apdex' README.md docs/ideas.md
```

Expected after: `README.md` no longer names apdex at all; `docs/ideas.md` names it in two places —
the `loadtest.*` registry list, as before, and an entry of its own under *Fields argued for and left
out*. Then confirm the ideas count still balances, which the gate does for you:

```bash
bash scripts/verify.sh 2>&1 | grep 'docs/ is'
```

Expected: `ok    docs/ is markdown-only, every idea states its condition, …`. A new entry without
its `*Would need*` clause fails this line — that is Principle VIII's gate, not a convention.

## 2. A selection row constrains its value (#60, commit 2)

**SC-003 — the reason is in the contract, not only in the gate.** Write a document whose path value
is not a string and hand it to the gate:

```bash
cat > /tmp/numeric-path.yaml <<'YAML'
apiVersion: opennfr.io/v1
kind: RequirementSet
metadata: {name: numeric-path}
spec:
  requirements:
    - name: two-hundred
      selector: {loadtest.request.name: 200}
      criteria:
        - {metric: http.client.request.duration, aggregation: p95, op: lte, threshold: 500, unit: ms}
YAML
cp /tmp/numeric-path.yaml examples/ && bash scripts/verify.sh; rm examples/numeric-path.yaml
```

Expected: `FAIL`, naming the requirement and *an assertion path part must be a string*. This is the
behaviour today as well — what changes is that the sentence is now findable in the contract:

```bash
grep -n 'is a string\|List\[String\]' specs/004-strip-to-schema/contracts/gatling-reach.md
```

Expected today: nothing. Expected after: the Selection table's value column.

**SC-004 — the probes have a floor.** After commit 2 the reach section reports its probe count:

```bash
bash scripts/verify.sh 2>&1 | grep 'assertable by Gatling'
```

Expected after: a line naming both the predicates checked and the probes rejected. Delete the probe
table and re-run — the section must FAIL, not report success over nothing. That is the same floor
`specs/005-fix-milestone-bugs` put on the schema section.

## 3. `"*"` selects every named request (#55, #56, commit 3)

**SC-002 — the blanket requirement is writable and means what it says.** The new corpus document
carries it; the gate accepts it:

```bash
bash scripts/verify.sh 2>&1 | grep 'assertable by Gatling'
cat examples/every-request-is-fast.yaml
```

Expected: the predicate count rises from 9, and the document selects
`{loadtest.request.name: "*"}`. Then confirm the contract names exactly one scope for it:

```bash
grep -n 'forAll' specs/004-strip-to-schema/contracts/gatling-reach.md
```

Expected: the **can** row, and the absent-data note attached to it. Nothing else.

**The two neighbouring selections are rejected**, and the gate says so rather than this page
saying it:

```bash
bash scripts/verify.sh 2>&1 | grep 'assertable by Gatling'
```

Expected after: `4 selection probes still rejected` — two for the string rule from § 2, two for
`"*"` carrying a path. The probes are the assertion; if either stops being rejected the line turns
into a FAIL naming the probe. `"*"` in **both** positions falls under the second of the two rows,
whose `X` is unconstrained, so it is covered without a third row.

Neither selection may be added to `examples/` — the corpus holds only documents that are
assertable, which is why these live as probes.

**SC-001 — the term changed in every place it is defined.**

```bash
grep -n -A 3 '^### selector' GLOSSARY.md
grep -n '"\*"' README.md schema/opennfr.io/v1/requirementset.schema.json
```

Expected after: all three say the same thing about `"*"` — presence, **and** each distinct value a
statement of its own — and `GLOSSARY.md` records the rejected alternative. Three documents
disagreeing about one value is the defect this milestone exists to remove; leaving one of them
behind would recreate it.

## 4. Nothing else moved

**SC-008.**

```bash
git diff main -- schema/ | grep '^[-+]' | grep -v '^[-+][-+]'
git diff --stat main -- .specify/memory/constitution.md
bash scripts/verify.sh 2>&1 | grep 'still rejects'
```

Expected: the first prints exactly one pair of lines, the `$defs/selector` description before and
after (research.md R8) — any other line means a constraint moved. The second prints nothing: the
constitution is untouched. The third prints `ok    24 embedded examples valid, 54 closures still
reject`, the same counts as today, which is what proves the description change carried no
constraint with it.
