# Contributing

Arguments are as welcome as pull requests. Most useful: a real requirement the format cannot
express, a reason one of its decisions is wrong, and better names — the vocabulary is deliberately
narrow and every added word is a cost paid by every reader.

## Where things live

| | |
|---|---|
| [README.md](README.md) | the format: what it is, and every field |
| [`schema/`](schema/) | the JSON Schema — what actually decides |
| [`examples/`](examples/) | validated documents; the gate fails if one stops validating |
| [GLOSSARY.md](GLOSSARY.md) | the terms, each with the alternative that was rejected |
| `docs/` | **ideas** — constructs the format does not have. Nothing here links into it |

## How an idea becomes part of the format

```
an idea in docs/  ->  argued in an issue  ->  a GLOSSARY.md entry with a rejected
alternative  ->  the schema  ->  the idea's note is deleted
```

**The last step is not optional.** A note that has become a rule is a second source for one
decision, and two sources drift — which is the failure this format exists to prevent, applied to
the repository that defines it. What survives the deletion is the glossary entry's *Rejected*
line, or the schema itself. What is deleted is the duplicate, never the argument.

Two surfaces need the argument in an issue before any file changes: an OpenTelemetry name the
format borrows, and a field name that appears in a published example. Both are things a
downstream consumer breaks on.

## Proposing a change

1. Open an issue and argue it. For a naming change, say what the current term gets wrong; for a
   new construct, say what case the format cannot express today.
2. Branch from `main`. One concern per pull request — a change to the format and a tidy-up of the
   prose are two. A milestone is one concern: its issues land as one pull request carrying one
   commit each, not as a stack of pull requests.
3. `bash scripts/verify.sh` must pass. It needs `python3` with `pyyaml` and `jsonschema`.
4. Assign the pull request to a milestone and link the issue it closes. `scripts/check-linkage.sh`
   gates this in CI. If you cannot set a milestone from a fork, a maintainer does it in review.

## Adding an example

An example must be a **case** — a question somebody actually has — not a listing of available
fields. It must also be runnable: every predicate has to be assertable by a real load generator,
which today means Gatling. `scripts/verify.sh` checks that, and [README.md](README.md) says what
Gatling can reach.

The format is deliberately wider than the corpus. `http.route`, `sum` and `neq` are valid and no
example uses them, because nothing available can run them yet.
