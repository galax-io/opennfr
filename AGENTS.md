# OpenNFR — Agent Guide

An open, tool-agnostic format for load testing requirements. One JSON Schema, a validated corpus, and one document describing every field. Consumers will be load-test adapters and CI backends; the vocabulary and the OpenTelemetry names it borrows are the compatibility surface. Nothing is stable yet.

> The sections above the `---` are **project-specific** — fill them in for each new
> project. Everything below the `---` is the **stack-agnostic development process**
> and is meant to be reused verbatim across all projects.

## Role

Principal Engineer: format and specification design, load testing, observability. The format is minimally usable — a schema, a validated corpus and a gate — and nothing renders or evaluates yet. Prefer precision of vocabulary over features, and treat every added term as a cost. Argue in issues before writing files.

## Stack

No code. One JSON Schema (`schema/opennfr.io/v1/requirementset.schema.json`), documents validated against it in `examples/`, and markdown. A Go reference implementation is anticipated but not started; constructs are already screened for whether they decode without a custom unmarshaler.

## Commands

```bash
# verify      bash scripts/verify.sh    (YAML parses, links resolve, docs are English)
# links       inside verify.sh, via scripts/mdlinks.py
# yaml        uv run --no-project --with 'pyyaml==6.0.3' python -I -c 'import yaml,glob; [list(yaml.safe_load_all(open(f))) for f in glob.glob("examples/*.yaml")]'
# no build, no tests — there is nothing to compile yet
```

## Structure

<!-- A LIGHT search index, not a full tree. List only the entry points an agent needs
     to FIND code fast — one terse line per area (`dir/ -> what lives there`). Omit
     anything discoverable by looking; an exhaustive tree is noise and rots fast. -->
`README.md` -> the format: what it is, every field, and what a target can actually assert; `schema/` -> the schema, which decides; `examples/` -> the validated corpus; `GLOSSARY.md` -> the terms; `CONTRIBUTING.md` -> how to propose a change; `scripts/` -> the gate (`verify.sh`) and what it shares (`mdlinks.py`, `identity.py`); `docs/ideas.md` -> constructs the format does not have; `specs/` -> spec-kit working dir, read as history. One file there is not history and says so in its own text: `specs/004-strip-to-schema/contracts/gatling-reach.md` is a redirect, kept only so the links written to it keep resolving.

## Architecture

The schema decides; `README.md` explains it, and is the only document that describes a field or states what a target can assert — a second target is a second section there, not a second file. `GLOSSARY.md` defines the terms the schema carries. Compatibility-sensitive: any OpenTelemetry semantic convention name borrowed by the format, and any field name that appears in a published example.

## Test Model

`scripts/verify.sh` is the gate. It validates every document in `examples/` against `schema/opennfr.io/v1/`, checks each predicate matches a row of the Gatling capability table exactly, rejects YAML that cannot map onto JSON (anchors, aliases, merge keys, non-finite numbers), and checks that links resolve, that `docs/` is markdown-only with every idea stating its condition and nothing outside linking in, and that the docs stayed English. `examples/` is the validated corpus and the only place documents are published.

---

<!-- ===================================================================== -->
<!-- STACK-AGNOSTIC DEVELOPMENT PROCESS — reuse verbatim across projects.   -->
<!-- ===================================================================== -->

## Boundaries

**Always:** format before commit, branch from `main`, keep commits semantic and green, run Python only through `uv`/`uvx` (`uv run --no-project python -I script.py` for a script, `uvx tool@version` for a tool from PyPI; in CI `astral-sh/setup-uv`, pinned by commit and with `version:`), never bare `python3`, `pip` or a hand-made venv, preserve backward compat for published public APIs and any downstream consumers. `none yet — no code. GLOSSARY.md is the vocabulary truth` = dependency truth, `.github/workflows/` = CI/release truth.

**Ask first:** new deps or upgrades, changing public API signatures / observable behavior / serialized formats, editing another repo, release/publish workflow changes.

**Never:** force-push or commit to `main`, merge commits in PR branches (rebase only), commit broken code, opportunistic refactors outside scope, mock external systems where a real integration path exists. The ban on force-push and merge commits binds the PR branches and `main`; a release branch `release/<id>` is rewritten with `--force-with-lease` by the `prepare` phase of the release workflow, and by nothing else.

## Milestones (ALWAYS)

A product repository has no milestones: a release is a business milestone of `galax-io/galaxio-sdlc-backlog` (see "Feature milestones"), and a PR here carries none.

- **Issues are for important tasks**, not technical ones. A PR that completes one writes `Closes owner/repo#N` (the issue closes when the PR lands on `main`); one PR of several writes `Part of owner/repo#N`. A technical PR (sync, pins, docs, CI) needs no issue: its commit already records it.
- **Spec work** (`specs/BCKLG-<N>-*/`) lives in the backlog and travels in the feature's backlog PR together with its work, never in a PR of its own.

## Feature milestones (ALWAYS)

A feature is an issue in `galax-io/galaxio-sdlc-backlog`. It belongs to exactly one backlog milestone whose description has the line `Release: business`: that milestone is its release.

- **Release branch.** A release has one branch `release/<id>` in each repository where it has work; `<id>` is the milestone's title up to its first em dash, lowercased (`M1.0.9 — first run` → `m1.0.9`). The maintainer makes it with the phase `open` of `.github/workflows/release-build.yml`. Several release branches may be open at once; the branch is the content of its release.
- **Where a PR goes.** The PR of a feature is opened into the release branch of its feature's release, so a release holds only the changes of its own features, and writes `Part of galax-io/galaxio-sdlc-backlog#<feature>`. A PR with no feature (a bot, CI, documents) and urgent work are opened into `main`. The link records the PR in the feature; it does not decide what a release holds.
- **Work enters through the backlog.** A bug, an audit finding or a request is not worked on until it belongs to a feature: grouped into one or given one. An issue from outside stays in its repository and carries the label `status:needs-feature` until it is linked to a feature in the backlog.
- **Release.** The backlog's `scripts/release-build.sh <release>` runs the phase `prepare` in every repository of the release: the branch is rebased onto `main` and this repository's checks run on it. Only when every repository is green does it run `publish` everywhere: `main` is fast-forwarded to the branch, the tag is set on `main`, the GitHub Release is made and the branch is deleted. A red check or a rebase conflict in one repository publishes nothing anywhere. The version is the next minor, `vX.Y.0`, counted by the build; a repository with no PR in its branch gets none.
- **Urgent release.** Urgent work is a PR into `main`; `scripts/release-build.sh --urgent <release>` publishes from `main`, with no release branch.
- **Feature done.** The feature's documents PR in the backlog writes `Closes galax-io/galaxio-sdlc-backlog#<feature>` and is merged last; the work's PRs here write `Part of`.
- **Published releases are not edited.** A fix after the release is the next release or an urgent one; no patch versions are made on a release branch, and a tag is never moved.

## Labels (ALWAYS)

One label scheme for every repository of the organization: `scripts/labels.json` in `galax-io/galaxio-sdlc-backlog`. A label says what the milestone and the feature link do not: the kind of work, its topic, how bad it is, where it stands.

- **Names.** Every label is `group:value`. Labels a tool owns (GitHub's `good first issue` and `help wanted`, Dependabot's, and those code reads, listed as `reserved`) are left alone.
- **Exactly one `type:*` on every open issue:** `bug`, `enhancement`, `docs`, `maintenance`, `question`; in the backlog `type:feature` (an issue of a business milestone) or `type:standing` (the standing feature of an older milestone). An issue without a type is not triaged.
- **At most one each:** `severity:*` (`critical`, `high`, `medium`, `low`: the impact, not the order of work), `status:*` (`needs-triage`, `needs-info`, `needs-feature`, `ready-for-agent`, `ready-for-human`, `blocked`), `tier:*`.
- **Any number:** `area:*` (topics shared by every repository), `module:*` (parts of one repository, declared in the scheme), `source:external`, `source:audit`.
- **Not labels.** The order of work is the milestone: no `priority:*`. The feature is the `Part of` link: no `feature:*`. A rejected or duplicate issue is closed with that reason and a comment: no `wontfix`, `invalid`, `duplicate`.
- **The engine's labels** `sdlc:*` live in the backlog: only the engine sets `sdlc:gate`, `sdlc:done` and `sdlc:failed`. The label of a run's workflow, `workflow:<pipeline name>`, is the maintainer's to set, at most one on an intent; the engine never sets or removes it.
- **A new label is a change to the scheme**, a PR to `scripts/labels.json`, not a label made in one repository. `scripts/sync-labels.sh` applies the scheme; `--check` lists what breaks it.

## Task number (ALWAYS)

A task of the backlog has one number across the organization: `BCKLG-<N>`, where `<N>` is its issue number in `galax-io/galaxio-sdlc-backlog`. It is the only number a spec gets, and it names the task wherever `#N` alone would be read as an issue or PR of another repository.

- **Spec.** Its directory is `specs/BCKLG-<N>-<name>/`, `<N>` its main task. Its `spec.md`, `plan.md` and `tasks.md` carry the line `**Tasks**: BCKLG-<N>[, BCKLG-<M>…]` under the title (the backlog writes the same line in Russian; both are read alike): every task it carries, the main one first. A task has one spec: before writing one, find the spec whose tasks line names the task, check it against the task as its issue says now, and update it rather than write another. A spec directory from before the number keeps its name.
- **Branch.** A task's documents branch in the backlog is `spec/BCKLG-<N>-<name>`, whether made by hand or by the engine, which works on it and opens no other branch in the backlog; the engine's run is `BCKLG-<N>-<time>`, and its branches in the code repositories are `sdlc/BCKLG-<N>-<time>`.
- **Commit.** A commit that does a task's work carries the trailer `Refs: BCKLG-<N>`; its subject stays a Conventional Commit.
- **PR.** Its body carries the line `Refs: BCKLG-<N>` beside `Part of galax-io/galaxio-sdlc-backlog#<N>`, or beside `Closes galax-io/galaxio-sdlc-backlog#<N>` in the task's documents PR.
- **Checked.** The backlog's `scripts/check-linkage.sh --specs` checks every spec there.

## Commits & PRs

- **Spec-first.** `specs/BCKLG-<N>-<feature>/` artifacts → `docs(speckit): add BCKLG-<N>-<feature> spec/plan/tasks` as the first commit of the backlog PR that carries the feature's work, BEFORE any `feat`/`fix`. Never folded into an implementation commit, never a spec-only PR; that PR merges together with the feature's PRs in the other repositories (backlog constitution, Principle II).
- **1 issue = 1 commit.** Each tracked GitHub issue maps to one semantic commit (`feat(scope): … (#NNN)`), green on its own (`bash scripts/verify.sh`). Docs, tweaks, and out-of-scope improvements go in separate PRs — never mixed with issue commits.
- **Intent, not path.** No add-then-remove within a PR. Squash churn before review.
- **One PR per repository part of a feature, a commit per concern.** What its checks find on the way (a dependency, a setting, a rule's findings) is a commit of that PR, not a PR of its own; docs and README that are not the feature's are another PR. Stack a second PR only when the first cannot merge without it; update with `--force-with-lease`.
- **Idiomatic code.** Follow the language's idioms and the conventions already in the codebase; no control-flow-by-exception, no dead/duplicated code.

## Agents & Models (ALWAYS)

Route work by the reasoning it needs, not by habit; parallelize only where agents would not rebuild the same context. Every model is the newest of its class that the accounts can run; an older one is never used.

| Tier | Claude (effort) | Codex (effort) | Google (effort) | Work |
|---|---|---|---|---|
| deep | `claude-opus-5-5` (xhigh) | `gpt-6.2-sol` (xhigh) | `gemini-4-neon` (xhigh) | complex code, review and verification (every critic), research, root-cause analysis, specs/plans, architecture |
| light | `claude-sonnet-5-5` (high) | `gpt-6.1-terra` (high) | `gemini-4-hydrogen` (high) | simpler work a plan already spells out: task/issue generation, mechanical infra (CI config, version pins, renames, doc fixes) |
| trivial | `claude-haiku-5-5` (high) | `gpt-6-luna` (high) | `gemini-4-hydrogen` (low) | very simple edits, gathering context, finding files, bookkeeping |
| exceptional | `claude-fable-5-2` (medium) | `gpt-6.2-astra` (xhigh) | `gemini-4-carbon` (xhigh) | only when the maintainer names the chosen model for a task; no automatic selection or vendor fallback |

- **Newest only.**
  - When a newer model of a class appears, this table and every pin of it move to it in the same change: `.claude/settings.json`, `.claude/agents/`, `setup-speckit.sh` (in spec-kit-galaxio-bootstrap), and any code that routes models.
  - Terra stays at 6.1 and Luna at 6 because Codex refuses `gpt-6.2-terra` and `gpt-6.2-luna` to a ChatGPT account.
  - `gpt-6.2-sol` and `gpt-6.2-astra` need Codex CLI 0.167.2 or later (0.165 refuses them); `gpt-6.1-terra` needs 0.159 or later.
  - Claude Code's own aliases and its background model are pinned to the table in `.claude/settings.json` (`env`: `ANTHROPIC_DEFAULT_FABLE_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`, `…_SONNET_MODEL`, `…_HAIKU_MODEL`, `ANTHROPIC_SMALL_FAST_MODEL`). Without that pin its `haiku` alias means an older Haiku.
- **Codex models by tier.** Deep work runs Sol on xhigh effort, light work runs Terra on high effort, and trivial work runs Luna on high effort. A stage keeps its tier through a vendor fallback; task labels do not switch the model inside its executor session.
- **Google models by tier.** Gemini CLI (`gemini`) and Antigravity (`agy`) follow the same tiers: deep runs `gemini-4-neon` at xhigh, light runs `gemini-4-hydrogen` at high, trivial runs `gemini-4-hydrogen` at low, and `gemini-4-carbon` at xhigh is exceptional (explicit maintainer choice only). Select the model explicitly with `--model <id>` (e.g. `agy --model gemini-4-neon` / `gemini --model gemini-4-neon`) and matching thinking depth.
- **Exceptional is explicit.** Fable, Astra and Carbon run only on their own vendor's harness, with no cross-vendor fallback. Token cost keeps them opt-in: the maintainer names the model on the chosen stage, never as defaultModel. The engine runs Fable at medium; interactive Claude Code uses `claude --model claude-fable-5-2 --effort medium`. Raising effort needs an explicit instruction.
- **Reviews are deep.** Every critic and reviewer runs at the deep tier, on the other vendor than the work it judges.
- **Research is adversarial.** Deep research gets a second opinion from the other vendor (`deep-researcher` does this via `codex exec --sandbox read-only`). A claim only one model supports is unverified, not a fact.
- **Every task carries its tier.** `tasks.md` lines add `[tier:deep]`, `[tier:light]` or `[tier:trivial]` next to `[P]`, and issues carry the matching `tier:*` label where the project labels them. When unsure, it is deep.
- **Parallelize by context, not by file.**
  - Every sub-agent builds its own context from scratch. Agents that must read the same code, spec, or repository repeat that cost and leave integration work behind.
  - `[tier:deep]` work that shares a context runs in one agent, task after task: the main session or a single deep sub-agent. This holds even when `[P]` marks the tasks as parallelizable.
  - Fan deep work out only where each agent's context differs: separate repositories, or subsystems an agent can learn without the others.
  - `[tier:light]` mechanical work (`infra-worker`) and `[tier:trivial]` work (`trivial-worker`) may fan out freely.
  - Dependent tasks stay sequential.
- **Pinned, not remembered.**
  - The Spec Kit kit (`.claude/skills/speckit-*`, `.agents/skills/speckit-*`, `.specify/` but `.specify/memory/`) is the same in every repository: `scripts/build-speckit-kit.sh` of spec-kit-galaxio-bootstrap generates it, pins the Claude Code skills to their tier (override with `SPECKIT_DEEP_MODEL` / `SPECKIT_LIGHT_MODEL`), and it arrives with `copier update` (or `scripts/adopt.sh --speckit`). `scripts/check-speckit.sh` fails when this repository's kit differs; do not edit it here and do not run `specify extension`, `preset` or `integration` commands here. The constitution (`.specify/memory/constitution.md`) is this repository's own.
  - `.claude/agents/` defines the tiered sub-agents, each with its tier's model and `effort`.
  - Where a project routes models in code, it routes by this table: a task or stage names its tier, and each harness runs its own vendor's model of that tier. A model outside the table is an error.

## Release Process (MANDATORY)

Releases are cut by the backlog, never by hand here (see "Feature milestones"): the phases `open`, `prepare` and `publish` of `.github/workflows/release-build.yml` run `scripts/release-phase.sh`, and only the maintainer or the backlog's `scripts/release-build.sh` starts them. The tag `vX.Y.0` that `publish` sets on `main` triggers the release workflow (GitHub Release only — nothing is published to a registry yet) and creates a GitHub Release (git-cliff).

- **No tag by hand.** A version is tagged only by the phase `publish`, on `main`, and only after a green `prepare` of that very head.
- **Never delete or move a release tag**, and never reuse a version number: most package registries reject duplicates permanently.
- **A release branch** `release/<id>` is rewritten only by `prepare` (a rebase onto `main`, pushed with `--force-with-lease`) and deleted by `publish`.
