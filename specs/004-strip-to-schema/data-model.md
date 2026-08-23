# Phase 1: the documents, before and after

**Feature**: `004-strip-to-schema` | **Date**: 2026-08-23

This feature has no data model in the usual sense — the schema is untouched. What it has is an
inventory. SC-007 requires that every rule living only in a removed document be accounted for, and
the only way to check that is a table with a row per file and no blanks.

## Entities

| Entity | What it is | Where it lives after |
|---|---|---|
| **The schema** | One JSON Schema defining `RequirementSet`. Unchanged by this feature: no field added, removed or narrowed | `schema/opennfr.io/v1/requirementset.schema.json` |
| **The field description** | The entry point and the specification in one document: what the format is, every field, per-field notes carrying the argument for its shape, and what Gatling can reach | `README.md` |
| **The corpus** | Three case documents, valid against the schema and wholly assertable by Gatling | `examples/*.yaml` |
| **The terms** | Definitions and a rejected alternative each. Not a second field description | `GLOSSARY.md` |
| **The ideas** | One file: every construct considered and left out, with a sentence of reasoning and what would have to become true | `docs/ideas.md` |
| **The gate** | One command validating the corpus, the links and the isolation of `docs/` | `scripts/verify.sh` |
| **How to contribute** | ~2 KB | `CONTRIBUTING.md` |

## Target tree

```
README.md                                     the specification
GLOSSARY.md                                   terms
CONTRIBUTING.md                               how to propose a change
LICENSE
schema/opennfr.io/v1/requirementset.schema.json
examples/one-request-is-fast.yaml
examples/fast-and-reliable.yaml
examples/the-run-held-up.yaml
docs/ideas.md
scripts/verify.sh
```

Six entries a reader has to consider — the format, the terms, contributing, the schema, the
examples, the ideas (SC-008). `LICENSE`, `.github/`, `.specify/`, `AGENTS.md`, `CLAUDE.md`,
`cliff.toml` and `scripts/check-linkage.sh` are tooling and are not read as documentation.

## Disposition of every current file

Nothing is listed as "deleted" without a destination for what it carried.

### Root

| File | Bytes | Disposition |
|---|---|---|
| `README.md` | 23,746 | **Rewritten.** Absorbs `schema/README.md`, `reference/units.md`, `reference/names.md`, the ten load-bearing decisions (research R4) as per-field notes, and the Gatling reach table (R1) |
| `ARCHITECTURE.md` | 19,339 | **Deleted** (FR-001). Carried nothing live: every component is proposed, six of its constructs are rejected by the schema, and its clause 3 disowns itself. Issue #35 closed with a reason (FR-021) |
| `LAYOUT.md` | 13,941 | **Deleted** (FR-002). Three rules move: *a note is deleted once it becomes a rule* and *the route from an idea into the schema* → `CONTRIBUTING.md`; *`docs/` is isolated* → the constitution, where the gate that enforces it can be named. The nine artifact classes, eleven governance words and the target-onboarding procedure are dropped — none describes anything that exists |
| `AGENTS.md` | 7,239 | **Reduced.** Working file, not published documentation. Paths follow the move; the Structure and Architecture sections shrink to the target tree |
| `CLAUDE.md` | 161 | Unchanged — one include line |
| `LICENSE` | 11,357 | Unchanged |
| `cliff.toml` | 2,225 | Unchanged |
| — | | **New**: `GLOSSARY.md`, `CONTRIBUTING.md` |

### `schema/`

| File | Bytes | Disposition |
|---|---|---|
| `opennfr.io/v1/requirementset.schema.json` | 12,671 | **Unchanged**, except the two `description` strings that name `reference/glossary.md` and `reference/units.md` |
| `README.md` | 12,169 | **Merged into `README.md`** (FR-006) and deleted. Its constraint tables, enumerations and rejection messages are the field description. The `name`-pattern workaround it carries goes with it, closing #43 |

### `reference/`  — the directory ceases to exist (FR-017)

| File | Bytes | Disposition |
|---|---|---|
| `glossary.md` | 12,894 | **→ `GLOSSARY.md`**, reduced to terms, definitions and rejected alternatives. Everything restating a field's rules is dropped as a second copy |
| `units.md` | 4,426 | **→ `README.md`**: the enumeration and the conversion table. Its unenforced rule 2 is restated as a limitation rather than a rule, closing #39 |
| `names.md` | 5,494 | **→ `README.md`**: which OpenTelemetry names to write, the vantage-point rule, and the `loadtest.*` debt (FR-018) |
| `compatibility.md` | 3,285 | **→ `README.md`**: the dated finding that no load generator publishes semantic convention names. The five-tool table is dropped; only Gatling is claimed against |
| `prior-art.md` | 4,217 | **Dropped**, apart from the paragraph in `README.md` on why no surveyed format was adopted |
| `adr/0001-terminology.md` | 8,134 | **Dropped**; D3–D7 → per-field notes (R4) |
| `adr/0002-compatibility.md` | 9,811 | **Dropped**; D14–D17 → per-field notes (R4) |
| `adr/0003-selection-belongs-to-the-requirement.md` | 5,493 | **Dropped**; its argument → the note on `selector` |
| `README.md` | 3,064 | **Deleted** — an index of a directory that no longer exists |

### `docs/` — reduced to one file (FR-016)

| File | Bytes | Disposition |
|---|---|---|
| `not-in-the-format.md` | 7,536 | **→ `docs/ideas.md`**, one paragraph per construct |
| `the-result-document.md` | 4,717 | **→ `docs/ideas.md`**, one paragraph |
| `tool-support.md` | 9,940 | **→ `docs/ideas.md`**, one paragraph |
| `semconv/loadtest.md` | 6,260 | **Split**: `loadtest.request.name` and `loadtest.group.name` → `README.md` (FR-018, they are the corpus's only way to address a request); the rest → one paragraph in `docs/ideas.md` |
| `experimental/README.md` | 3,854 | **→ `docs/ideas.md`**, one paragraph. The whole of `docs/` is now what the experimental area was |
| `examples/checkout-perf.yaml` | 4,800 | **Deleted.** Sketches of constructs the format does not have; `docs/ideas.md` describes those constructs in prose |
| `examples/checkout-perf.report.yaml` | 3,686 | **Deleted**, same |
| `examples/mapping-k6.yaml` | 3,291 | **Deleted**, same. Its `errorSignal` sketch is named in `docs/ideas.md` as the unsolved problem it is |
| `examples/mapping-jmeter.yaml` | 2,986 | **Deleted**, same |
| `README.md` | 3,229 | **Deleted** — an index of one file |

### `examples/` — replaced (FR-013)

| File | Disposition |
|---|---|
| `minimal.yaml` | **Deleted.** Its one predicate is unrunnable — `http.route`. Replaced by `one-request-is-fast.yaml` |
| `six-statements.yaml` | **Deleted.** Named after the format's history, and seven of its eleven predicates are unrunnable. Its live content splits across `fast-and-reliable.yaml` and `the-run-held-up.yaml` |

### `scripts/`

| File | Disposition |
|---|---|
| `verify.sh` | **Reduced** per `contracts/verify-sections.md`: the sketch-label section is deleted with the sketches; six sections survive |
| `check-linkage.sh` | Unchanged. CI tooling, not documentation |

### Governance

| File | Disposition |
|---|---|
| `.specify/memory/constitution.md` | **Amended to 3.0.0** (FR-019). Principle VII removed, its number withdrawn; III trimmed to what exists; VIII reduced to `docs/`; the ADR requirement replaced by an argued issue plus a glossary rejection (R5); every path and artifact class that no longer exists removed |
| `.specify/templates/plan-template.md` | **Updated** — the Constitution Check gates follow 3.0.0 |
| `.github/pull_request_template.md` | **Updated** — glossary path; the ADR checklist line becomes the issue line |
| `.github/ISSUE_TEMPLATE/*.yml` | **Updated** — glossary and prior-art paths |
| `.copier-answers.yml` | **Left alone** — its header forbids manual editing. #46 stands and grows: the answers would now regenerate `AGENTS.md` against a tree two cuts old |

## Issue disposition (FR-021)

| Issue | After |
|---|---|
| #35 `ARCHITECTURE.md` contradicts the constitution | Disposition commented; **closes on merge**. Its own linkage rule closes an issue when the fix is on `main`, and these commits are on a branch |
| #36 the conformance ladder has no ADR | Commented; closes on merge. Every document that cited a level is deleted or rewritten, and 3.0.0 removes the ADR requirement that made the retirement owe one |
| #37 the schema self-check passes vacuously | **Stays open.** Real, and untouched by this feature |
| #38 dead conditional in the schema | **Stays open.** Its `description` is corrected — it cited the glossary for a rule about `ratio`, which the glossary no longer states — but the unreachable block is untouched |
| #39 `units.md` claims a check that does not exist | Commented; closes on merge. The claim moved to `README.md` restated as a limitation |
| #40, #41, #45 | Commented; close on merge. Superseded — this feature cuts further than all three. #44 is the branch's closing link |
| #42 noisy predicate errors | **Stays open.** A schema change |
| #43 the link check reads a regex as a link | **Argued to stay open.** The workaround disappeared with `schema/README.md`, but the defect bit twice more while writing this feature's quickstart, which now carries the second workaround for it |
| #46 `.copier-answers.yml` drift | **Stays open**, and is worse |

## Totals

Measured 2026-08-23, at the commit the work starts from. **Documentation** means markdown outside
`.git/`, `.claude/`, `.specify/`, `.github/` and `specs/`, excluding `CLAUDE.md` — one include
line. An earlier draft of this table said 29 files; that count had swept in the constitution, the
pull-request template and `CLAUDE.md`, and is corrected here rather than carried.

Measured after the change, 2026-08-23.

| | Before | After |
|---|---|---|
| Prose describing no field of the format | 66,383 B | **2,577 B** — one `CONTRIBUTING.md` |
| Documentation markdown files | 20 | **5** — README, GLOSSARY, CONTRIBUTING, docs/ideas.md, AGENTS |
| Documentation bytes | 168,591 B | **53,390 B** |
| Documents describing a field | 2 | **1** |
| Corpus predicates Gatling cannot run | 8 of 12 | **0 of 9** |
| Schema bytes changed | — | **0** — five `description` strings, no field |
