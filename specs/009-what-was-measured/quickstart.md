# Quickstart: checking this feature

**Feature**: `009-what-was-measured` | **Date**: 2026-08-30 | **Revised** the same day after adversarial review

Nine checks, each mapped to a success criterion. Run them from the repository root. The first is the
whole gate; the rest are what the gate cannot see, because a document that is refused leaves no trace
in `examples/` and a sentence contradicting another sentence is not a parse error.

Prerequisites: `python3` with `pyyaml` and `jsonschema`. Nothing else is needed and nothing is built.

```bash
bash scripts/verify.sh
```

Expected: `PASS`. The schema self-check prints **58 closures still reject**, unchanged — this feature
adds no schema rule. The Gatling section prints a new predicate-probe count beside its selection
counts.

---

## 1. The shape stays valid, and the gate refuses it — SC-001, SC-002

The two halves of #57's answer, and they must both hold.

```bash
cat > /tmp/metric-count.yaml <<'EOF'
apiVersion: opennfr.io/v1
kind: RequirementSet
metadata: {name: probe}
spec:
  requirements:
    - name: r
      selector: {}
      criteria:
        - metric: http.client.request.duration
          aggregation: count
          op: lte
          threshold: 20
          unit: "{request}"
EOF
python3 -c "
import json, sys, yaml
from jsonschema import Draft202012Validator as V
schema = json.load(open('schema/opennfr.io/v1/requirementset.schema.json'))
errors = sorted(V(schema).iter_errors(yaml.safe_load(open(sys.argv[1]))), key=lambda e: list(e.path))
for e in errors:
    print('/'.join(map(str, e.path)) or '(root)', ':', e.message)
sys.exit(1 if errors else 0)
" /tmp/metric-count.yaml
```

Expected: **exit 0, no output.** The format is not narrowed; the same is true of `{metric, sum}`,
`op: neq` and `{http.route: …}` today, and this shape must not become the one exception.

Then the other half — copy that document into `examples/` and run the gate:

```bash
cp /tmp/metric-count.yaml examples/zz-probe.yaml && bash scripts/verify.sh; rm examples/zz-probe.yaml
```

Expected: `FAIL`, naming `aggregation count over a metric has no equivalent`. Before this feature the
same run passed, having rendered `allRequests.count` and discarded the `metric`.

## 2. The corpus does not move — SC-004

```bash
git diff --stat main -- examples/
python3 - <<'EOF'
import subprocess
d = subprocess.run(["git", "diff", "main", "--", "schema/"], capture_output=True, text=True).stdout
changed = [l for l in d.splitlines() if l[:1] in "+-" and not l.startswith(("+++", "---"))]
print("changed schema lines:", len(changed))
print("all inside the selector description:",
      all('"description": "Selects requests by attribute' in l for l in changed))
EOF
```

Expected: the first command prints **nothing** — this feature edits no example. The second prints
`2` and `True`: the schema's only edit is the one description string. The count is stated rather
than "empty" because the description *does* change; what must not change is what the schema
validates, so a diff touching `allOf`, `properties`, `required` or any keyword means the plan has
drifted back to the reversed decision.

## 3. Three artifacts agree about `count` over a metric — SC-003

They must say three different things that do not contradict: the format admits it, Gatling cannot
compute it, the gate refuses it.

```bash
python3 - <<'EOF'
readme = open("README.md").read()
row = [l for l in readme.splitlines() if l.startswith("| `metric` |")][0]
print("format-level, the metric row:", row.split("|")[3].strip())
table = readme[readme.index("Over a metric:"):readme.index("Over the requests themselves")]
print("reach, over a metric, count/rate listed:",
      all(f"| `{a}` |" in table for a in ("count", "rate")))
gate = open("scripts/verify.sh").read()
i = gate.index('"metric": {'); block = gate[i:gate.index("},", i)]
print("gate, metric shape carries count/rate:",
      any(f'"{a}":' in block for a in ("count", "rate")))
EOF
```

Expected: `True`, `True`, `False`. The `metric` row **still lists** `count` and `rate` — it is a
claim about the format and it is true; the reach table now **lists them as rows** rather than
excluding them by silence; the gate **no longer carries them** under the metric shape. At the branch
point the third printed `True`, and the window must be bounded by the next table — unbounded, it
reads the *Over the requests themselves* rows and passes before anything is done.

## 4. `$defs/selector` answers on its own — SC-006

The test is that no second file is opened.

```bash
python3 -c "
import json
print(json.load(open('schema/opennfr.io/v1/requirementset.schema.json'))['\$defs']['selector']['description'])
"
```

Three questions must be answerable from that text alone:

1. Does `{loadtest.request.name: "*"}` trigger the anchoring rule? — **no**, `"*"` is not a name.
2. What does `{loadtest.group.name: ["*"]}` denote? — a group at that position with **any** name.
3. What may each key's value be? — string, number or boolean, save `loadtest.group.name`, which is
   the ordered list.

A reader who has to open `README.md` for any of the three fails this check.

## 5. `"*"` has one meaning, and nothing was deduplicated — SC-007, SC-010

```bash
for f in README.md GLOSSARY.md schema/opennfr.io/v1/requirementset.schema.json; do
  printf '%s: ' "$f"
  python3 -c "import sys; print(open(sys.argv[1]).read().count('is not a name'))" "$f"
done
```

Expected: `README.md: 1`, `GLOSSARY.md: 2`, schema: `1` or more. **`GLOSSARY.md` must still print
2** — the two occurrences do different jobs, one is the anchoring rule's trigger and one a premise
inside the quantifier's derivation, and deleting either leaves a claim unsupported. A `1` here means
the withdrawn deduplication was shipped anyway.

Then the reading test, which no count can do: take
`{loadtest.group.name: ["*"], loadtest.request.name: POST /checkout}` to each of the three artifacts
and ask what it denotes. All three must answer *a group at that position with any name*, and none may
also say *a group whose recorded name is `*`*.

And the duplication that must be gone:

```bash
python3 -c "
t=open('README.md').read()
i=t.index('### \`selector\` — which requests'); j=t.index('### \`criteria\` and \`guards\`')
print('target fact still in the field description:', 'no scope carries a wildcard path part' in t[i:j])
print('still in the reach row:', 'no scope carries a wildcard path part' in t[j:])
"
```

Expected: `False` then `True`.

## 6. Nothing skips — SC-002, SC-005

The probes must be able to fail. Put the defect back and confirm the gate goes red:

```bash
python3 - <<'EOF'
p = "scripts/verify.sh"; s = open(p).read()
s = s.replace('        "stddev":     ("responseTime.stdDev",     TIME, True),',
              '        "stddev":     ("responseTime.stdDev",     TIME, True),\n'
              '        "count":      ("allRequests.count",       COUNT, True),', 1)
open(p, "w").write(s)
EOF
bash scripts/verify.sh; git checkout -- scripts/verify.sh
```

Expected: `FAIL`, naming the predicate probe for `{metric, count}`. A green run here means the probe
is decorative and the two-line fix guards nothing.

Do the same for the floor: delete one predicate probe without lowering its floor, and confirm the
gate fails saying a probe that is gone cannot fail.

## 7. No verdict is deferred, and no taxonomy was added — SC-008, SC-009

```bash
python3 - <<'EOF'
import re
t = open("README.md").read()
tables = t[t.index("## What any tool can actually run"):t.index("## What is not in the format yet")]
print("deferrals inside the reach tables:", tables.count("is open"))
print("issue references inside them:", len(re.findall(r"issues/\d+", tables)))
print("kind-of-cannot markers:", tables.count("the format's limit") + tables.count("the target's limit"))
print("cannot rows:", tables.count("**cannot**"))
EOF
```

Expected, against the branch point's `1 / 2 / 0 / 15`: **0** deferrals (was 1, the #52 row);
**1** issue reference (was 2 — #52's goes, and #61's stays because it records a real limitation with
its provenance rather than deferring a verdict); **0** kind markers, unchanged, because the taxonomy
was withdrawn and every row carries its reason inline; **17** `cannot` rows, the two added to
*Over a metric*.

§ *What is unresolved* keeps its own open questions. They are open by design and are not in these
tables.

## 8. No term is added, three rejections are recorded — SC-010

```bash
python3 -c "print(sum(1 for l in open('GLOSSARY.md') if l.startswith('### ')))"
git diff main -- GLOSSARY.md | grep '^+### ' || echo 'no term added'
python3 - <<'EOF'
t = open("GLOSSARY.md").read()
want = {"aggregation": "schema",          # the rejected schema rule (#57)
        "selector":    "element of a list",  # the rejected literal reading (#77)
        "metric":      "mint"}            # the declined name (#62)
for term, keyword in want.items():
    i = t.index("### " + term + chr(10)); j = t.index("###", i + 5)
    entry = t[i:j]
    rej = entry[entry.index("*Rejected*"):] if "*Rejected*" in entry else ""
    print(f"{term:12s} rejection recorded:", keyword in rej)
EOF
```

Expected: `15`, unchanged; no added heading; and all three printing `True`. Every entry already
carried a *Rejected* line before this feature, so the presence of the marker proves nothing — the
check has to look for what was rejected. At the branch point all three print `False`.

## 9. No new claim about an external tool — SC-011

```bash
git diff main -- README.md | grep '^+' | grep -iE 'gatling|responseTime|scala|v3\.1' || echo 'no new tool claim'
```

Expected: every added line mentioning Gatling either reuses a claim already published with its date,
or is a mechanical restatement of one. Nothing may assert a new property of `responseTime`, of
`logResponse`, or of any scope, without a source and a date added in the same change. If a line does,
it must be cut — the verdict never depends on it.

## 10. What cannot be checked here

Stated so it is not mistaken for coverage:

- **That #57's answer is right.** After this feature an author can still write `{metric, count}` and
  receive no error anywhere: the schema accepts it, the gate reads only `examples/`, and no renderer
  exists. The reach rows and the probe stand in for a schema rule and are weaker than one. The
  condition that would reverse the decision is in `research.md` R2, and nobody has run it.
- **That the two refusals in #62 and #52 are right.** The checks above confirm only that each is
  written down, non-deferring, and inside the evidence the repository already carries. A second
  surveyed target is what would reopen either, and there is none.
- **That Gatling asserts what #62 and #52 report.** Neither claim is made by this feature.
- **SC-012.** Issues closed and milestone v0.6.0 assigned are checked by `scripts/check-linkage.sh`
  and by the pull requests, not by anything runnable here.
