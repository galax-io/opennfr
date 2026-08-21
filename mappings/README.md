# Target descriptions

One file per target, `kind: TargetDescription`, named for the target.

A description says everything about one target: how it names things, **what it can assert and
what it cannot**, how its units convert, how it builds its own report line, and where it can
report success on absent data. Adding a target is adding one of these — it changes no schema,
no existing document, and no code anywhere.

This is the **only** artifact class in this repository where a tool name legitimately appears.
A requirement document names no tool, in a field, a value, a metric name or an example; the
whole subject of a file here is one tool, so its name belongs in `metadata.name` and nowhere
else matters.

## What every claim owes

**A source and the date it was checked.** A capability claim is an assertion about somebody
else's software, and undated it rots without anyone noticing. This is a schema constraint here,
not a convention.

**Its opposite.** Capabilities and gaps partition each axis. A combination declared in neither
is a **defect of the description**, catchable mechanically — and a description that is silent
about a capability is not claiming the target has it.

## Two things easy to get wrong

**Units are exact ratios, never floats.** Whether a threshold is *exactly* representable in the
target's own numeric type decides whether it renders at all, and a floating-point conversion
cannot answer that. The surveyed targets differ by three orders of magnitude in one direction
and by a factor of a hundred in another; a rounding opinion here produces a confident, wrong,
green result.

**Where the target can pass on absent data.** One surveyed target has an assertion scope that
exits *successfully* when it matches nothing. Nothing outside that target's own description can
discover this, and nothing downstream can prevent it — so it is declared, or it is a silent
green nobody owns.

## What does not live here

A tool-native integration — a plugin, an extension, a library that constructs the target's
assertion objects — lives in **that tool's own repository** and consumes this one. Nothing here
renders; these files say what a correct rendering would produce.

See [LAYOUT.md](../LAYOUT.md) § 5 for the full procedure, and
[docs/GLOSSARY.md](../docs/GLOSSARY.md) for the term.
