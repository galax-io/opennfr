# OpenNFR — Agent Guide

Design notes toward an open, tool-agnostic format for load testing requirements. Consumers will be load-test adapters and CI backends; the document vocabulary and the OpenTelemetry metric names it borrows are the compatibility surface. Nothing is stable yet.

> The sections above the `---` are **project-specific** — fill them in for each new
> project. Everything below the `---` is the **stack-agnostic development process**
> and is meant to be reused verbatim across all projects.

## Role

Principal Engineer: format and specification design, load testing, observability. The format is minimally usable — a schema, a validated corpus and a gate — and nothing renders or evaluates yet. Prefer precision of vocabulary over features, and treat every added term as a cost. Argue in issues before writing files.

## Stack

No code. One JSON Schema (`schema/opennfr.io/v1/requirementset.schema.json`), documents validated against it in `examples/`, and markdown. A Go reference implementation is anticipated (`reference/adr/0002-compatibility.md`) but not started; constructs are already screened for whether they decode without a custom unmarshaler.

## Commands

```bash
# verify      bash scripts/verify.sh    (YAML parses, links resolve, docs are English)
# links       grep-based, inside verify.sh
# yaml        python3 -c 'import yaml,glob; [list(yaml.safe_load_all(open(f))) for f in glob.glob("docs/**/*.yaml", recursive=True)]'
# no build, no tests — there is nothing to compile yet
```

## Structure

<!-- A LIGHT search index, not a full tree. List only the entry points an agent needs
     to FIND code fast — one terse line per area (`dir/ -> what lives there`). Omit
     anything discoverable by looking; an exhaustive tree is noise and rots fast. -->
`README.md` -> the entry point, every field explained; `schema/` -> the schema and its reference; `examples/` -> the validated corpus; `reference/` -> what is true today (glossary, units, names, tool survey, prior art) with `reference/adr/` for the decision records; `docs/` -> ideas, constructs the format does not have; `specs/` -> spec-kit working dir, read as history.

## Architecture

The vocabulary is the source of truth: `reference/glossary.md` defines the terms the schema carries, the ADRs justify them, and everything else must follow. Compatibility-sensitive: any OpenTelemetry semantic convention name borrowed by the format, and any field name that appears in an example.

## Test Model

`scripts/verify.sh` is the gate. It validates every document in `examples/` against `schema/opennfr.io/v1/`, rejects YAML that cannot map onto JSON (anchors, aliases, merge keys, non-finite numbers), and checks that links resolve, that no documentation links into `docs/`, and that the docs stayed English. `examples/` is the validated corpus; the sketches under `docs/examples/` are deliberately outside the gate, because they illustrate ideas the format does not have — see LAYOUT.md.

---

<!-- ===================================================================== -->
<!-- STACK-AGNOSTIC DEVELOPMENT PROCESS — reuse verbatim across projects.   -->
<!-- ===================================================================== -->

## Boundaries

**Always:** format before commit, branch from `main`, keep commits semantic and green, preserve backward compat for published public APIs and any downstream consumers. `none yet — no code. reference/glossary.md is the vocabulary truth` = dependency truth, `.github/workflows/` = CI/release truth.

**Ask first:** new deps or upgrades, changing public API signatures / observable behavior / serialized formats, editing another repo, release/publish workflow changes.

**Never:** force-push or commit to `main`, merge commits in PR branches (rebase only), commit broken code, opportunistic refactors outside scope, mock external systems where a real integration path exists.

## Milestones (ALWAYS)

Every piece of work is tied to a milestone. No exceptions unless explicitly told otherwise.

- **Every PR** must be assigned to the active milestone before merging. No milestone = do not merge.
- **Every issue** fixed by a PR must be closed when that PR lands on `main`. Do not leave completed issues open.
- **Spec work** (`specs/NNN-*/`) belongs to the milestone that owns the spec. Link the spec PR to the milestone immediately when creating it.
- **Active milestone** = the lowest-numbered open milestone that matches the current spec/plan. Check `gh api repos/galax-io/opennfr/milestones` if unsure.

## Commits & PRs

- **Spec-first.** `specs/NNN-*/` artifacts → `docs(speckit): add NNN-<feature> spec/plan/tasks` commit BEFORE any `feat`/`fix`. Never folded into implementation.
- **1 issue = 1 commit.** Each tracked GitHub issue maps to one semantic commit (`feat(scope): … (#NNN)`), green on its own (`bash scripts/verify.sh`). Docs, tweaks, and out-of-scope improvements go in separate PRs — never mixed with issue commits.
- **Intent, not path.** No add-then-remove within a PR. Squash churn before review.
- **1 concern per PR.** Feature ≠ docs/README. Stack dependent PRs; update with `--force-with-lease`.
- **Idiomatic code.** Follow the language's idioms and the conventions already in the codebase; no control-flow-by-exception, no dead/duplicated code.

## Release Process (MANDATORY)

Trunk-based with release branches. Trunk is `main`; `release/*` branches are cut from `main` for stabilization. Pushing a `vX.Y.Z` tag on `main` or a `release/*` branch triggers the release workflow (GitHub Release only — nothing is published to a registry yet) and creates a GitHub Release (git-cliff).

### Minor/Major release (e.g. 1.2.0, 2.0.0)

1. `git checkout -b release/X.Y.0 main` — cut release branch from `main`
2. `git push -u origin release/X.Y.0`
3. `git tag vX.Y.0` on the release branch
4. `git push origin vX.Y.0` — triggers release workflow

### Patch release (e.g. 1.2.1)

1. Fix lands on `main` first (via PR as usual)
2. `git cherry-pick <fix-sha>` onto `release/X.Y.0`
3. `git tag vX.Y.1` on the release branch
4. `git push origin vX.Y.1` — triggers release workflow

### Rules

- **Every minor version gets its own `release/X.Y.0` branch** — no exceptions
- **Tags ONLY on `release/*` branches or `main`** — `release.yml` validates this
- **Branch name must match tag version**: `release/1.2.0` → `v1.2.0`, `v1.2.1`, etc.
- **Never delete a release tag** after the registry deployment starts — creates stuck deployments
- **Never reuse a version number** — most package registries reject duplicates permanently
- **Before tagging**: every PR merged since the previous tag must be assigned to the milestone; every issue in the milestone whose fix is on `main` must be closed

<!-- The issue↔PR↔milestone contract above is enforced mechanically by         -->
<!-- scripts/check-linkage.sh + the .claude/hooks/linkage-guard.sh PreToolUse   -->
<!-- hook (gates release tagging only; normal push/PR/merge untouched).         -->
