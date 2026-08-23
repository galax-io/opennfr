# Phase 1: what changes, in which file

**Feature**: `005-fix-milestone-bugs` | **Date**: 2026-08-23

No new entity is introduced — this feature corrects diagnostics, dead schema logic, a gate false
positive and a stale scaffolding record. What follows is the inventory FR-012 depends on: every
artifact touched, what changes in it, and what does not.

## Artifacts

| Artifact | Touched by | What changes | What does not |
|---|---|---|---|
| `scripts/verify.sh` — "The schema holds up its own examples, and still rejects" section | R1 (#37) | The seven probes' shared base document gains the fields it was missing (`selector`; `metric` where `max` requires it) **and loses the `indicator` key `requirement` never declared**; a precondition assertion that it validates before mutation; a floor that fails rather than reports `ok` if no probe is left | The section's `ok`/`FAIL` reporting shape, and six of the seven probe mutations. **The seventh changes**: "displayName on a series" mutated `indicator.distribution`, a construct the schema no longer has, so it is repointed to the document root — the same closure class, the one place still uncovered |
| `schema/opennfr.io/v1/requirementset.schema.json` → `$defs/predicate` | R2 (#42) | Gains `"additionalProperties": false` | `required`, `properties`, its own `allOf` (the four cross-field rules), `examples` |
| `schema/opennfr.io/v1/requirementset.schema.json` → `$defs/requirement.properties.criteria.items` | R2 (#42) | `{"allOf": [{"$ref": "#/$defs/predicate"}], "unevaluatedProperties": false}` → `{"$ref": "#/$defs/predicate"}` | — |
| `schema/opennfr.io/v1/requirementset.schema.json` → `$defs/requirement.properties.guards.items` | R2 (#42), R3 (#38) | Same collapse to a plain `$ref` (R2); the no-op `"properties": {}` it currently carries and `criteria.items` does not is removed as part of the same collapse (R3) — see research.md R2 sequencing note | `minItems`, `description` |
| `schema/opennfr.io/v1/requirementset.schema.json` → `$defs/requirement.allOf` | R3 (#38) | Deleted entire (the unreachable `if`/`then` block) | Everything else in `$defs/requirement` |
| `scripts/mdlinks.py` — **new file** | R4 (#43) | One definition of a markdown link — fence and code-span stripping, target extraction, path resolution — plus the fixtures the gate holds it to on every run | — |
| `scripts/verify.sh` — "Internal markdown links resolve" section | R4 (#43) | Extraction moves to `scripts/mdlinks.py`; a target beginning with `/` resolves against the repository root rather than escaping to the filesystem root; an unreadable file fails as a file instead of aborting the section on a traceback | Detection of a genuine broken link outside code spans/fences; the `found == 0` anti-silent-green guard |
| `scripts/verify.sh` — "`docs/` is isolated" section | R4 (#43) | Uses the same `scripts/mdlinks.py` definition, so a code span naming a path under `docs/` is no longer counted or reported as a link into it | The three clauses it checks, and its `scanned == 0` guard |
| `README.md` — `metadata.name` field row | R4 (#43) | Prose paraphrase replaced with the literal, unmodified `name` pattern regex | Every other field row |
| `README.md` — the "wart" paragraph | R2 (#42) | Deleted: it told readers to expect `Unevaluated properties are not allowed`, which the schema can no longer emit. Replaced with what is true — a bad value gives one message, a misspelled key gives two, both naming it | The ten rows of the error table above it, each re-validated against the current schema |
| `.copier-answers.yml` | R5 (#46) | Eight answers corrected to match `AGENTS.md`/`README.md`: the six issue #46 tabulates (`architecture`, `structure`, `stack_detail`, `dep_manifest`, `role`, `test_model`), `project_tagline` from its closing prose, and `commands` — which the issue does not name but the round-trip test in FR-011 proves still reverts a corrected path | `_commit`, `_src_path`, `org_repo`, `project_name`, `do_git`, `run_speckit`, `stack`, `build_test_cmd`, `publish_mechanism`, `release_notes_tool` |
| `.gitignore` | R4 (#43) | Ignores `__pycache__/` and `*.pyc`: importing `scripts/mdlinks.py` writes bytecode beside it | Every existing rule |
| `AGENTS.md` — Commands block | R4 (#43) | One line: the link check is no longer `grep-based`, and saying so was falsified by R4 itself | Every other section. `.copier-answers.yml` is otherwise brought to match `AGENTS.md`, not the reverse |

## What every fix must leave unchanged (FR-012)

- `examples/fast-and-reliable.yaml`, `examples/one-request-is-fast.yaml`,
  `examples/the-run-held-up.yaml` — all three continue to validate. Checked by dry-run for R2 and
  R3 (research.md); R1, R4 and R5 do not touch the schema or the corpus at all.
- The schema's own embedded `examples` (`$defs/selector`, `$defs/predicate`, `$defs/requirement`)
  continue to validate against the definitions they illustrate. Checked by dry-run for R3.
- `bash scripts/verify.sh` exits 0 after all five fixes land (SC-001).

## Ordering constraint

R2 and R3 both edit `$defs/requirement.properties.guards.items` and
`$defs/requirement.properties.criteria.items`. Per `AGENTS.md`'s "1 issue = 1 commit", these ship
as two separate commits (issue #42, issue #38); whichever lands second must be diffed against the
schema *as the first left it*, not against the schema as it reads today, or its documented "delete
the no-op `properties: {}`" instruction may target a key that R2 already removed by replacing the
whole `items` value. `tasks.md` sequences R2 before R3 for exactly this reason — R3's change
becomes a smaller, purely-subtractive diff (delete the `allOf` block) once R2 has already
collapsed `items` to a plain `$ref`.
