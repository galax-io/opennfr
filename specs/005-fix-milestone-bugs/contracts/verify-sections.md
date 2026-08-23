# Contract: what the gate checks after these five fixes and one enhancement

**Feature**: `005-fix-milestone-bugs`

FR-002, FR-007 and FR-008: a section that is supposed to be able to fail must actually be able to
fail, on the specific input it claims to guard against. Three sections change what they check; the
rest are named here to record that this feature leaves them alone.

| # | Section | Changes | After the fix |
|---|---|---|---|
| 1 | YAML parses | No | Unchanged |
| 2 | Documents map one-to-one onto JSON | No | Unchanged |
| 3 | Examples validate against the schema | Indirectly (schema edits from R2/R3) | Unchanged in shape; still validates every file in `examples/` against the schema, which after R2/R3 rejects the same documents it does today (data-model.md, "What every fix must leave unchanged") |
| 4 | The schema holds up its own examples, and still rejects | **Yes — R1 (#37), R6 (#31)** | The probes' shared base document is asserted valid *before* mutation, so a probe can only be rejected by the mutation it targets. The probe set grew from 7 to 54 — one per constraint the schema makes — after a sweep found 39 of 41 single-constraint loosenings left the section green. A floor fails the section if probes are removed |
| 5 | Examples are assertable by Gatling | No | Unchanged |
| 6 | Internal markdown links resolve | **Yes — R4 (#43)** | Extraction moves to `scripts/mdlinks.py`, checked against its own fixtures on every run. Text shaped like a markdown link inside a code span or fence no longer fails the section; a `/`-rooted target resolves against the repository rather than the filesystem root; an unreadable file FAILs as a file instead of aborting the section |
| 7 | `docs/` is isolated | **Yes — R4 (#43)** | Uses the same `scripts/mdlinks.py` definition, so the two scanners can no longer disagree about whether a given piece of text is a link. Its count moved 26 → 25, the miscounted code span going away. The three clauses it checks are unchanged |
| 8 | Docs are English | No | Unchanged |

No section is added or removed. Sections 1, 2, 3, 5, 7 and 8 are listed for completeness — this
feature's Constitution Check (plan.md) depends on being able to name every section it does *not*
touch, not only the two it does.

## Acceptance

After all five fixes land:

- `bash scripts/verify.sh` reports **PASS**.
- Section 4 **FAILS**, naming the base-document error, if the shared probe base document is
  mutated to be invalid on its own (a regression test for R1's whole point) — probed during
  planning by reading the base document's current validation errors (research.md R1), to be
  re-probed as a task during implementation by deliberately reintroducing each of the seven closure
  gaps and confirming the corresponding probe now fails for the right reason.
- Section 6 **FAILS** on a markdown link outside any code span or fence that targets a
  non-existent path (unchanged behavior — probed, not assumed, since R4 changes the extraction
  mechanism).
- Section 6 does **NOT FAIL** when the schema's literal `name` pattern, or any other text with the
  same closing-bracket-then-opening-parenthesis shape, is written inside a code span or fenced
  code block anywhere under version control — reproduced as broken today in research.md R4, to be
  re-probed once R4 lands.
- A predicate document with exactly one invalid field (e.g. `unit: "mss"`) produces exactly one
  schema-validation error in section 3's output, not two (R2, research.md).
- `examples/fast-and-reliable.yaml`, `examples/one-request-is-fast.yaml` and
  `examples/the-run-held-up.yaml` continue to pass section 3 unchanged (R2, R3 — dry-run
  confirmed zero regressions in research.md; re-confirmed live once the schema edits land).
