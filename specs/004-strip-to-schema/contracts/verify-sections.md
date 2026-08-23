# Contract: what the gate checks after the cut

**Feature**: `004-strip-to-schema`

FR-009: every check must still be checking something, or fail rather than report success on an
empty scan. One section is deleted with what it checked; seven survive; one is added.

| # | Section | Scans | After the cut |
|---|---|---|---|
| 1 | YAML parses | `examples/*.yaml` + `docs/**/*.yaml` | **Survives.** `docs/` holds only `ideas.md`, so the second glob goes empty; the first keeps the section non-empty and its "found nothing" guard keeps meaning what it says |
| 2 | Maps one-to-one onto JSON | `examples/*.yaml` + `docs/examples/**/*.yaml` | **Survives, narrowed** to the first glob. Anchors, aliases, merge keys and non-finite numbers are still rejected |
| 3 | Examples validate against the schema | `examples/*.yaml` | **Survives unchanged.** The point of the gate, and the only check the format itself depends on |
| 4 | The schema holds up its own examples, and still rejects | the schema | **Survives unchanged, and is known broken.** Its seven probes pass vacuously — issue #37. Not fixed here; recorded so the tasks do not silently inherit a green that means nothing |
| 5 | Internal links resolve | every `*.md` outside dotfiles | **Survives unchanged**, and is what proves FR-003 |
| 6 | `docs/` is isolated | every tracked markdown file outside `docs/` and `specs/`, plus everything under `docs/` | **Survives, widened.** It now checks all three clauses of Principle VIII, not one: `docs/` is markdown-only, every idea states its condition, and nothing outside links in. Dot-directories are no longer exempt — `.github/` and `.specify/` hold markdown a reader follows |
| 7 | Docs are English | tracked `*.md` and `*.yaml` | **Survives unchanged** |
| 8 | **Examples are labelled as sketches** | `docs/examples/*.yaml` | **Deleted** with the sketches. Left standing it fails with `docs/examples/ holds no sketch to check` — the anti-silent-green guard firing on the wrong input. The `docs/`-absent branch added in #45 goes with it |

## One section is added

**Decided during task generation, not during planning.** FR-010 — every published predicate must
be assertable by Gatling — is a rule on the corpus, and `quickstart.md` § 2 checks it by hand. A
rule checked only by hand is one the next example quietly breaks, which is the failure this
repository keeps meeting: the vacuous self-check probes (#37), the sketch guard firing on the
wrong input (§ 8 above). Principle III applies to this feature's own work.

| # | Section | Scans | Fails when |
|---|---|---|---|
| 9 | **Examples are assertable by Gatling** | `examples/*.yaml` | the predicate does not match a row of the capability table exactly. Reports the count of predicates it checked, so an empty scan cannot read as a pass |

The table is a **partition**, not a denylist: `(shape, aggregation)` keys a row giving the native
statistic, the units it accepts and whether its target is an `Int`, and anything unlisted is
rejected. Written the other way round — reject `sum`, reject `neq`, accept the rest — it passed a
filtered `bad`, an empty `bad`, a percentile in `%` and a fractional millisecond, all four of
which a renderer would have had to approximate.

This checks the **published corpus**, never the schema. The schema keeps `http.route`, `sum` and
`neq` (FR-014), and the section must never be extended to read the schema — that would be the
format narrowing to one tool, which Principle VI forbids. The section carries that sentence as a
comment.

## Acceptance

After the change:

- `bash scripts/verify.sh` reports **PASS**, and every section prints what it scanned.
- Section 9 **FAILS** on each of: an `http.route` selector, `bad: {}`, a filtered `bad`, a `good`
  in any form, `sum`, `neq`, a percentile in `%`, and a fractional millisecond or count. Probed,
  not assumed.
- Section 6 **FAILS** on a link from `.github/` into `docs/`, and on a non-markdown file under
  `docs/`. Probed, not assumed.
- No section reports `ok` having scanned zero files.
- `rm -rf docs && bash scripts/verify.sh` still reports **PASS** — the isolation property survives
  the cut rather than being quietly dropped with the directory that motivated it.
- Adding a markdown link from `README.md` into `docs/` makes section 6 **FAIL**. Probed, not
  assumed.
