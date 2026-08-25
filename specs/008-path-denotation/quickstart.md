# Quickstart: checking this feature

Every success criterion, as something you run or read. Run from the repository root. The gate is the
whole test model, so most of this is `bash scripts/verify.sh` plus a way of proving the gate would
have caught the thing it says it caught.

**Before anything else**, the tree must be green:

```bash
bash scripts/verify.sh
```

At the time this was written it was **red**, and not for a reason in the milestone: `plan.md` links
`./research.md`, which did not exist until Phase 0 wrote it. The `docs(speckit)` commit carries
`research.md` and `tasks.md` for that reason — see [research.md](./research.md) R5.

---

## 1. The construct exists — SC-004

The three-level requirement from #53, which cannot be written at all today.

```bash
cat > /tmp/nested.yaml <<'YAML'
apiVersion: opennfr.io/v1
kind: RequirementSet
metadata:
  name: nested-groups
spec:
  requirements:
    - name: deep-request
      selector:
        loadtest.group.name: [Checkout, Payment]
        loadtest.request.name: GET /test/id
      criteria:
        - {metric: http.client.request.duration, aggregation: p99, op: lte, threshold: 1500, unit: ms}
YAML
```

Validate it with the one-liner `README.md` publishes. **Before** the change it fails with
`['Checkout', 'Payment'] is not of type 'string', 'number', 'boolean'`; after, it validates and the
gate accepts it as assertable, rendering to `details("Checkout" / "Payment" / "GET /test/id")`.

## 2. The schema decides, not only the gate — SC-005

Three shapes must be rejected **by the schema**. Two of them validate today.

```bash
python3 - <<'EOF'
import json, yaml
from jsonschema import Draft202012Validator as V
s = json.load(open('schema/opennfr.io/v1/requirementset.schema.json'))
def check(sel):
    d = {"apiVersion":"opennfr.io/v1","kind":"RequirementSet","metadata":{"name":"t"},
         "spec":{"requirements":[{"name":"r","selector":sel,
           "criteria":[{"metric":"http.client.request.duration","aggregation":"p95",
                        "op":"lte","threshold":1,"unit":"s"}]}]}}
    errs = [e.message for e in V(s).iter_errors(d)]
    print(f"{str(sel)[:52]:54} {'ACCEPT' if not errs else 'REJECT  ' + errs[0][:46]}")
check({"loadtest.group.name": ["A","B"], "loadtest.request.name": "X"})   # want ACCEPT
check({"loadtest.group.name": ["A"],     "loadtest.request.name": "X"})   # want ACCEPT
check({"loadtest.request.name": "X"})                                     # want ACCEPT
check({"loadtest.request.name": "*"})                                     # want ACCEPT
check({})                                                                 # want ACCEPT
check({"loadtest.group.name": "Checkout", "loadtest.request.name": "X"})  # want REJECT
check({"loadtest.group.name": [],         "loadtest.request.name": "X"})  # want REJECT
check({"http.route": ["a","b"]})                                          # want REJECT
check({"loadtest.group.name": ["A", 2]})                                  # want REJECT
EOF
```

Nine lines, and every verdict must match its comment. The fourth rejection is the half of the edit
that is easy to lose: `properties` goes **beside** `additionalProperties`, not instead of it, so an
array under any other attribute is still refused.

## 3. Nothing skips — SC-010

Each rule must redden the gate when deleted. Prove it by deleting one and watching it fail.

```bash
cp scripts/verify.sh /tmp/verify.bak
# delete the branch that rejects a scalar hierarchy, then:
bash scripts/verify.sh ; echo "rc=$?"          # must be non-zero
cp /tmp/verify.bak scripts/verify.sh
```

Two deletions matter more than the rest, because both fail *silently* rather than loudly:

- **the list check placed after the flattening instead of before it.** A scalar hierarchy then
  becomes one path part per character — `"Checkout"` is eight parts, all strings — and is accepted
  as an eight-deep hierarchy.
- **the `"*"` test reading `sel.values()` instead of the flattened path.** A list never equals
  `"*"`, so the branch goes dead and `{loadtest.group.name: ["*"], …}` is accepted, reinstating
  exactly the defect #55 closed.

And the direction a rejection table cannot cover: **add a one-group depth bound** to the rule and
every existing check stays green, because nothing published nests two groups. Only the positive
probe table catches it.

## 4. One home — SC-002, and the reason #68 exists

```bash
grep -rn 'forAll\|details(' --include='*.md' . | grep -v '^./specs' | grep -v '^./.claude'
```

Every hit must be inside `README.md`'s reach section. Before the change, `README.md`'s summary table
still routes `{loadtest.request.name: "*"}` through the `X` row and a renderer built from it emits
`details("*")` — the #55 defect, live on the page most readers meet.

```bash
bash scripts/verify.sh 2>&1 | grep -c FAIL     # must be 0: no link may dangle
```

The old contract path keeps resolving because the file becomes a dated redirect rather than being
deleted. Deleting it produces six failures under *Internal markdown links resolve*, in three files of
a completed spec — reproduced in [research.md](./research.md) R5.

## 5. Four homes, one rule — SC-007, SC-009

Read, not run. For a simulation recording one request name under two different hierarchies, ask each of the four
homes how many statements `{loadtest.request.name: "*"}` makes:

```bash
sed -n '/^### selector/,/^### metric/p' GLOSSARY.md
sed -n '/^### `selector`/,/^### `criteria`/p' README.md
python3 -c "import json;s=json.load(open('schema/opennfr.io/v1/requirementset.schema.json'));print(s['\$defs']['selector']['description']);print('---');print(s['\$defs']['requirement']['properties']['selector'])"
```

All must say **two** — one per recorded position — and the fourth home, the Selection row, must agree.
The schema's second node must restate none of it: it keeps only what is true of a requirement's
selector and of no other, that it is written once and binds every criterion and guard beneath it.

These are **milestone-end** criteria, satisfied at #71, not per-commit ones. #70 leaves the schema
alone deliberately — writing the definition onto the wrong node and deleting it a commit later is
add-then-remove across a stack. See [research.md](./research.md) R5.

## 6. The corpus barely moves — SC-006

```bash
git diff --stat main -- examples/
```

One value in `examples/fast-and-reliable.yaml` (`Checkout` → `[Checkout]`) and one comment in
`examples/every-request-is-fast.yaml`. `one-request-is-fast.yaml` and `the-run-held-up.yaml` are
untouched. A rule that made the corpus rewrite itself would be a rule the corpus was already
disagreeing with.

## 7. What cannot be checked here

- **"Outermost first."** The gate never renders, so element order is unverifiable from this
  repository. Stated in `path_parts()` and in the published text; a limitation, recorded rather than
  papered over.
- **The precondition on the two `details(...)` rows** — that the rendered path must not also be a
  recorded group's full hierarchy. Not knowable when a document is written, and not enforceable by a
  gate that never sees a run. It is a dated statement about the target; see
  [contracts/reach-selection.md](./contracts/reach-selection.md).
