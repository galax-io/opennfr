# Phase 0 research: Strip the repository to the schema, the examples and the fields

**Feature**: `004-strip-to-schema` | **Date**: 2026-08-23

Six questions had to be answered before the design could be written. Four came from the
specification's own Dependencies section; two surfaced while checking the first four.

---

## R1. Where does the Gatling capability record live?

**Decision**: Restate it as a section of the field description — a dated, sourced table of what
Gatling's assertion DSL can express. Do **not** restore `mappings/gatling.yaml`.

**Rationale**: FR-014 already requires the field description to say which parts of the format no
available target can run, so the information has to be there regardless; putting it anywhere else
creates the second copy this feature exists to remove. The restored file would also be a
`kind: TargetDescription` document with no schema to validate it, in a `mappings/` directory the
approved shape does not contain — reintroducing the "support as data" direction on the same day
it is being cut.

**Alternatives considered**:

- *Restore `mappings/gatling.yaml` from `cb7cb58`* (309 lines). Rejected: it is a document kind
  nothing validates, and it re-adds a top-level directory against SC-008.
- *Leave it in git history and cite the commit.* Rejected: FR-010 is a rule the corpus is judged
  against on every commit. A rule whose text is only in history cannot be applied by a reviewer.

**What is carried forward** — from `mappings/gatling.yaml` @ `cb7cb58`, sourced to Gatling
v3.15.1 and checked 2026-08-20, recorded in `contracts/gatling-reach.md`:

| | Gatling can assert |
|---|---|
| Scope | `Global`, `ForAll`, `Details(parts)` — a path of recorded group and request names, and nothing else |
| Response time | `min`, `max`, `mean`, `stdDev`, `percentile(Double)` — target typed `Int`, in milliseconds |
| Request counts | `allRequests`, `failedRequests`, `successfulRequests`, each with `count` and `percent` |
| Throughput | `requestsPerSec`, a `Double` target |
| Conditions | `lt`, `lte`, `gt`, `gte`, `between`, `around`, `deviatesAround`, `is`, `in` |
| Abort | none |

---

## R2. What in the current corpus fails that bar?

**Decision**: Replace both example documents. Address requests by name, not by route.

**Rationale**: Checked predicate by predicate against R1. **Eight of the twelve predicates in the
published corpus cannot be run by Gatling**, and every one of them fails for the same reason: the
selector is `http.route`, which Gatling's assertion path cannot express — its scope is recorded
group and request names, not routes, methods or status codes.

| Document | Requirement | Selector | Predicates | Runnable |
|---|---|---|---|---|
| `minimal.yaml` | `orders` | `http.route` | 1 | **0** |
| `six-statements.yaml` | `checkout` | `http.route` | 7 | **0** |
| `six-statements.yaml` | `legacy-search` | group + request name | 1 | 1 |
| `six-statements.yaml` | `everything` | `{}` | 3 | 3 |

Nothing else fails: every aggregation, operator, unit and fraction in use is within reach. `sum`
and `neq` — the other two gaps R1 records — do not currently appear.

**Alternatives considered**: *Keep `http.route` and mark those examples unrunnable.* Rejected —
FR-010 admits no exception, and an example labelled "cannot be run" teaches the shape anyway,
which is the failure User Story 2 describes.

---

## R3. What should the corpus contain instead?

**Decision**: Three documents, each a **case** rather than a catalogue:

| File | The question it answers | What only it shows |
|---|---|---|
| `one-request-is-fast.yaml` | "This one call must stay under 500 ms." | The smallest valid document; addressing one request by name |
| `fast-and-reliable.yaml` | "This call must be fast *and* not fail." | One selector, several statements — the idea that a requirement is one human sentence; the `bad` fraction, as share and as count |
| `the-run-held-up.yaml` | "Did the whole run behave, and did it even reach the load?" | `selector: {}`; a guard beside criteria, and why a green criterion under a violated guard proves nothing |

**Rationale**: FR-013, and the shape of OpenSLO's own `examples/` — `budgeting-method` and
`treat-low-traffic-as-equally-important` are questions, not field listings. `minimal.yaml` and
`six-statements.yaml` are named after the format's internals; a reader with a problem cannot tell
which one to open.

Three rather than two because guards are the format's one distinctive idea and have never appeared
in a validated example — they exist only in prose and in the sketches this feature deletes.

**Alternatives considered**: *Keep one document showing every field.* Rejected — that is what
`six-statements.yaml` is, and FR-013 rules it out. The field description is where a complete
listing belongs.

---

## R4. Which arguments in the decision records are load-bearing?

**Decision**: Ten of the nineteen decisions justify a field that exists; they become per-field
notes in the field description. Nine describe machinery that does not exist; they are dropped.

| Carried forward — justifies a live field | Dropped — nothing it describes exists |
|---|---|
| D3 names come from OpenTelemetry | D1 what to call the project |
| D4 structure, no string DSL | D2 the three-layer split |
| D5 `unit` is mandatory | D8 the two indicator shapes (already retired) |
| D6 `guards` | D9 the result document (out of scope) |
| D7 `workload` reserved and unused | D10 as few document kinds as possible |
| D14 `loadtest.request.name` as the addressing fallback | D11 an adapter is a semantic mapper |
| D15 units are a closed enumeration | D12 mapping as data |
| D16 a YAML subset that maps onto JSON | D13 conformance levels (already retired) |
| D17 strict parsing, unknown field is an error | D18 the data source is not in the document |
| ADR-0003 selection written once | D19 Go-friendliness as a selection criterion |

**Rationale**: The test is mechanical and can be applied by a reviewer: does the decision explain
a field the schema currently defines? D14 is the one to be careful with — it is the reason
`loadtest.request.name` exists, and after R2 it is the **only** way the corpus can address a
request, which is why FR-018 exists.

**Alternatives considered**: *Keep `reference/adr/` as a directory.* Rejected by the approved
shape. OpenSLO carries no decision records in-repo either.

---

## R5. If the decision records go, what does a compatibility-sensitive change require?

**Decision**: An issue argued before the files change, plus the rejected-alternative line in
`GLOSSARY.md`. The constitution's "MUST NOT change without an ADR" becomes "MUST NOT change
without an issue that argued it, and a glossary entry recording what was rejected".

**Rationale**: This surfaced while answering R4 and is not in the specification. The constitution
names three compatibility-sensitive surfaces and says they may not change without an ADR. Deleting
`reference/adr/` while leaving that clause standing would leave a rule that cannot be obeyed —
the same defect as Principle VII binding against a deleted architecture, which FR-019 already
fixes. Both instruments already exist: Principle I requires naming disagreements to be argued in
an issue, and requires a rejected alternative in the glossary. Nothing new is introduced.

**Alternatives considered**:

- *Keep `reference/adr/` only for future decisions.* Rejected: a directory kept empty of its own
  history to satisfy one clause is the clause deciding the layout.
- *Drop the compatibility-sensitive surface entirely.* Rejected: the surfaces are real — a borrowed
  OpenTelemetry name and a field name in a published example are exactly what a downstream consumer
  would break on.

---

## R6. What happens to the gate when the files it checks disappear?

**Decision**: Two sections are deleted with what they checked; four survive unchanged; one narrows.

| Section | After the cut |
|---|---|
| YAML parses | Survives. Its glob covers `docs/**/*.yaml`, which becomes empty — `examples/*.yaml` keeps it non-empty, so its "found nothing" guard still means what it says |
| Maps one-to-one onto JSON | Survives, narrowed to `examples/*.yaml` |
| Examples validate against the schema | Survives unchanged — the point of the gate |
| The schema holds up its own examples | Survives, and **is already broken**: its seven probes pass vacuously (issue #37). Out of scope here; the plan does not silently inherit it |
| Internal links resolve | Survives unchanged |
| `docs/` is isolated | Survives. `docs/` becomes one file and the rule still holds |
| **Examples are labelled as sketches** | **Deleted** with `docs/examples/`. Left standing it would fail with `docs/examples/ holds no sketch to check` — the anti-silent-green guard firing on the wrong input |

**Rationale**: FR-009 requires every surviving check to still be checking something. Verified by
inspection of each glob against the post-cut tree, and recorded as a contract so the tasks can be
checked against it rather than against a memory of this paragraph.

**Alternatives considered**: *Keep the sketch check and let it pass on an empty directory.*
Rejected outright — that is the silent green the gate exists to prevent.

---

## Constitution consequences, consolidated

Removing Principle VII and the ADR requirement makes this a **MAJOR** amendment by the
constitution's own versioning policy: a principle is removed, and a binding constraint is
redefined to permit what it previously forbade. Version **3.0.0**.

| Principle | After |
|---|---|
| I. Vocabulary Before Features | Survives; path becomes `GLOSSARY.md`; "before an ADR" becomes "before an issue" |
| II. Borrow Names, Never Invent Them | Survives unchanged — it governs `metric` and selector keys, both live |
| III. No Silent Green | Survives, trimmed. Its bullets about rendering, target descriptions and absent-data declarations describe machinery that does not exist. What remains: an unknown field is a parse error; a check that cannot run fails rather than skips; an artifact nothing validates says so |
| IV. Honest Status | Survives unchanged, and is what R1's dated table answers to |
| V. Structure Over Grammar | Survives unchanged |
| VI. The Requirement Is Target-Blind | Survives, and is what FR-014 protects: the corpus narrows to Gatling, the format does not |
| VII. Architecture Before Implementation | **Removed.** Its number stays withdrawn, per the constitution's own rule that a withdrawn number is not reused |
| VIII. Experiments Are Parked | Survives, reduced to `docs/`: ideas live there, nothing outside links in, and it is removable in one operation. The grandfather clause goes with the two artifacts it named |
| Compatibility Constraints | The target-description surface goes with target descriptions. The remaining two — borrowed names, and field names in published examples — change on an argued issue rather than an ADR (R5) |
