<!--
  scripts/check-linkage.sh gates this PR in CI. It fails unless the PR carries a
  milestone AND closes an issue in that same milestone. See AGENTS.md > Milestones.
-->

Closes #

## What changes

<!-- One concern per PR. A vocabulary change and a docs tidy-up are two PRs. -->

## Why

<!-- For a naming change: what the old term got wrong, and what breaks if we keep it.
     For a new idea: what case it covers that the current notes cannot express. -->

## Checklist

- [ ] Milestone assigned (CI fails without one)
- [ ] `Closes #<issue>` above points at an issue in the same milestone
- [ ] `bash scripts/verify.sh` passes locally
- [ ] If a term changed: [docs/GLOSSARY.md](../reference/glossary.md) updated, including the
      *Rejected* note explaining what the old term got wrong
- [ ] If a decision changed: the relevant ADR updated rather than contradicted elsewhere
