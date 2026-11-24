<!--
  A PR of a feature goes into its release branch, release/<id>, and writes
  Part of galax-io/galaxio-sdlc-backlog#<feature>; a change with no feature goes
  into main. See AGENTS.md > Feature milestones.
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
