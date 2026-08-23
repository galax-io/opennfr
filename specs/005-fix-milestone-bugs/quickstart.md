# Quickstart: validating the five fixes

**Feature**: `005-fix-milestone-bugs` | **Date**: 2026-08-23

Every success criterion in the specification is checkable by a command or a diff. This is how, in
priority order. Run from the repository root.

## Prerequisites

```bash
python3 -m pip install --user --break-system-packages pyyaml jsonschema
```

(`--break-system-packages` is only needed on a Homebrew-managed `python3`; drop it if your
`python3` accepts plain `--user`. This mirrors `specs/004-strip-to-schema/quickstart.md`'s own
prerequisite — nothing new is required.)

## 1. The gate self-check can fail (#37, P1)

```bash
bash scripts/verify.sh 2>&1 | sed -n '/still rejects/,/^$/p'
```

Expected today, before the fix: `ok 8 embedded examples valid, 7 closures still reject` — green
for the wrong reason (research.md R1). After the fix the count is 54: review found that 39 of the
41 single-constraint loosenings in the schema left the old seven probes green.

After the fix, prove it can go red: temporarily drop `"additionalProperties": false` from
`$defs/predicate` (or raise `$defs/displayName`'s `maxLength` above 200) and re-run. Expected: the
section **FAILS**, naming the closure that came loose. Revert the temporary edit and confirm the
section returns to `ok`.

Do **not** reach for `unevaluatedProperties: false` here. R2 both added a closure and removed a
redundant one; putting the redundant half back is a *tightening*, so the section stays `ok` — and
it silently reinstates the double-error behaviour #42 exists to remove, which no section of the
gate checks.

*Covers SC-001, SC-003.*

## 2. One predicate defect, one error message (#42, P2)

```bash
python3 - <<'PY'
import json
from jsonschema import Draft202012Validator as V
schema = json.load(open("schema/opennfr.io/v1/requirementset.schema.json", encoding="utf-8"))
v = V(schema)
doc = {"apiVersion": "opennfr.io/v1", "kind": "RequirementSet", "metadata": {"name": "probe"},
       "spec": {"requirements": [{"name": "r", "selector": {},
                "criteria": [{"metric": "m", "aggregation": "p99", "op": "lte",
                              "threshold": 1, "unit": "mss"}]}]}}
errs = list(v.iter_errors(doc))
print(f"{len(errs)} error(s):")
for e in errs:
    print(f"  {'/'.join(map(str, e.path))}: {e.message}")
PY
```

Expected after the fix: **1 error**, naming `unit`. (Before the fix: 2 — see research.md R2 for
the exact output.)

*Covers SC-002.*

## 3. The dead conditional is gone, nothing else moves (#38, P3)

```bash
grep -c '"description": "UNREACHABLE' schema/opennfr.io/v1/requirementset.schema.json
bash scripts/verify.sh 2>&1 | sed -n '/Examples validate against the schema/,/^$/p'
```

Expected: the first command prints `0` (the marked-unreachable block is gone); the second still
shows all three files in `examples/` as `ok`.

*Covers SC-006, and re-confirms SC-001's "zero regressions" for this fix specifically.*

## 4. The literal pattern in a code span doesn't fail the build (#43, P4)

```bash
grep -n 'a-z0-9' README.md
bash scripts/verify.sh 2>&1 | sed -n '/Internal markdown links resolve/,/^$/p'
```

Expected: `README.md`'s `name` field row shows the literal regex — starts with `^[a-z0-9]`, then an
optional group of letters, digits and hyphens closing on a letter or digit, then `$` — matching
`schema/opennfr.io/v1/requirementset.schema.json`'s `$defs/name/pattern` exactly (described here
in prose rather than quoted verbatim, for the same reason given in research.md R4: this file is
scanned by the same gate). The link-resolution section reports `ok`, not `FAIL`.

*Covers SC-004.*

## 5. The scaffolding record agrees with `AGENTS.md` (#46, P5)

```bash
D=$(mktemp -d) && mkdir -p "$D/repo" && cp AGENTS.md CLAUDE.md README.md .copier-answers.yml "$D/repo/" && git -C "$D/repo" init -q . && git -C "$D/repo" config user.email p@example.com && git -C "$D/repo" config user.name Probe && git -C "$D/repo" add -A && git -C "$D/repo" commit -qm baseline && cp AGENTS.md "$D/before.md" && (cd "$D/repo" && copier recopy --defaults --trust --overwrite --vcs-ref "$(python3 -c "import yaml;print(yaml.safe_load(open('.copier-answers.yml'))['_commit'])")" . >/dev/null 2>&1) && diff "$D/before.md" "$D/repo/AGENTS.md" && echo "IDENTICAL — the record reverts nothing"
```

There **is** an automated oracle, and it is the criterion: render the template at the recorded
`_commit` and diff the `AGENTS.md` it produces against the one on disk. Identical output means no
answer disagrees with what the template would generate from it — which is the property the file's
"never hand-edit" header protects. Run it on a **throwaway copy**, never in place: `copier recopy
--overwrite` rewrites template-managed files this repository has deliberately diverged from,
`.gitignore` among them.

*Covers SC-005.*

## 6. Everything together

```bash
bash scripts/verify.sh
```

Expected: `PASS`, all eight sections `ok`, none reporting a scan of zero files.

To check the checks rather than trusting them, mutate one schema constraint at a time and confirm
this gate reddens for each. 40 of the 41 constraints are covered; the exception,
`$defs/predicate.type`, changes no verdict when removed, so no document can probe it.

*Covers SC-001 as the final word.*
