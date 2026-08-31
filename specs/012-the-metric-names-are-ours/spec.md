# Feature Specification: The Metric Names Are Ours

**Feature Branch**: `011-identity-has-one-scope`

**Created**: 2026-08-31

**Status**: Draft

**Input**: [#89](https://github.com/galax-io/opennfr/issues/89), milestone **v0.8.0**, `severity:critical`. Filed after the milestone's first three issues had landed and brought into scope on the maintainer's call, so it rides in the same pull request. It is a second spec rather than a section of `011-identity-has-one-scope` because it is a second argument: that one is about what tells two statements apart, this one is about who owns a name.

**Scope note**: `http.client.request.duration` is retired for `loadtest.request.duration`, and `loadtest.group.duration` is minted beside it. This is the first time this repository mints a metric name, and it reverses two decisions `GLOSSARY.md` records — which is why the entry that records them is amended rather than contradicted.

Unlike `011`, this one **does** change the published corpus: four documents carry the retired name.

## Decisions

### Session 2026-08-31

- **Q**: #89 asks for the old name to be *"deprecated with a window and then removed — accepted with a warning while the corpus and any existing documents migrate"*. The gate has two outcomes, `ok` and `FAIL`; a warning is a third, and Principle III forbids reporting success by omission. → **A**: **No window. A clean cut.** The corpus is four documents in this repository, the one external consumer #89 names is *"ready to follow"*, and `AGENTS.md` says nothing is stable yet. A window would buy a deprecation period for documents nobody has, at the price of a third verdict in the gate and an argument for why it is not a silent green.

- **Q**: #89 says the borrowing rule *"needs one qualification"* — semconv having a **string** is not semconv having this **quantity**. That rule is also Principle II of the constitution, word for word. Does the constitution get the qualification? → **A**: **No amendment.** *"Equivalent"* is read as an equivalent **quantity**, which is what the word means and what makes the clause coherent: semconv has no name for *the duration of one recorded operation, whatever produced it, by the generator's own clock*, so Principle II already permits the mint. `README.md` § *Names* states what "equivalent" means; the constitution stays at **4.0.0**.

### What was verified here, and what was taken from the issue

#89 is sourced to Gatling 3.13.5. Every load-bearing claim it makes about the assertion path was **re-read from the jars on this machine** rather than quoted, with `javap` against `gatling-charts` 3.13.5 and `gatling-shared-model` 0.0.11 on **2026-08-31**:

| Claim | Verified |
|---|---|
| The assertion path reads `AssertionStatsRepository`, which has exactly four methods | `allRequestPaths`, `findPathByParts`, `requestGeneralStats`, `groupCumulatedResponseTimeGeneralStats` |
| A group's cumulated response time **is** assertable | `groupCumulatedResponseTimeGeneralStats(List[String], Option[Status])` is on the interface |
| A group's wall-clock duration is **not** | `groupDurationGeneralStats` exists on `LogFileData` and is **absent** from `AssertionStatsRepository`, so no assertion can reach it |
| A group statistic admits the same aggregations as a request's | both return `AssertionStatsRepository.Stats(min: Int, max: Int, count: Long, mean: Int, stdDev: Int, percentile: Double => Double, meanRequestsPerSec: Double)` — one type, so one set of aggregations and the same integer-threshold rule |

What was **not** re-verified and is carried from #89 on its own authority, dated to its reading: that `gatling.charting.useGroupDurationMetric` reaches the report generator only and never the assertion path. It is consistent with what was verified — the flag cannot change an assertion that has no access to the quantity it selects — and the reach text says which reading it rests on.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A mixed run stops rendering to something it does not say (Priority: P1)

An author writes `metric: http.client.request.duration` under `selector: {}`. Every row of the Selection and Metrics tables says **can**, and the document is schema-valid. It renders to Gatling's global scope, whose buffer holds every entry recorded through `statsEngine.logResponse` — JMS, JDBC, every third-party protocol plugin. On an HTTP-only run the two quantities coincide. On a mixed run the document says *99th percentile of HTTP client request duration* and the assertion evaluates *99th percentile of the response time of every recorded operation*, and nothing anywhere says so.

After this story the name states the quantity that is actually measured: `loadtest.request.duration`, the duration of one recorded operation by the generator's own clock, protocol left to the operation.

**Why this priority**: it is the `severity:critical` case — a document silently rendering to something it does not say — and every other change here follows from fixing the name.

**Independent Test**: write the mixed-run document with the new name and read it against the Metrics row. The row says what is measured, and the document says the same thing.

**Acceptance Scenarios**:

1. **Given** the retired name, **When** an author writes it, **Then** the gate refuses the document for a published example and the reach table says why.
2. **Given** `loadtest.request.duration` under `selector: {}`, **When** a reader asks what is measured, **Then** the answer is the same on a mixed run as on an HTTP-only one.
3. **Given** `README.md` § *Names*, **When** a reader asks why the format mints a name here, **Then** the answer names the vantage — `loadtest.*` is the vantage statement — and does not rest on semconv lacking a string.

---

### User Story 2 - A group scope becomes assertable, and says which quantity (Priority: P2)

`{loadtest.group.name: [G₁, …, Gₙ]}` with no request name is **cannot** today, and the row's reason is that *"no name in § Names is true of"* a group's cumulated response time. That reason was a missing name, not a missing capability: `AssertionStatsRepository.groupCumulatedResponseTimeGeneralStats` is on the interface and has been all along.

After this story the selection renders, paired with `loadtest.group.duration`, and the reach text says which of the two quantities that could answer to "the duration of a group" a Gatling run computes.

**Why this priority**: it is the half of [#52](https://github.com/galax-io/opennfr/issues/52) that could not be closed until a name existed. It is second because it depends on the minting rule Story 1 establishes.

**Independent Test**: the hierarchy-only selector with `loadtest.group.duration` renders; with any other metric it does not; and the reach text names the quantity Gatling computes and the one it does not.

**Acceptance Scenarios**:

1. **Given** `{loadtest.group.name: ["Checkout"]}` with `loadtest.group.duration`, **When** the gate judges it, **Then** it renders.
2. **Given** the same selection with `loadtest.request.duration`, **When** the gate judges it, **Then** it is refused: a hierarchy-only path resolves to a group, and a group has no request statistics of its own.
3. **Given** the Identity of the quantity, **When** a reader asks what Gatling computes, **Then** the text says the **sum of the enclosed operations' durations**, not the elapsed time of the traversal, and says the wall-clock quantity is computed but unreachable by any assertion.

---

### Edge Cases

- **`sum` is not a substitute.** The group quantity is a percentile across traversals of a sum across the operations each traversal encloses — two nested aggregations, and `aggregation` states one. It is a distinct measured quantity, so it is a distinct name.
- **Aliasing.** Pointing the old name at the new one would make `metric: http.client.request.duration` over a Kafka run conformant and false. It is retired, not aliased.
- **The other three names in § *Names*.** `http.client.request.body.size`, `http.client.response.body.size` and `http.server.request.duration` keep their names. Fault 2 does not reach them: the body sizes are volumes and unrenderable either way, and `http.server.request.duration` names a *different vantage* on purpose — it is the one place the format deliberately says "not the generator's clock".
- **A rejected alternative reversed.** `GLOSSARY.md` § *metric* declined a name for a group's cumulated response time *"because no scope denotes the requests a path encloses"*. That reason is false and this milestone verified it false. Development Workflow requires the entry to be amended rather than contradicted.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `loadtest.request.duration` MUST be minted: the duration of one recorded operation, measured by the load generator's own clock, with the protocol an attribute of the operation rather than part of the measurement.
- **FR-002**: `loadtest.group.duration` MUST be minted: the duration of one traversal of a group.
- **FR-003**: `http.client.request.duration` MUST be retired — removed from § *Names* as a name an author may write, and carried in the reach tables as a row that refuses it with the reason. It MUST NOT be aliased to either new name.
- **FR-004**: The published corpus MUST migrate in the same commit. Four documents in `examples/` and four embedded examples in the schema carry the retired name.
- **FR-005**: `README.md` § *Names* MUST state the qualification the mint rests on: semconv having a **string** is not semconv having this **quantity**, and where a semconv name would import a producer this format is not, a `loadtest.*` name is required rather than merely permitted. The paragraph that says **no name is minted here** MUST be replaced, because one is.
- **FR-006**: `GLOSSARY.md` MUST gain an entry for each minted name before either appears in an example, a schema or an implementation, as Principle I requires, and each MUST record a rejected alternative.
- **FR-007**: `GLOSSARY.md` § *metric* MUST be **amended**, not contradicted. It records two decisions this change reverses — the mint bar as applied to a group's cumulated response time, and the claim that no scope denotes the requests a path encloses. Development Workflow requires the amendment to be in this PR.
- **FR-008**: The reach § *Metrics* table MUST carry a row for each minted name and a row retiring `http.client.request.duration`, each with its reason.
- **FR-009**: The reach § *Selection* row for `{loadtest.group.name: [G₁, …, Gₙ]}` with no request name MUST become **can**, paired with `loadtest.group.duration`.
- **FR-010**: The pairing MUST be stated as a **joint** constraint and enforced as one. A hierarchy-only path resolves to a group, so it admits `loadtest.group.duration` and nothing else; every other selection admits `loadtest.request.duration` and not the group name. § *How these tables are applied* MUST say that this one pair is judged jointly, because the section otherwise claims each axis decides alone.
- **FR-011**: The reach text MUST say which quantity a Gatling run computes for `loadtest.group.duration` — the sum of the enclosed operations' durations, not the elapsed time of the traversal — and MUST record that the wall-clock quantity is computed and unreachable by any assertion.
- **FR-012**: Every claim about Gatling MUST carry the artifact it was read from and the date. Claims re-read here MUST be dated to this reading; the one carried from #89 MUST say so rather than borrowing this reading's authority.
- **FR-013**: `scripts/verify.sh` MUST implement every row it publishes: the two metric names, the retired one, the new selection, and the joint rule. Each MUST be probed in both directions, with the floors raised beside the probes.
- **FR-014**: The schema MUST NOT enumerate metric names. It does not today and this change does not start: only its embedded examples move.
- **FR-015**: `.specify/memory/constitution.md` MUST NOT change. Principle II already permits the mint under the reading recorded in § *Decisions*.
- **FR-016**: `bash scripts/verify.sh` MUST be green at the commit, and every document in `examples/` MUST keep its validity and gain no new refusal.

## Success Criteria *(mandatory)*

- **SC-001**: No artifact outside `specs/` and `docs/` offers `http.client.request.duration` as a name an author may write, and the reach tables refuse it with a reason.
- **SC-002**: `examples/` validates and renders with the new names, and the mixed-run document a reader can now write says the quantity it renders to.
- **SC-003**: A hierarchy-only selection renders with `loadtest.group.duration` and is refused with any other metric, and both directions are probed.
- **SC-004**: Every reach claim about a group statistic names the jar it was read from and the date, and the one claim carried from #89 is marked as carried.
- **SC-005**: `GLOSSARY.md` carries an entry for each minted name with a rejected alternative, and § *metric* no longer records a decision this PR reverses.
- **SC-006**: `bash scripts/verify.sh` is green, and the probe counts are higher than before by the number of probes added.

## Assumptions

- **The quantity exists outside this repository.** The mint bar in `GLOSSARY.md` § *metric* — *"a name is minted only where something outside this repository already records the quantity under one"* — is cleared by the quantity, not the string: Gatling records a response time per recorded operation and a cumulated time per group, JMeter records elapsed time per sample and per transaction controller, k6 records per-request and per-group timings. One target's feature is not the grounds; three tools recording the same quantity is.
- **The corpus migrates, and its meaning does not.** Every published document is HTTP-only, so the number each asserts is unchanged. What changes is that the name now states what was always being measured.
- **`http.server.request.duration` stays.** It is the one name in § *Names* whose whole point is a different vantage, and Fault 2 does not reach it.
- **One commit.** #89 is one issue, so it is one commit, with the spec commit before it.
