# Conformance corpus

What a conforming consumer must reproduce, as data. Three parts, three notions of a case.

| Part | A case is | The expectation lives |
|---|---|---|
| `parse/` | one document that must be accepted, or rejected | in a sidecar file naming every finding and the exact path it must report |
| `render/` | a directory holding one document and one rendering per target | the rendering **is** the expectation |
| `gate/` | a described mutation of a tracked file | the exit code and the line `scripts/verify.sh` must print |

## Two rules that make a rejection case readable

**One mutation per case.** A rejection case differs from a valid document by exactly one
change, so exactly one rule can be responsible for the outcome. A case that breaks three rules
proves only that something was wrong.

**The expectation is a sidecar, never inside the case.** A case file is the document exactly as
written. An `expect:` key inside it would itself be an unknown field — and unknown fields are
what several of these cases exist to catch, so the expectation would mask the finding.

Rejection cases may not live in `examples/`: everything there must validate, and a field name
in a published example is a compatibility-sensitive surface.

---

## What this corpus does **not** establish

Required by the specification, and worth reading before quoting a green run.

**Nothing here renders.** The rendering implementation belongs to whoever integrates a target,
in that target's own repository. What lives here is an **oracle** — the triple *(document,
target description, rendering)* that any implementation, in any language, must reproduce. Until
an implementation somewhere runs against it, the corpus is unfalsified: a very well-formed
guess.

**It can be uniformly wrong about a target.** Every check is a consistency check between files
this repository writes. If a target description wrongly claims a tool lacks a comparison, and
the case agrees, both are wrong and the build is green. The only defence is the dated source
each claim carries — and a machine can verify that a date *exists*, never that the claim is
true.

**It does not check that the target accepts the assertion.** The corpus pins the arguments,
never the API. A statistic name the tool does not have passes every check here; that failure
surfaces only in an integration test in the tool's own repository, running a real simulation.

**The counting rule closes over the document, not over intent.** It catches a predicate the
renderer dropped. It cannot catch the requirement nobody thought to write — which is the most
common real defect in requirement documents, and the one nothing mechanical will ever find.

**Two targets do not prove the shape is neutral.** Any record designed while looking at two
targets fits those two. The honest next probe is a third with native assertions of a different
shape.

---

## How it fails

Never by skipping. The runner distinguishes *ran and passed* from *could not run*, and the
second is a failure: a missing dependency, an unreadable schema, an empty corpus, or a case
with no expectation all turn the build red rather than quietly reporting nothing.

That is the same rule this repository applies to its own gate, and it is applied here from the
start because four sections of that gate once did not have it — each reporting `ok` on every
commit, on both platforms, for the life of the project, and one of them without ever having
executed.
