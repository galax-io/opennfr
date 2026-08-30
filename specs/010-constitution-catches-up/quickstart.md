# Quickstart — validating The Constitution Catches Up

**Feature**: `010-constitution-catches-up` | **Date**: 2026-08-30

This milestone changes no behaviour, so `bash scripts/verify.sh` proves only that nothing broke. The
work is validated by **reading**, and every check below is a comparison a second person can repeat
without knowing what the author intended. Where a step's expected output is a judgment, the step says
what would fail it.

## Prerequisites

```bash
bash scripts/verify.sh
```

Green before you start. If it is not, the failure predates this milestone.

---

## 1. Nothing the format owns moved

The strongest claim this milestone makes is a negative one.

```bash
git diff --stat main...HEAD -- schema/ examples/ scripts/ GLOSSARY.md README.md specs/008-path-denotation/
```

**Expect**: empty. Six paths, no output. A single line here means a requirement was violated — the
schema and corpus by FR-027, `GLOSSARY.md` by FR-025, `README.md` by FR-021, `specs/` by FR-016.

```bash
git diff --stat main...HEAD
```

**Expect**: exactly four files outside `specs/010-constitution-catches-up/` —
`.specify/memory/constitution.md`, `.specify/templates/plan-template.md`, `AGENTS.md`,
`docs/ideas.md`. That is SC-008.

---

## 2. The two documents stop contradicting each other (#83, SC-001)

Read these two, in this order, and nothing else:

```bash
sed -n '/^## Architecture/,/^## Test Model/p' AGENTS.md
sed -n '/^### VI\./,/^### VII/p' .specify/memory/constitution.md
```

**Expect**: `AGENTS.md` states that a second target is a second section in `README.md`, with **no
parenthetical**. Principle VI permits exactly that.

**What fails it**: a reader having to open a third file to reconcile them; `AGENTS.md` still citing
`specs/008-path-denotation/plan.md`; the principle naming `README.md`.

Then the negative check — the rule must still bite:

```bash
grep -n "targets/gatling.md\|README.md" .specify/memory/constitution.md | sed -n '/VI/p'
```

**Expect**: no path inside Principle VI (FR-004). The exception is named by role.

---

## 3. The amended rule is true of the repository as it stands (SC-002)

This is the check Phase 0 added, and the one most likely to be skipped. The rule must permit what the
repository already does and refuse what it should.

**Permitted, and must stay permitted:**

```bash
sed -n '477,479p' README.md      # k6's name tag, Gatling's request name, JMeter's sampler label
sed -n '564,567p' scripts/verify.sh   # "no Gatling scope denotes the requests a path encloses"
```

Neither is a description a renderer reads. If the amended bullet forbids either, it ships a violated
MUST and must be rewritten — this is [research.md](./research.md) R1 and FR-005.

**Refused, and must stay refused:** a second table of what Gatling can assert, anywhere. Confirm
there is still exactly one:

```bash
grep -rln "Gatling" --include=*.md . | grep -v '^./specs/' | grep -v '^./.claude/'
head -4 specs/004-strip-to-schema/contracts/gatling-reach.md
```

**Expect**: `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `docs/ideas.md` — of which only `README.md`
carries rows; and the `gatling-reach.md` redirect still saying in its own text that it carries no rule.

---

## 4. Principle II names two classes, and each reason is true of its class (#75, SC-003)

```bash
sed -n '/^### II\./,/^### III/p' .specify/memory/constitution.md
sed -n '423,426p' README.md
```

**Expect**: the derived clause names throughput and error rate. For each, name the aggregation:
`rate` and a `bad` fraction. apdex appears in the composite clause, under *reduces to no construct
the format has*.

**What fails it**: apdex still in the derived list; a composite clause that restates why apdex needs
two constructs (that argument belongs to `docs/ideas.md` — FR-019); a clause written as though it
were the only thing refusing `loadtest.apdex` (FR-020).

Cross-check the two documents agree on every name they both mention:

```bash
grep -o "throughput\|error rate\|apdex" README.md | sort | uniq -c
grep -n "throughput\|error rate\|apdex" .specify/memory/constitution.md
```

**Expect**: no name asserted in one and denied in the other.

---

## 5. The parked argument passes its own check (SC-004)

```bash
python3 -c "import json; d=json.load(open('schema/opennfr.io/v1/requirementset.schema.json')); print(d['\$defs']['aggregation']['anyOf'])"
sed -n '80,83p' docs/ideas.md
```

**Expect**: the enum's seven names all present in the prose, plus `p*` for the pattern, and a clause
saying why `sum` is not the aggregation apdex needs.

The gate check that this edit could break:

```bash
bash scripts/verify.sh 2>&1 | grep "docs/ is isolated" -A1
git rm -r --cached -q docs && bash scripts/verify.sh >/dev/null 2>&1; echo "exit=$?"; git reset -q
```

**Expect**: `ok  docs/ is markdown-only, every idea states its condition…`, and the ideas/conditions
counts unchanged at **16 and 16** — the `26` in the gate's own line is how many links it scanned, not
how many ideas it found. If the edit added a line-initial `**bold**`, the counts diverge and the
section fails (FR-024).

```bash
python3 -c "import re,io; t=io.open('docs/ideas.md',encoding='utf-8').read(); print(len(re.findall(r'^\*\*(.+?)\*\*',t,re.M)), t.count('*Would need*'))"
```

---

## 6. The gate a plan is held to matches the rule it cites (SC-005)

```bash
sed -n '41,45p'  .specify/templates/plan-template.md
sed -n '/VI. The Requirement Is Target-Blind/,+4p' .specify/templates/plan-template.md
```

**Expect**: the version pointer names v4.0.0 (FR-014), and the Principle VI question asks about the
format, the schema, the corpus, and any existing document *other than the one holding the target
descriptions* — plus whether there is still exactly one per target. Read it against Principle VI and
the two must agree without a third file.

Also check the Principle II gate names both classes (FR-015):

```bash
sed -n '/II. Borrow Names/,+4p' .specify/templates/plan-template.md
```

---

## 7. The version and its record (SC-006)

```bash
tail -3 .specify/memory/constitution.md
sed -n '1,40p' .specify/memory/constitution.md
```

**Expect**: `**Version**: 4.0.0`, **Last Amended** on the landing date, and a Sync Impact Report that
names Principle VI (MAJOR — *redefined in a way that permits what it previously forbade*), Principle II
(MINOR — *materially expanded*), states why each previous wording failed, and lists the templates
reviewed. VII is still the only withdrawn number.

---

## 8. The milestone's own linkage (SC-009)

```bash
bash scripts/verify.sh
bash scripts/check-linkage.sh 2>/dev/null || echo "(run in CI)"
gh pr view --json milestone,body --jq '{milestone: .milestone.title, first_para: (.body | split("\n\n")[0])}'
```

**Expect**: green; milestone **v0.7.0**; `Closes #83` and `Closes #75` both present; and a first
paragraph that says the PR amends the constitution and what breaks without it (FR-030). Three commits,
#83's before #75's, each green on its own:

```bash
git log --oneline main..HEAD
```

To check each commit is green on its own, check it out in a scratch worktree rather than moving this
one — `AGENTS.md` forbids the shared stash stack for exactly this:

```bash
git worktree add /tmp/onfr-green <sha> && (cd /tmp/onfr-green && bash scripts/verify.sh)
```
