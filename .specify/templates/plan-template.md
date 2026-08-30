# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]

**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]

**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]

**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]

**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]

**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Answer each gate explicitly. A "no" is either fixed or justified in Complexity Tracking
below — never left blank. See `.specify/memory/constitution.md` (v4.0.0).

- [ ] **I. Vocabulary Before Features** — does this feature introduce or rename a term? If so, is
      `GLOSSARY.md` updated in the same change, with a rejected alternative and its reason? Was
      the naming argued in an issue before files changed?
- [ ] **II. Borrow Names, Never Invent Them** — is every metric and attribute name taken from
      OpenTelemetry semconv where an equivalent exists? Is anything new confined to `loadtest.*`,
      and does the field description say so where the corpus depends on it? Are there aliases, or
      derived or composite quantities masquerading as metrics?
- [ ] **III. No Silent Green** — does any check this adds skip rather than fail when it cannot
      run? Does any check report success having scanned nothing? Does any artifact this adds
      claim a validation that does not happen? If a check's input is being deleted, is the check
      deleted with it rather than left to pass on an empty scan?
- [ ] **IV. Honest Status** — do the artifacts state what is verified and what is speculation? Is
      every claim about an external tool dated and sourced?
- [ ] **V. Structure Over Grammar** — is every new field validatable by schema without a bespoke
      parser? Are value sets closed?
- [ ] **VI. The Requirement Is Target-Blind** — does any requirement document name a target, in a
      field, a value, a metric name or an example? Does adding a target change the format, the
      schema, the published corpus, or any existing document other than the one holding the target
      descriptions? Is there still exactly one description per target, and does any gate carry a
      second copy of its rows?
- [ ] **VII** — *withdrawn in 3.0.0. No gate.*
- [ ] **VIII. Ideas Are Parked, Not Merged** — does anything outside `docs/` link into it? Does
      every idea state what would have to become true before it could enter the format? Does
      `git rm -r docs && bash scripts/verify.sh` still pass?
- [ ] **Compatibility** — does this touch a borrowed OTel name or a field name in a published
      example? If so, was it argued in an issue, and does `GLOSSARY.md` record what was rejected?
      For every construct added: can **at least one surveyed target assert it exactly**, and is it
      being added for a reason beyond reaching that one target's feature? If the published corpus
      narrows, does the format stay as wide, and does the field description say which parts no
      target reaches?

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
