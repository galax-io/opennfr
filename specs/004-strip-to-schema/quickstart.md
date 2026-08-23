# Quickstart: validating the cut

**Feature**: `004-strip-to-schema` | **Date**: 2026-08-23

Every success criterion in the specification is checkable by a command or by a count. This is how,
in order. Run from the repository root.

## Prerequisites

```bash
python3 -m pip install pyyaml jsonschema
```

## 1. The gate is green, and every section scanned something

```bash
bash scripts/verify.sh
```

Expected: `PASS`, seven sections, and **no section reporting `ok` on zero files**. Section 4 is
green for the wrong reason — see issue #37 and `contracts/verify-sections.md`; that is inherited,
not introduced.

*Covers SC-006.*

## 2. Every example is wholly assertable by Gatling

```bash
python3 - <<'PY'
import glob, yaml
SEL = [set(), {"loadtest.request.name"}, {"loadtest.group.name", "loadtest.request.name"}]
rc = 0
for f in sorted(glob.glob("examples/*.yaml")):
    for r in yaml.safe_load(open(f))["spec"]["requirements"]:
        sel = set(r["selector"])
        for section in ("guards", "criteria"):
            for p in r.get(section) or []:
                bad = []
                if sel not in SEL: bad.append(f"selector {sorted(sel)}")
                if p.get("metric", "http.client.request.duration") != "http.client.request.duration":
                    bad.append("metric " + p["metric"])
                frac = "bad" in p or "good" in p
                agg = p["aggregation"]
                if frac and agg not in {"rate", "count"}: bad.append("agg " + agg)
                if not frac and agg == "sum": bad.append("agg sum")
                if p["op"] == "neq": bad.append("op neq")
                if p["unit"] not in {"ms", "s", "%", "1", "{request}", "{request}/s"}:
                    bad.append("unit " + p["unit"])
                if bad:
                    print(f"UNRUNNABLE {f} {r['name']}/{section}: {'; '.join(bad)}"); rc = 1
print("all predicates assertable by Gatling" if rc == 0 else "FAILED")
raise SystemExit(rc)
PY
```

Expected: `all predicates assertable by Gatling`. On the tree as it stands today this prints eight
`UNRUNNABLE` lines — that is the defect being fixed, and running it before the change is the
cheapest way to see it.

*Covers SC-002. The rules it applies are `contracts/gatling-reach.md`.*

## 3. `docs/` is still isolated, and still removable

```bash
git rm -r --quiet docs && bash scripts/verify.sh ; git checkout HEAD -- docs
```

Expected: `PASS`, then the directory restored.

```bash
{ echo; echo "[probe]""(docs/ideas.md)"; } >> README.md && bash scripts/verify.sh ; git checkout README.md
```

Expected: `FAIL`, naming `./README.md links into docs/`, then the file restored. A rule that
cannot fail is not a rule.

The link is split across two shell strings rather than written whole, because the gate's own
link extractor would otherwise read this page's example as a real link and fail on it — which it
did, twice, before landing on a form that survives. That is issue #43, still open, and this is the
second workaround written for it. Worth remembering when deciding whether #43 stays open.

*Covers SC-006 and the isolation half of SC-004.*

## 4. One field, one place

```bash
grep -rl 'p\\d{1,2}' --include='*.md' . | grep -v -e 'specs/' -e '.specify/' -e '.claude/'
```

Expected: `./README.md` and nothing else — it is the only page stating what `aggregation`
**accepts**. `GLOSSARY.md` names the term and says what it displaced, which is a different job and
the intended split; a second page stating the constraint is the drift this feature exists to end.

*Covers SC-003.*

## 5. Nothing points at what was deleted

```bash
grep -rn -e 'ARCHITECTURE\.md' -e 'LAYOUT\.md' -e 'reference/' -e 'schema/README' \
  --include='*.md' --include='*.json' --include='*.yml' --include='*.yaml' --include='*.sh' . \
  | grep -vE '(^\\./)?(specs|\\.claude|\\.specify)/'
```

Expected: no output. The gate's link check catches broken *links*; this catches a path named in
prose, in a script, or inside the schema's own `description` strings — where a link check does not
look.

`specs/` and `.specify/` are excluded and the exclusion is not laziness. `specs/` is history: it
records what was decided when, against the tree of the day. The constitution names the deleted
documents on purpose, in the amendment that deletes them — a record of what went, which is the
opposite of a stale pointer.

*Covers FR-003.*

## 6. The counts

```bash
find . -name '*.md' -not -path './.git/*' -not -path './.claude/*' -not -path './.specify/*' \
  -not -path './specs/*' | sort
wc -c CONTRIBUTING.md
```

Expected: five markdown files — `README.md`, `GLOSSARY.md`, `CONTRIBUTING.md`, `docs/ideas.md`,
`AGENTS.md` — and a `CONTRIBUTING.md` of roughly two kilobytes. Before the change the same command
lists 29 files.

*Covers SC-005 and SC-008.*

## 7. The reader test

Not a command, and the only one that matters. Give the repository to somebody who has not seen it
and ask them to write a requirement for one request that must answer within 400 ms, then to prove
it is valid.

Expected: they open `README.md`, copy from `examples/one-request-is-fast.yaml`, and run
`bash scripts/verify.sh`. Three files. If they open a fourth, or ask which of two documents to
believe, the cut did not go far enough.

*Covers SC-001.*

## What this does not check

- **SC-007**, that every rule from a removed document is accounted for. That is a review against
  the disposition table in `data-model.md`, row by row. No command can do it, which is why the
  table has no blanks.
- **The schema is unchanged.** `git diff main -- schema/opennfr.io/v1/requirementset.schema.json`
  should show only the two `description` strings that name moved files.
