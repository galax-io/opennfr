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
below — never left blank. See `.specify/memory/constitution.md` (v2.0.0).

- [ ] **I. Vocabulary Before Features** — does this feature introduce or rename a term?
      If so, is `reference/glossary.md` updated in the same change, with a rejected
      alternative and its reason? Does any ADR now contradict it?
- [ ] **II. Borrow Names, Never Invent Them** — is every metric and attribute name taken
      from OpenTelemetry semconv where an equivalent exists? Is anything new confined to
      `loadtest.*`? Are there aliases or derived quantities masquerading as metrics?
- [ ] **III. No Silent Green** — for every predicate a document can carry: is it either
      rendered into the target's assertions or reported by name as one that target cannot
      express, with the two lists covering the document exactly and arriving before the run?
      Is any approximation substituted for a construct a target cannot express? Where a
      target can pass on absent data, is that declared in its description, dated and sourced?
      Does any check this adds skip rather than fail when it cannot run?
- [ ] **IV. Honest Status** — do the artifacts state what is verified and what is
      speculation? Is every claim about an external tool dated and sourced?
- [ ] **V. Structure Over Grammar** — is every new field validatable by schema without a
      bespoke parser? Are value sets closed? Does anything need custom decoding, and is
      that justified in an ADR?
- [ ] **VI. The Requirement Is Target-Blind** — does any requirement document name a
      target, in a field, a value, a metric name or an example? Does adding a target change
      the format, the schema, or an existing document? Where two targets derive the same
      criterion differently — the percentile, the vantage point, the unit, the precision — is
      each difference recorded in that target's description, dated and sourced, rather than
      closed by the format?
- [ ] **VII. Architecture Before Implementation** — does every component this adds or alters
      name the architectural role it fills? If it needs a role the architecture lacks, does
      an earlier PR amend the architecture rather than diverging from it?
- [ ] **VIII. Experiments Are Parked, Not Merged** — is any unsettled work entering a
      compatibility-sensitive surface? Does every experimental artifact state its status,
      promotion and retirement conditions, and the date? Is the experimental area still
      removable in one operation, with nothing outside linking into it?
- [ ] **Compatibility** — does this touch a borrowed OTel name, a published example's
      field name, or what a target description may declare? For every construct added: can
      **at least one surveyed target assert it exactly**, and is it being added for a reason
      beyond reaching that one target's feature? Does anything **this feature adds** cite a
      conformance level? (The ladder is retired; several documents still carry old citations
      and are corrected by the amendments the constitution names as owed — those are not this
      feature's to answer for.)

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
