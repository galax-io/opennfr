# Quickstart: verifying this feature landed correctly

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-08-18

This feature ships documents, so most of its success criteria are read rather than run. Four
are genuinely executable, and they are the ones worth wiring into review. Everything below
runs from the repository root.

## Prerequisites

- `python3` with PyYAML, or `verify.sh` skips its YAML check and says so
- `gh`, authenticated, for the milestone and linkage checks
- A clean working tree — several checks below delete files

---

## 1 · The standing gate

```bash
bash scripts/verify.sh
```

Expected: `PASS`. Four checks — YAML sketches parse, internal markdown links resolve, no
non-English text in `*.md` or `*.yaml`, every example announces itself as a sketch.

**Two blind spots to know before trusting it.** The link check filters `grep -v '^\./\.'`, so
anything under a dot-prefixed root directory — `.specify/`, `.claude/`, `.github/` — has its
outgoing links unchecked; the checked set is twelve files. And the sketch-label check is
hardcoded to `docs/examples/*.yaml`, so a tool mapping moved to `mappings/` silently stops
being checked.

---

## 2 · SC-007 — the experimental area really is removable

The only criterion in this feature that is a command rather than a reading.

```bash
git rm -r docs/experimental && bash scripts/verify.sh
```

Expected: `PASS`. Then `git restore --staged docs/experimental && git checkout docs/experimental`.

A `FAIL` naming a dangling link means some document linked into the parked area, and "parked"
was never true — the fix is in the referring document, not in the criterion.

---

## 3 · SC-004 — the constitution and its templates agree

```bash
grep -n 'Version.*:' .specify/memory/constitution.md | tail -1
grep -n 'constitution.md.*v[0-9]' .specify/templates/plan-template.md
grep -c '^### [IVX]*\.' .specify/memory/constitution.md
grep -n 'principles above' .specify/memory/constitution.md
```

Expected, after the amendment PR: the footer reads `1.1.0`; the template's pointer reads
`v1.1.0` and not `v1.0.0`; the principle count matches the number the Compliance review
sentence claims. A stale version pointer in the template is exactly the drift this amendment
exists to prevent, so it fails the check rather than being tidied later.

---

## 4 · SC-013 — every introduced word has exactly one home

```bash
for w in target "artifact class" "component role" "compatibility-sensitive surface" \
         "experimental area" "follow-up spec" "monitoring backend"; do
  printf '%-34s glossary:%s layout:%s\n' "$w" \
    "$(grep -ci "$w" docs/GLOSSARY.md)" "$(grep -ci "$w" docs/layout.md)"
done
```

Expected: each word is defined in exactly one of the two. Colliding words — `target`,
`monitoring backend` — in the glossary; governance words in the layout document. A word
defined in both is a defect, not a convenience.

Also check the dropped word did not survive:

```bash
grep -rn '\bbindings\?\b' docs/ --include='*.md' | grep -v 'binding constraint'
```

Expected: no hits naming an artifact class. The noun was dropped for `tool mapping`.

---

## 5 · SC-010 — nothing executable shipped

```bash
git diff --name-only main...HEAD | grep -vE '\.(md)$|^specs/|^\.gitignore$'
```

Expected: empty. This feature produces markdown and nothing else — no schema, no validator, no
parser, no renderer, no tool mapping.

---

## 6 · Linkage — the check that fails first if preconditions were skipped

```bash
bash scripts/check-linkage.sh --pr
gh api repos/galax-io/opennfr/milestones --jq '.[] | "\(.number) \(.title) [\(.state)]"'
```

Every PR needs milestone `v0.2.0` and a registered closing link to an issue in that milestone.
**No issue exists for any part of this feature yet**, so this is the check that fails on the
first PR if the issues were not created first.

---

## Read, not run

These carry the feature's actual value and no script can judge them.

| Criterion | How to judge |
|---|---|
| SC-001 | Hand `docs/architecture.md` to someone who has read nothing else. Ask them to trace one requirement to an outcome, naming every component. A step they cannot name is a defect |
| SC-002 | Three walkthroughs over `docs/examples/checkout-perf.yaml`, one per load generator, present and followable. The four monitoring backends are a dated unverified claim — check it says so |
| SC-003 | Every principle in the amendment resolves to a file and section without git history |
| SC-005 | Every artifact class has one home; count classes with none or two |
| SC-006 | Hand `docs/layout.md` to a newcomer; ask which files they would create to add a tool |
| SC-008 | Enumerate the follow-up list's deliverables; count files claimed twice |
| SC-014 | Count clauses and table rows in `docs/architecture.md` carrying no binding/proposed marker |

---

## Known-failing on purpose

The walkthroughs will document four defects that already exist in the reference example and
the gate vocabulary — a perfect run that reports `noData` and fails; an unmeasurable guard that
fails for the wrong reason; a `skipped` status no gate key handles; an `indicatorRef` pointing
at the wrong kind. They are **declared, not fixed**: fixing them changes the format, which
FR-025 puts out of scope. Each needs its own issue. A walkthrough that steps over them silently
would be the very failure Principle III exists to prevent.
