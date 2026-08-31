# Quickstart — Validating: Identity Has One Scope

**Feature**: `011-identity-has-one-scope` | **Date**: 2026-08-31 | **Spec**: [spec.md](spec.md)

How to check that the milestone landed. Every step below is runnable from the repository root, and every claim it makes is decidable without opening Gatling — except step 5, which says so.

**Prerequisites**: `python3` with `jsonschema` and `pyyaml`, and `bash`. Nothing else; there is nothing to build.

---

## 0. Baseline — the gate is green and stays green

```bash
bash scripts/verify.sh
```

Expected: `PASS`, at **every** commit of the pull request, not only the last (FR-033).

Two lines in that output are new. § *Examples validate against the schema* ends with:

```text
  ok    identity: 6 probes still hold, 5 lists read
```

and § *Examples are assertable by Gatling* reports **15** predicate rendering probes where it reported 14:

```text
  ok    10 predicates assertable by Gatling, 10 selection probes still rejected, 5 still rendered, 10 predicate probes still rejected, 15 still rendered
```

---

## 1. The corpus did not move

```bash
git diff --stat main -- examples/
```

Expected: **empty** (FR-009, FR-021). Every published document is already valid under the reading this milestone settles on, and the corpus is not where coverage gets installed.

And the whole diff is six files plus this directory (FR-034):

```bash
git diff --name-only main | grep -v '^specs/011-'
```

Expected exactly:

```text
AGENTS.md
GLOSSARY.md
README.md
schema/opennfr.io/v1/requirementset.schema.json
scripts/identity.py
scripts/verify.sh
```

---

## 2. #58 — the scope is stated once, and it is the list

**a. Exactly one place states it.**

```bash
grep -rn "within one list" README.md GLOSSARY.md schema/ scripts/
```

Expected: one hit, in `README.md` § *A predicate*. The schema's `name` description and `GLOSSARY.md` § *criterionId* name that section without repeating the rule.

**b. Nothing still says "requirement".**

```bash
grep -rn "in one requirement\|of one requirement\|within one requirement" \
  README.md GLOSSARY.md schema/opennfr.io/v1/requirementset.schema.json
```

Expected: **no hits**. Three sites carried that wording before this milestone ([research.md](research.md) R2).

**c. The flagship example is valid under the schema's own description.**

```bash
python3 - <<'PY'
import json, yaml
schema = json.load(open("schema/opennfr.io/v1/requirementset.schema.json"))
print(schema["$defs"]["predicate"]["properties"]["name"]["description"])
doc = next(yaml.safe_load_all(open("examples/the-run-held-up.yaml")))
r = doc["spec"]["requirements"][0]
for sec in ("criteria", "guards"):
    print(sec, [p.get("name") or p.get("aggregation") for p in r.get(sec, [])])
PY
```

Expected: the description defers the scope to `README.md`, and the two lists print `['p99', 'rate']` and `['rate']` — two `rate` identities in one requirement, in two lists, and nothing in the repository calls that malformed.

**d. Read the two paragraphs back to back.** `README.md` § *A predicate*'s worked example and the sentence below it. The example's collision must be one the sentence forbids. Before this milestone it was one the sentence permits.

---

## 3. #72 — the rule fires, in both directions

Each mutation below is applied **alone**, the gate is run, and it must exit non-zero. Undo before the next. **Mutate one line, not two**: an earlier version of row 5 said "delete the call", which readers took to include the counting line beside it — and with both gone the floor fired for the wrong reason, hiding that the check alone could be dropped green.

| # | Mutation | Expected failure |
|---|---|---|
| 1 | in `scripts/identity.py`, make `duplicates()` `return []` | probes 1, 2, 3, 5 — `the identity rule is wrong: …` |
| 2 | make `duplicates()` report every pair it sees | probes 4 and 6 |
| 3 | in `predicate_id`, drop the `name` arm: `return predicate.get("aggregation")` | probes 3 and 5 |
| 4 | move `seen = set()` above the `for section` loop | probe 6, **and** `examples/the-run-held-up.yaml` |
| 5 | in the `SCHEMA` heredoc, replace the `identity.collisions(r, identity_lists)` loop with an empty iterable, **keeping every other line** | the counted floor: `read 0 lists, expected at least 5`. The count is appended to by `collisions` while it is consumed, so dropping the loop drops the count with it |
| 6 | the same, for the root-example loop in the `SELFCHECK` heredoc | its own floor: `read 0 lists … expected at least 1` |
| 7 | delete any one entry from `PROBES` | `the probe list has shrunk to 5, expected at least 6` |
| 8 | drop `pairing_why` from `render_why` | the four pairing rejection probes, which go through the composite the corpus is judged by, not through `pairing_why` alone |
| 9 | rename `GROUP_METRIC` | the README anchor: the gate's metric names must be names the page publishes |

**Every one of these is green at `7cf314a`.** That is the whole of #72: the rule was stated, claimed in `README.md` § *What the schema does not check*, and enforced by nothing that could notice its absence.

Revert between mutations with a checkout rather than the stash — this repository is worked in several worktrees at once and the stash stack is shared:

```bash
git checkout -- scripts/identity.py scripts/verify.sh
```

---

## 4. #82 — the axis exists and rejects nothing

**a. Every axis exists, and the two keys that had none are on it.**

A word-match over the section decides this in neither direction, which the baseline run proved:
`aggregation`, `threshold` and `unit` are written as headings or inside `threshold: 0.5, unit: ms`
and never as a bare backticked token, so a strict match calls three renderable axes missing; while
`name` appears all through the Selection table as `loadtest.request.name` and `loadtest.group.name`,
which are selector attributes and not the predicate key, so a loose match passes before the row
exists. The check is structural instead — the axes are subsections, and the two keys must be rows of
the new one:

```bash
python3 - <<'PY'
import re
reach = open("README.md").read().split("## What any tool can actually run", 1)[1]
print("subsections:", re.findall(r'^#### (.+)$', reach, re.M))
ident = reach.split("#### Identity", 1)[1].split("\n#### ", 1)[0] if "#### Identity" in reach else ""
for k in ("name", "displayName"):
    print(f"  {k:12} {'on the Identity axis' if f'`{k}`' in ident else 'MISSING'}")
PY
```

Expected: six axis subsections — Selection, Metrics, Aggregations, Operators, Units, **Identity** —
and neither key `MISSING`. Before this milestone there were five and both were missing.

**b. The axis rejects nothing, and something says so.**

```bash
grep -n "not carried" README.md
grep -n '"name": "p95-latency"' scripts/verify.sh
```

Expected: two `not carried` rows plus the paragraph explaining the verdict, and one rendering probe carrying a `name`.

**c. The probe is load-bearing.** Add a rejection on the key and confirm it is caught:

```bash
# in predicate_why, after the metric check:
#     if "name" in p:
#         why.append("name has no equivalent")
bash scripts/verify.sh   # must fail
```

At `7cf314a` this passes, which is why the probe exists.

---

## 5. The one claim this repository cannot check

The Identity row's reason is about Gatling's `Assertion`, and there is no Scala here and no build. It was read with `javap` from a jar on the machine that planned this feature:

```bash
javap -p -cp ~/.m2/repository/io/gatling/gatling-shared-model_2.13/0.0.11/gatling-shared-model_2.13-0.0.11.jar \
  io.gatling.commons.stats.assertion.Assertion \
  io.gatling.shared.model.assertion.AssertionResult \
  io.gatling.shared.model.assertion.AssertionMessage
```

Expected: `Assertion` carries `path`, `target` and `condition` and no label; `AssertionResult` is `Resolved(assertion, success, actualValue)` or `ResolutionError(assertion, error)`; `AssertionMessage.message` takes an `Assertion` and returns a `String`.

**This will not run on a machine without that jar, and that is the point.** The row names the version it was read at — **3.13.5**, via `gatling-shared-model` 0.0.11 — rather than the 3.15.1 the section header carries, because 3.15.1 could not be opened. A reviewer who has 3.15.1 and finds a difference has found a fact, not a formatting slip: record what 3.15.1 says and date it.

---

## 6. The milestone contract

```bash
scripts/check-linkage.sh --pr <N>
```

Expected: the pull request carries milestone **v0.8.0**, and closing links for **#58**, **#72** and **#82**, all three in that milestone.

Commits, in order (FR-035):

```text
docs(speckit): add 011-identity-has-one-scope spec/plan/tasks
fix(format): identity is unique within one list (#58)
fix(gate): the identity rule is probed in both directions (#72)
docs(format): identity has no slot in a Gatling assertion (#82)
```

---

## What "done" looks like

- `bash scripts/verify.sh` is `PASS` at all four commits.
- `examples/` is byte-identical to `main`.
- One sentence in the repository states what an identity is unique within; deleting it leaves none.
- Seven mutations in step 3 each redden the gate. All seven are green today.
- Nine predicate keys, nine rows, and an axis whose verdict is neither **can** nor **cannot**.
- `.specify/memory/constitution.md` is untouched and still 4.0.0 (FR-037).
