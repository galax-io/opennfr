# Contract — the corpus runner

**Feature**: [003-assertion-first-format](../spec.md) | **Date**: 2026-08-20

How the conformance corpus executes, what it reports, and — the part that matters — how it fails.

> **Partly built.** The document checks and the render-case rule live in
> `scripts/opennfr_check.py` and run from the gate today. The check codes in § E2 beyond
> those, and the mutation suite in § E4, are specified and not written — `scripts/test-gate.py`
> does not exist. Read the unbuilt parts as what is owed, not as what runs.
`bash scripts/verify.sh` is the gate (AGENTS.md and the constitution's Development Workflow), so the
corpus is reachable from it and its exit code propagates.

---

## E1. The exit contract

| Code | Meaning |
|---|---|
| `0` | every case ran and every case passed |
| `1` | the suite ran; at least one case failed |
| `2` | **the suite could not run** — a missing dependency, an unreadable schema, an empty corpus, a case with no expectation |

Code `2` is the whole point. FR-035: *no part of the suite may skip.* The distinction between "ran
and passed" and "could not run" must survive into the exit code, or a broken environment reads as a
clean build — which is Principle III applied to the project's own tooling.

**There is no `skip` branch.** Not for a missing interpreter, not for a missing library, not for an
empty directory. The gate now gets this right everywhere — four sections were repaired to match the
one that always had it (spec Appendix B) — and the corpus is written the same way from the start.

---

## E2. Check codes

Every check reports a short code so a failure names itself rather than describing itself.

| Code | Checks |
|---|---|
| `SCHEMA` | every document validates against its kind's schema |
| `IDENTITY` | within one requirement, no two predicates share an identity — `criteria` and `guards` counted **together** |
| `SUM` | every predicate falls in exactly one bucket. No third bucket, no remainder (FR-033, SC-017) |
| `ORDER` | entries follow document order; selectors and native parts follow their declared orders (FR-015) |
| `CONVERT` | the threshold, recomputed in exact rational arithmetic from the description's units, equals the rendering's value **and** is exactly representable in the declared domain (FR-013) |
| `GAP` | every unrenderable reason cites a gap the description actually declares; and no predicate is called unrenderable for a capability the description **does** declare (FR-017, both directions) |
| `PARTITION` | capabilities and gaps partition each axis — a combination in neither is a defect of the description |
| `EVIDENCE` | every capability, gap and pinned literal carries a citation and a date (FR-026, SC-007) |
| `COLLIDE` | reports predicate pairs whose `report.derivedFrom` projections are equal — indistinguishable in that target's report (SC-012) |
| `NOTOOL` | no tool name appears in any `document.yaml`, comments included (SC-004) |

`GAP` checking **both directions** is what catches laziness: declaring something unrenderable that
the target can in fact assert is as much a defect as the reverse, and only one of the two is
uncomfortable to report.

`COLLIDE` **reports rather than fails**. Two predicates that collide in a target's report are a fact
about the target, not an error in the corpus. Failing on it would push authors to hide collisions;
reporting it makes them visible, which is what SC-012 now asks for.

---

## E3. One rule, one implementation

FR-036. Where the gate and the corpus check the same rule, they call the same code.

The gate today carries its checks as copy-pasted heredocs inside `scripts/verify.sh`. The corpus must
not re-implement them: a corpus asserting against its own copy proves nothing about the gate that
actually runs, and two copies drift — the failure this repository exists to prevent, reproduced
inside its own test suite.

So the shared checks are extracted once and called twice. If that extraction is judged out of scope,
the affected cases are **dropped and the rule recorded as untested** — never duplicated.

---

## E4. The gate mutation suite

`conformance/gate/`. **Specified, not written** — `scripts/test-gate.py` does not exist, and the
cases below are planted by hand today. Each plants a defect in a copy of the tree and requires the
gate to go red (FR-034).

**A control case is mandatory**: an unmutated copy must exit `0`. Without it the whole suite can pass
because the gate is red for an unrelated reason.

Cases fall into two groups, and the distinction is worth keeping in the output:

- **Pins** — the check works; the case stops a future refactor from losing it.
- **Known-red** — the check is broken; the case is the specification of the fix, and must be visibly
  distinguished from a pin so nobody "fixes" it by deleting it.

Four of the pins guard checks that were repaired while this feature was being specified (spec
Appendix B). They are the most valuable cases in the suite: each covers a section that reported `ok`
on every commit, on both platforms, for the life of the project — one of them without ever having
executed.

**One honest limitation, and it is why the pin matters.** CI runs on Linux. The Cyrillic case would
have passed there and always would have; the defect only ever bit on a developer's macOS, and only
if they ran the gate. So no mutation case could have *found* it — the repair had to be removing the
platform-dependent construct, which is what landed. The case guards that repair, and is worthless as
a detector of the next defect of the same shape. A mutation suite pins what is known; it does not
discover.

---

## E5. What the runner cannot establish

Repeated from spec Appendix C because a runner contract is where someone will look for it.

- Nothing here renders. Every check is a consistency check between files this repository writes.
- A target description and a case can be **uniformly wrong** about a tool and the build stays green.
  `EVIDENCE` can verify a date exists; it cannot verify the claim is true.
- The sum rule closes over the document, not over intent. It catches a dropped predicate. It cannot
  catch the requirement nobody wrote.
