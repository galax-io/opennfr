# Contract — the three document kinds

**Feature**: [003-assertion-first-format](../spec.md) | **Date**: 2026-08-20

What this repository would publish, and what a consumer would have to do with it.

> **Nothing described below is built.** What exists in this repository is the RequirementSet
> schema, with `displayName` and embedded `examples`. There is no target description, no
> rendering, no corpus and no runner — this file is the argument for what they would be and
> what each would cost. Read it as a proposal.

Of the three kinds below, **only `RequirementSet` exists**. Its field names are already a
compatibility-sensitive surface — the constitution puts "any field name that appears in a published
example" on it — and the other two bind nobody, because there is nothing to bind to.

The consumer is a renderer living in the tool's own repository. This repository ships no renderer
(spec Assumptions), so this contract is written to be implementable without reference to any code
here.

---

## C1. `kind: RequirementSet` — the input

**A conforming consumer MUST:**

1. **Reject an unknown field, anywhere, at any depth.** Not warn, not ignore. A typo like
   `agregation:` would otherwise silently disable a criterion and turn a run green (FR-006).
2. **Reject a document it cannot fully decode**, rather than decoding the part it understands.
3. **Ignore `displayName` entirely when rendering.** It is free text for a person, it is optional,
   and it never affects what is selected, measured, compared or produced (FR-007). A consumer that
   reads it for anything but display is wrong.
4. **Compute predicate identity** as `name` if present, else `aggregation`, and reject a document in
   which two predicates of one requirement — counting `criteria` and `guards` together — share one.
5. **Never resolve a data source from the document.** The document names no tool, no endpoint, no
   backend (FR-001).

**A conforming consumer MUST NOT:**

- treat a selector matching many requests as anything but one aggregate — there is one reading, and
  the format has no second one to choose between;
- accept a threshold without a unit;
- accept YAML anchors, aliases or merge keys, or any value with no JSON equivalent.

---

## C2. `kind: TargetDescription` — the capability declaration

**A conforming consumer MUST:**

1. **Treat the capability table as exhaustive.** A combination of *(shape, metric, side, scope,
   selection, aggregation, comparison)* that the table does not declare as supported is
   **unrenderable**. There is no inference, no nearest match, no fallback.
2. **Treat capabilities and gaps as a partition.** A combination in neither half is a **defect of the
   description**, reported as such — not silently resolved either way (FR-017).
3. **Convert units using the declared rationals, in exact arithmetic.** A threshold that is not
   exactly representable in the declared numeric domain is **unrenderable, never rounded** (FR-013).
4. **Refuse to render a claim with no evidence.** Every capability and every gap cites at least one
   evidence entry; a description that fails this is invalid, not merely undocumented.

**A conforming consumer MUST NOT:**

- extend the table by rule, pattern or heuristic;
- substitute an available comparison for an unavailable one, however close;
- treat `report.carriesAuthorName: false` as an invitation to synthesise a name by other means — see
  spec Appendix D for what that costs.

---

## C3. `kind: Rendering` — the output, and the oracle

**A conforming consumer MUST produce, for one document and one description:**

1. **Exactly one entry per predicate**, in document order: per requirement in order, its `guards`
   then its `criteria`.
2. **Exactly one of `rendered` or `unrenderable` per entry.** There is no third state and no absent
   state. A predicate that produced nothing and was not declared unrenderable is the failure this
   whole feature exists to prevent (FR-010, FR-025).
3. **`role`** on every entry, distinguishing a criterion from a precondition.
4. **At least one assertion** in every `rendered` entry.
5. **At least one reason** in every `unrenderable` entry, each citing a gap the description actually
   declares.

**Determinism** (FR-015): the same document and the same description produce the same entries, in the
same order, with selectors serialised in lexicographic key order and native parts in the order
`native.fields` declares.

**The sum rule** (FR-033): predicate → exactly one **bucket**. Not predicate → exactly one assertion.
One criterion may render to several native assertions where the target can only express it as a
conjunction, and one native assertion may expand into many results at run time. Neither breaks the
rule.

---

## C4. What this repository does not promise

Stated because a contract that overclaims is worse than none.

- **No renderer.** Nothing here turns a document into assertions. The corpus is an oracle: it says
  what a correct rendering looks like, and is unfalsified until an implementation elsewhere runs
  against it (spec Appendix C).
- **No guarantee the target accepts the assertion.** The corpus pins the arguments, never the API. A
  statistic name the tool does not have passes every check here.
- **No coverage of run time.** Everything above is checkable before a run; what the target then does
  is the target's. One target has a per-request assertion scope that exits **successfully** when it
  matches nothing — a silent green inside the tool. The format does not reach for that scope
  (spec D2, withdrawn), so nothing here renders into it; it is recorded because a reader comparing
  the format to the tool will find the capability and ask why it is unused.
