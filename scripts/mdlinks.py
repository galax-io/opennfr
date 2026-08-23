"""One definition of a markdown link, for the two gate sections that need one.

`scripts/verify.sh` scans links twice: once to check they resolve, once to check that nothing
outside `docs/` links into it. Those two scanners MUST agree on what a link is. When they
disagreed, the same code span passed one gate and failed the other, and documenting the isolation
rule became impossible — the text describing a link read, to one of the gates, as a link.

Issue #43 was this file's reason for existing: a `grep` for `](` cannot tell a link from a regular
expression that happens to close a bracket group with a parenthesis. The first fix for it was a
handful of `re.DOTALL` regexes, and they were worse than the grep in the way that matters here —
they masked *more* than the code they were aiming at, so a stray backtick in prose could hide a
genuinely dangling link and the gate went green. Principle III ranks that below the loud
false positive it replaced.

So the rule this module is built on: **when in doubt, report the link.** Masking is the dangerous
direction, because a mask that is too wide is silent. Every gap listed under KNOWN GAPS below errs
the other way — the gate over-reports, a human sees the FAIL and fixes it in a minute.

Behaviour here is checked against a real CommonMark renderer, not against reasoning about the
spec; `selftest()` carries the cases and the gate runs it before trusting anything in this file.

KNOWN GAPS, all in the safe direction (the gate over-reports, never under-reports):

  - An indented (four-space) code block is not masked, so link-shaped text inside one is checked.
    Deliberate: detecting one correctly needs list-item context, and getting it wrong would blank
    the indented continuation lines this repository's task files are full of — turning real links
    invisible, which is the failure this module exists to avoid.
  - A link destination split across lines is not scanned. The `grep` this replaced was line-based
    and never saw them either.
  - Reference-style links (`[a][b]` with `[b]: target` elsewhere) are not resolved.
"""

import os
import re

# An opening fence: up to three spaces, then three or more backticks or tildes. A backtick fence's
# info string may not itself contain a backtick — without that rule, a line like "```yaml``` is the
# marker." reads as a fence and swallows everything to the next fence-looking line.
FENCE_OPEN = re.compile(r"^(?P<quote>(?: {0,3}>)*) {0,3}(?P<fence>`{3,}|~{3,})(?P<info>.*)$")

LINK = re.compile(r"\]\(([^)\n]+)\)")

# Only the two schemes the previous implementation excluded, so no relative path containing a colon
# is silently dropped as though it were a URL.
SCHEME = re.compile(r"^(https?|mailto):", re.IGNORECASE)


def _mask_spans(line):
    """Blank inline code spans in one line, preserving length.

    Per-line by design. A code span may legally cross lines in CommonMark, but scanning the whole
    file at once meant one unpaired backtick could mask every link to the end of the document. The
    blast radius of a stray backtick is now the line it sits on.

    A backslash-escaped backtick cannot OPEN a span — it is literal text — but it can CLOSE one,
    because inside a span a backslash is already literal. Both halves are load-bearing: barring it
    from closing hides the links after a span that ends in one; letting it open hides the links
    after a stray escape in prose.
    """
    runs = []
    i, n = 0, len(line)
    while i < n:
        if line[i] == "`":
            j = i
            while j < n and line[j] == "`":
                j += 1
            backslashes = 0
            k = i - 1
            while k >= 0 and line[k] == "\\":
                backslashes += 1
                k -= 1
            runs.append((i, j, backslashes % 2 == 1))
            i = j
        else:
            i += 1

    out = list(line)
    idx = 0
    while idx < len(runs):
        start, end, escaped = runs[idx]
        if escaped:
            idx += 1
            continue
        width = end - start
        closer = next((j for j in range(idx + 1, len(runs))
                       if runs[j][1] - runs[j][0] == width), None)
        if closer is None:
            idx += 1
            continue
        for p in range(start, runs[closer][1]):
            out[p] = " "
        idx = closer + 1
    return "".join(out)


def strip_code(text):
    """Blank every fenced block and inline code span, preserving line count and length.

    Equal-length spaces rather than deletion: nothing on either side of a stripped span can then
    join into a `](` adjacency that was never written.
    """
    out = []
    fence = None                                   # (character, width) of the open fence
    for line in text.split("\n"):
        if fence is None:
            m = FENCE_OPEN.match(line)
            if m and not (m.group("fence")[0] == "`" and "`" in m.group("info")):
                fence = (m.group("fence")[0], len(m.group("fence")))
                out.append(" " * len(line))
                continue
            out.append(_mask_spans(line))
        else:
            char, width = fence
            m = FENCE_OPEN.match(line)
            # A closing fence is at least as long as the one that opened it and carries no info.
            if (m and m.group("fence")[0] == char and len(m.group("fence")) >= width
                    and not m.group("info").strip()):
                fence = None
            out.append(" " * len(line))
    return "\n".join(out)


def _destination(target):
    """The destination out of a link target, dropping any CommonMark title.

    `[a](x.md "the title")` addresses `x.md`. Taken whole, the title made the gate fail on a link
    that renders correctly.
    """
    target = target.strip()
    if target.startswith("<"):
        return target[1:].split(">", 1)[0]
    return target.split(None, 1)[0] if target.split(None, 1) else ""


def targets(text):
    """Every link destination in `text` that is not a URL, in source order."""
    found = (_destination(t) for t in LINK.findall(strip_code(text)))
    return [t for t in found if t and not SCHEME.match(t)]


def resolve(root, base, target):
    """Absolute path a target addresses, or None when it addresses no file.

    `root` is the repository root, `base` the directory of the file the link is written in.
    None means "there is nothing on disk to look for" — a pure anchor or a placeholder — NOT that
    the path is missing; whether it exists is the caller's question.

    A target starting with `/` is repository-root-relative, which is how GitHub renders it. Joined
    onto `base` instead, it escaped to the machine's filesystem root, where a dangling link
    reported ok and a valid one failed.
    """
    path = target.split("#")[0]
    if not path:
        return None                                # pure anchor, same file
    if any(c in path for c in "<>{"):
        return None                                # placeholder, e.g. specs/001-<feature>/
    if path.startswith("/"):
        return os.path.normpath(os.path.join(root, path.lstrip("/")))
    return os.path.normpath(os.path.join(root, base, path))


# Every case is a direction this scanner has actually been wrong in, and each was checked against
# the `marked` CommonMark renderer before being written down. Left as data so the gate can hold the
# extractor to them on every run — #43 survived as long as it did because nothing checked
# the checker.
SELFTEST = [
    ("[a](x.md)", ["x.md"], "a plain link is a link"),
    ("`[a](x.md)`", [], "a code span is not a link"),
    (r"\`[a](x.md)\`", ["x.md"], "an escaped backtick opens no code span"),
    (r"a \` b [c](x.md)", ["x.md"], "a stray escaped backtick swallows nothing"),
    ("a ` b\n[c](x.md)", ["x.md"], "an unpaired backtick cannot mask the next line"),
    (r"a `x \` [b](y.md) `c", ["y.md"], "an escaped backtick still closes a span it did not open"),
    ("  ~~~\n[a](x.md)\n  ~~~", [], "an indented tilde fence is still a fence"),
    ("  ```\n[a](x.md)\n  ```", [], "an indented backtick fence is still a fence"),
    ("````\n[a](x.md)\n````\n[b](y.md)", ["y.md"], "a longer fence closes on its own width"),
    ("```yaml``` is it.\n[a](x.md)", ["x.md"], "a triple-backtick span is not a fence opener"),
    ("> ```\n> [a](x.md)\n> ```", [], "a fence inside a blockquote is still a fence"),
    ("```\n[a](x.md)\n```\n[b](y.md)", ["y.md"], "a fence ends, and scanning resumes"),
    ("[a](\nx.md)", [], "a destination does not cross a line"),
    ('[a](x.md "the title")', ["x.md"], "a title is not part of the destination"),
    ("[a](<x.md>)", ["x.md"], "an angle-bracketed destination is unwrapped"),
    ("[a](https://example.com/x)", [], "a URL is not an internal link"),
    ("[a](HTTPS://example.com/x)", [], "a scheme is matched whatever its case"),
]

# What resolve() must do, checked as its own fixtures. The `/`-prefixed rule is the round's own
# headline fix; without a case here, reverting it leaves the gate green.
RESOLVE_SELFTEST = [
    ("/r", "sub", "/schema/x.json", "/r/schema/x.json", "a rooted target resolves against the repository"),
    ("/r", "sub", "x.md", "/r/sub/x.md", "a relative target resolves against its own directory"),
    ("/r", "sub", "../y.md", "/r/y.md", "a parent-relative target climbs from its own directory"),
    ("/r", "", "#anchor", None, "a pure anchor addresses no file"),
    ("/r", "", "specs/001-<feature>/x.md", None, "a placeholder addresses no file"),
    ("/r", "sub", "x.md#frag", "/r/sub/x.md", "a fragment is not part of the path"),
]


def selftest():
    """Every fixture the extractor gets wrong, as a list of strings. Empty when sound."""
    wrong = []
    # A floor of its own: an emptied fixture list would otherwise read as a sound extractor,
    # which is the defect this whole module was written in response to.
    if len(SELFTEST) < 15 or len(RESOLVE_SELFTEST) < 5:
        wrong.append(f"the fixture list itself has shrunk to {len(SELFTEST)}/{len(RESOLVE_SELFTEST)} "
                     f"— it is checking less than it was written to check")
    for text, want, why in SELFTEST:
        got = targets(text)
        if got != want:
            wrong.append(f"{why}: expected {want}, got {got}")
    for root, base, target, want, why in RESOLVE_SELFTEST:
        got = resolve(root, base, target)
        if got != want:
            wrong.append(f"{why}: expected {want}, got {got}")
    return wrong
