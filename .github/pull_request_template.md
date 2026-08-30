<!--
  scripts/check-linkage.sh gates this PR in CI. It fails unless the PR carries a
  milestone AND closes at least one issue, with every issue it closes in that same
  milestone. A PR may close several. See AGENTS.md > Milestones.
-->

Closes #

## What changes

<!-- One concern per PR. A vocabulary change and a docs tidy-up are two PRs.
     A milestone is one concern: one commit per issue, all in this PR. -->

## Why

<!-- For a naming change: what the old term got wrong, and what breaks if we keep it.
     For a new idea: what case it covers that the current notes cannot express. -->

## Checklist

- [ ] Milestone assigned (CI fails without one)
- [ ] every `Closes #<issue>` above points at an issue in the same milestone
- [ ] `bash scripts/verify.sh` passes locally
- [ ] If a term changed: [GLOSSARY.md](../GLOSSARY.md) updated, including the
      *Rejected* note explaining what the old term got wrong
- [ ] If a compatibility-sensitive surface changed — a borrowed OpenTelemetry name, or a
      field name in a published example — it was argued in the issue above first
