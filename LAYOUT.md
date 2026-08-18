# Repository layout

Where every kind of thing lives, who may change it, and what changing it obliges.

If you are here to add support for a load generator, you need § 5 and nothing else.

## 1. The classes

`specs/` is **not** an artifact class. It is the spec-kit working directory, and the flow is
one-directional: a follow-up specification writes artifacts into the homes named below, and
never becomes one.

| Class | Home | Who may change it | Changing it obliges | Binds later work |
|---|---|---|---|---|
| **The format** | `FORMAT.md` at the repository root, plus `schema/` once it exists | Anyone, by pull request | A term reaches [docs/GLOSSARY.md](docs/GLOSSARY.md) with a rejected alternative first; a naming disagreement is argued in an issue **before** files change; a compatibility-sensitive change requires an ADR | **Yes** |
| **Ideas and notes** | `docs/` | Anyone, by pull request | Say what is checked and what is opinion. A note may contradict the format — that is what notes are for | No |
| Decision records | `docs/adr/NNNN-slug.md` | Anyone, by pull request | A PR that contradicts an ADR amends that ADR instead; status stays `proposed` until something validates it | No, but they are why the format is what it is |
| Tool mappings | `mappings/` once it exists | Anyone, by pull request | The claimed conformance level is evidenced and dated; every gap the target cannot honour is declared | No — the conformance ladder is |
| Conformance corpus | `conformance/` once it exists | Anyone, by pull request | Every case states the outcome a conforming consumer must reach | **Yes** |
| Sketches | `docs/examples/` | Anyone, by pull request | Every file announces itself as a sketch in its first six lines. Nothing validates them | No |
| Parked experiments | `docs/experimental/` | Anyone, by pull request | Status, promotion and retirement conditions, a date; nothing outside links in; markdown only | No, by construction |
| Reference implementation | Declared, not created | Anyone, by pull request | — | No |

**Why the third column is uniform.** It reads the same in every row on purpose. The
constitution already forbids a surface only maintainers can extend — *"A target list that only
maintainers can extend is not tool-agnostic"* — and no other class has a reason to be narrower.
Classes differ by what a change **obliges**, not by who may propose it. No role vocabulary is
introduced here, because [Principle I](.specify/memory/constitution.md) prices every added
governance word and a role taxonomy would buy nothing mechanical.

### A note is deleted when it stops being a note

An idea lives in `docs/` only while it is still an idea. The moment it is **accepted into the
format**, **parked** into the experimental area, or **rejected**, the note is deleted — in the
same pull request that accepts, parks or rejects it.

This is not tidiness. A note that has already become a rule is a second source for one
decision, and two sources drift. That is the failure the format exists to prevent, applied to
the repository that defines it.

The reasoning is not lost when the note goes: it lands in an ADR, in a glossary entry's
*Rejected* line, or in the schema itself. What is deleted is the duplicate, never the argument.

**The one place "anyone" needs help.** `scripts/check-linkage.sh` gates every pull request on a
milestone **and** a registered closing link to an issue in that milestone, and an outside
contributor cannot normally set a milestone on a fork's pull request. A maintainer opens the
issue and sets the milestone on the contributor's behalf, as part of first review. Without that
sentence the uniform column is theatre.

### Why `docs/semconv/` is a note and not the format

`docs/semconv/loadtest.md` proposes names under `loadtest.*` for what OpenTelemetry does not
cover. It states in its own text that it has been submitted nowhere and that nothing emits
those names today — which makes it an idea, and `docs/` is where ideas live.

The awkward part, stated rather than hidden: two constructs in `FORMAT.md` already lean on it.
`window.phase` rests on `loadtest.phase`, and the fallback addressing rests on
`loadtest.request.name`. Both are listed in FORMAT.md's optional table with that dependency
named. A name graduates from note to format by being used in `FORMAT.md` and, eventually, fixed
in `schema/` — not by moving directory.

## 2. Governance vocabulary

These words describe the repository, not the format. They are defined here rather than in the
glossary, which is the format's three-layer vocabulary and does not gain a fourth layer. A word
that collides with one already in the glossary is settled **there** instead, where the collision
is visible — that is why `target` and `monitoring backend` are in [docs/GLOSSARY.md](docs/GLOSSARY.md)
and not below.

| Word | Meaning | Rejected |
|---|---|---|
| **artifact class** | A kind of thing the repository holds, with exactly one home and one rule for changing it | `artifact type` — `type` already names a parsing concern and appears in the format as `error.type` |
| **home** | The single directory an artifact class lives in | `owner` — conflates location with permission, which is a separate column |
| **normative core** | The class later specifications must obey | `spec` — the repository is explicit that it is not one yet |
| **compatibility-sensitive surface** | The published set of things that cannot change without a decision record | `public API` — there is no API, and the phrase imports stability promises nothing here makes |
| **experimental area** | The parked class, outside that surface and removable in one operation | `incubator` — implies a pipeline to graduation that nothing here operates |
| **follow-up spec** | One concrete future task with a boundary and a dependency | `roadmap item` — implies a schedule; these carry dependencies, not dates |
| **obligation** | What a change to a class requires of the person making it | `policy` — pulls towards OPA and rule engines |
| **non-conformance list** | The published record of what is currently mis-filed | `tech debt` — invites deferral rather than disclosure |
| **component role** | A named job on the path from requirement to outcome, defined by input, output and forbidden knowledge | `layer` — already used for the vocabulary's three layers, and roles are contracts rather than strata |
| **tool mapping** | The data that binds the format to one target | `binding` — collides with `MetricMapping`, and `binding` is already load-bearing in this repository as an adjective meaning normative |
| **file adapter** | The sub-role of `Adapter` that reads a target's output files | `reader` — in this repository's documents `reader` means a human, and two success criteria rest on that sense |

## 3. What is currently mis-filed

Published rather than fixed. [AGENTS.md](AGENTS.md) forbids opportunistic refactors outside
scope, so these move in their own pull requests — and each move carries an obligation that is
cheaper to know now than to discover mid-rename.

| Path | Belongs to | Why not moved now | The move's obligation |
|---|---|---|---|
| `docs/examples/mapping-k6.yaml` | Tool mappings | Linked from five other documents; a move turns `scripts/verify.sh` red across the tree | **`verify.sh`'s sketch-label check is hardcoded to `docs/examples/*.yaml`.** A mapping relocated to `mappings/` silently stops being checked until the script is extended. Extend it in the same PR |
| `docs/examples/mapping-jmeter.yaml` | Tool mappings | Same | Same |
| `docs/compatibility.md` | Three classes at once | Splitting it is a separate concern from publishing this layout | It spans conformance levels (normative), the dated tool survey (evidence) and the Go notes (proposal). A split must keep the survey's date attached to the survey |
| `docs/references.md` | Evidence, which has no class | Inventing a class for one file costs a governance word | Either widen the normative core's definition or accept it as an unclassified note, stated as such |
| `docs/units.md` | Normative core | Already correctly filed; listed because its status line predates the layout | Confirm it announces its own status |
| `mappings/` | Tool mappings | The directory does not exist yet | Created by the first target follow-up specification, not by this document |

## 4. The compatibility-sensitive surface

This document does **not** republish the list. The constitution owns it, and a second copy is a
copy that can drift — which the constitution's own supremacy clause makes wrong by definition.

The authoritative list is in
[the constitution's Compatibility Constraints](.specify/memory/constitution.md). The
per-class column in § 1 says whether a class touches it; the constitution says what "it" is.
Extending the list is a constitutional amendment, not a layout change.

## 5. Adding support for a target

The whole point of the layout: this needs no permission and touches no normative-core file.

1. Write one `kind: MetricMapping` document in `mappings/`, named for the target.
2. Declare, at minimum: the correspondence between the target's names and canonical ones; the
   unit conversion for each; the correspondence between the target's labelling and canonical
   attributes; how the target signals a failed request; and how it derives percentiles.
3. Declare the conformance level the mapping claims, and **the list of constructs the target
   cannot honour**. An undeclared gap is a defect of the mapping, not of the format.
4. Evidence the claimed level with a **dated manual verification against the target's own
   documentation**, in the mapping's own annotations. This is what
   [Principle IV](.specify/memory/constitution.md) requires of every claim about an external
   tool.
5. Open a pull request. A maintainer attaches the milestone and the closing link if you cannot.

**This procedure is unenforceable today, and says so.** There is no schema to validate the
mapping against and no conformance corpus to run it through; both are follow-up specifications.
Until they exist, review is by reading, and the dated evidence in step 4 is the only thing
standing behind a conformance claim.

Reviewing a submitted mapping means checking: every canonical name used by the reference example
is covered or declared missing; every unit conversion is stated rather than implied; the claimed
level matches what the evidence shows; and the gap list is not empty when the survey says it
should not be.

## 6. Cross-repository integrations

A tool-native integration — a Gatling plugin, a k6 extension — lives in **that tool's own
repository** and consumes this one. It never lives here.

**This repository is authoritative** for the format, the vocabulary and the conformance levels.
An integration that disagrees is wrong and is fixed there, not here.

How drift becomes visible is deliberately unanswered: every detection mechanism is an
executable artifact, and this feature ships none. Detection is assigned to the conformance-corpus
follow-up specification, which is the first artifact capable of failing when an integration
diverges.
