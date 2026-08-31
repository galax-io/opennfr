---

description: "Tasks for 012-the-metric-names-are-ours"
---

# Tasks: The Metric Names Are Ours

**Input**: [spec.md](spec.md) and [#89](https://github.com/galax-io/opennfr/issues/89)

**Tests**: no separate test tasks. The probes T009 adds are deliverables, not tests of the feature;
what validates it is that each new row is exercised in both directions and that the retired name is
refused. Both are inside T009 and T010.

## Format: `[ID] [P?] Description`

## Path Conventions

```text
GLOSSARY.md                                      # § metric amended; two entries minted
README.md                                        # § Names; reach § Metrics, § Selection, § Units,
                                                 #   § How these tables are applied
schema/opennfr.io/v1/requirementset.schema.json  # four embedded examples; no enumeration added
examples/                                        # four documents migrate
scripts/verify.sh                                # METRIC -> two names, SELECTIONS, the joint rule,
                                                 #   probes and floors
```

---

## Phase 1: Vocabulary first

**Purpose**: Principle I — a new term reaches `GLOSSARY.md` before it reaches an example, a schema or
an implementation. Two names are minted, and the entry that declined one of them is amended.

- [X] T001 Amend `GLOSSARY.md` § *metric* (**FR-007**): it records two decisions this change reverses — the mint bar as applied to a group's cumulated response time, and the claim that *"no scope denotes the requests a path encloses"*, which this milestone verified false. Development Workflow requires the entry to be amended rather than contradicted.
- [X] T002 Add `GLOSSARY.md` § *loadtest.request.duration* (**FR-001**, **FR-006**): the duration of one recorded operation by the generator's own clock, protocol an attribute of the operation. *Rejected*: `http.client.request.duration`, with Fault 2 as the reason — it is published by other producers, so a requirement document and a production dashboard could carry one string for two measurements.
- [X] T003 Add `GLOSSARY.md` § *loadtest.group.duration* (**FR-002**, **FR-006**): the duration of one traversal of a group. *Rejected*: `aggregation: sum` over `loadtest.request.duration` — the quantity is two nested aggregations and `aggregation` states one.

**Checkpoint**: both names exist in the vocabulary before anything writes them — **SC-005**.

---

## Phase 2: What an author may write

- [X] T004 `README.md` § *Names* → Metrics table (**FR-001**, **FR-002**, **FR-003**): the two minted names replace `http.client.request.duration`; the three remaining borrowed names stay, and the text says why Fault 2 does not reach them.
- [X] T005 `README.md` § *Names* — the qualification (**FR-005**): semconv having a **string** is not semconv having this **quantity**, and where a semconv name would import a producer this format is not, a `loadtest.*` name is required rather than permitted. The paragraph saying *"No name is minted here"* goes, because one is.
- [X] T006 [P] Migrate `examples/` — four documents — and the schema's four embedded examples (**FR-004**, **FR-014**). No enumeration of metric names is added to the schema.

**Checkpoint**: the corpus says what it measures — **SC-002**.

---

## Phase 3: What a tool can run

- [X] T007 `README.md` reach § *Metrics* (**FR-008**): a row for each minted name and a row retiring `http.client.request.duration` with its reason. The group row carries the quantity Gatling computes — the **sum** of the enclosed operations' durations — and records that the wall-clock quantity is computed and unreachable (**FR-011**), with the jar and date it was read from (**FR-012**).
- [X] T008 `README.md` reach § *Selection* and § *How these tables are applied* (**FR-009**, **FR-010**): the hierarchy-only row becomes **can**, paired with `loadtest.group.duration`, and the section says that this one pair is judged **jointly** — the only place where an axis does not decide alone.

**Checkpoint**: every published row states its reason and its source — **SC-001**, **SC-004**.

---

## Phase 4: The gate implements every row it publishes

- [X] T009 `scripts/verify.sh` (**FR-013**): `METRIC` becomes the two names; `SELECTIONS` gains the hierarchy-only shape; a joint rule refuses a group metric under a request selection and a request metric under a group selection. Probes in both directions for each new row, and the floors beside them raised.
- [X] T010 Verify: the retired name is refused, the hierarchy-only selection renders only with `loadtest.group.duration`, every new probe fires when its rule is removed, and `bash scripts/verify.sh` is green (**FR-016**, **SC-003**, **SC-006**).
- [ ] T011 Commit as `feat(format): the metric names are ours (#89)` with `Closes #89`, and add the closing line to [#90](https://github.com/galax-io/opennfr/pull/90).

**Checkpoint**: #89 closed; milestone v0.8.0 has no issue without a closing PR.
