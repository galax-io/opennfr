#!/usr/bin/env python3
"""The checks, in one place.

`scripts/verify.sh` is the gate and the conformance corpus is the test suite, and both
need the same answers. If they each carried their own copy, the corpus would assert
against a copy and prove nothing about the gate that actually runs — two sources for one
rule, drifting, which is the failure this repository exists to prevent, reproduced inside
its own tooling.

So: one implementation, two callers. Every function here returns a list of findings and
prints nothing; the caller decides how a finding is shown and what it costs.

Runnable directly for one-off use:

    python3 scripts/opennfr_check.py examples/*.yaml
"""

from __future__ import annotations

import glob
import json
import math
import os
import sys
from typing import Any, Iterable, NamedTuple

SCHEMA_DIR = "schema/opennfr.io/v1"

# kind -> schema basename. A kind absent from this table has no schema, and a document
# carrying it is a failure rather than a pass: nothing would validate it.
KIND_SCHEMAS = {
    "RequirementSet": "requirementset",
    "TargetDescription": "targetdescription",
    "Rendering": "rendering",
}


class Finding(NamedTuple):
    """One thing wrong, in one place.

    `gate` names which check produced it, so a caller can group or filter. `path` is a
    document path (``spec/requirements/0/criteria/0``) where one applies, and empty where
    the finding is about the file as a whole.
    """

    gate: str
    file: str
    path: str
    message: str

    def __str__(self) -> str:
        where = f"{self.file}: {self.path}: " if self.path else f"{self.file}: "
        return f"{where}{self.message}"


class DependencyMissing(Exception):
    """A check could not run. Never the same thing as a check that passed."""


def _yaml():
    try:
        import yaml
    except ImportError as e:  # pragma: no cover - environment-dependent
        raise DependencyMissing(f"{e.name} not installed (pip install pyyaml)") from e
    return yaml


def _validator_cls():
    try:
        from jsonschema import Draft202012Validator
    except ImportError as e:  # pragma: no cover - environment-dependent
        raise DependencyMissing(f"{e.name} not installed (pip install jsonschema)") from e
    return Draft202012Validator


# --------------------------------------------------------------------------- parsing


def check_parses(path: str) -> list[Finding]:
    """The file is YAML at all."""
    yaml = _yaml()
    try:
        list(yaml.safe_load_all(open(path, encoding="utf-8")))
    except Exception as e:
        return [Finding("parse", path, "", str(e))]
    return []


def check_jsonable(path: str) -> list[Finding]:
    """Every value maps onto JSON, and no anchor, alias or merge key is used.

    ADR-0002 § D16. Both halves must happen at the event level, before ``safe_load_all``
    resolves them away: by the time it returns, an alias is an ordinary dict and the
    evidence is gone.
    """
    yaml = _yaml()
    out: list[Finding] = []

    for ev in yaml.parse(open(path, encoding="utf-8")):
        if isinstance(ev, yaml.AliasEvent):
            out.append(Finding("jsonable", path, "", f"alias *{ev.anchor} — ADR-0002 D16 forbids aliases"))
        elif getattr(ev, "anchor", None):
            out.append(Finding("jsonable", path, "", f"anchor &{ev.anchor} — ADR-0002 D16 forbids anchors"))
        elif isinstance(ev, yaml.ScalarEvent) and ev.value == "<<":
            out.append(Finding("jsonable", path, "", "merge key << — ADR-0002 D16 forbids merge keys"))

    def walk(v: Any, where: str) -> None:
        if v is None or isinstance(v, (bool, str, int)):
            return
        if isinstance(v, float):
            if not math.isfinite(v):
                out.append(Finding("jsonable", path, where, f"{v!r} has no JSON representation"))
            return
        if isinstance(v, dict):
            for k, x in v.items():
                if not isinstance(k, str):
                    out.append(Finding("jsonable", path, where, f"non-string key {k!r}"))
                walk(x, f"{where}/{k}")
            return
        if isinstance(v, list):
            for i, x in enumerate(v):
                walk(x, f"{where}/{i}")
            return
        out.append(Finding("jsonable", path, where, f"{type(v).__name__} has no JSON equivalent ({v!r})"))

    for doc in yaml.safe_load_all(open(path, encoding="utf-8")):
        walk(doc, "")
    return out


# ---------------------------------------------------------------------------- schema


def load_validators() -> dict[str, Any]:
    """One validator per kind whose schema exists. Missing files are not an error here —
    a kind with no schema becomes a finding at the document, where the file can be named."""
    V = _validator_cls()
    out = {}
    for kind, base in KIND_SCHEMAS.items():
        p = os.path.join(SCHEMA_DIR, f"{base}.schema.json")
        if os.path.exists(p):
            schema = json.load(open(p, encoding="utf-8"))
            V.check_schema(schema)
            out[kind] = V(schema)
    return out


def check_schema(doc: Any, path: str, validators: dict[str, Any]) -> list[Finding]:
    """The document satisfies the schema for its own kind."""
    if not isinstance(doc, dict):
        return [Finding("schema", path, "", f"top level is {type(doc).__name__}, expected a mapping")]
    kind = doc.get("kind")
    if kind not in validators:
        return [Finding("schema", path, "", f"kind {kind!r} has no schema — nothing validates this file")]
    out = []
    for e in sorted(validators[kind].iter_errors(doc), key=lambda e: list(e.path)):
        out.append(Finding("schema", path, "/".join(map(str, e.path)), e.message))
    return out


# -------------------------------------------------------------------------- identity


def predicate_identity(predicate: dict) -> Any:
    """A predicate's identity: its ``name`` if set, otherwise its ``aggregation``."""
    return predicate.get("name") or predicate.get("aggregation")


def check_predicate_identity(doc: Any, path: str) -> list[Finding]:
    """No two predicates of one requirement share an identity.

    Counted across ``criteria`` **and** ``guards`` together, not per section. A guard and
    a criterion that both reduce by ``rate`` collide, and a per-section check waves that
    through — which is what this repository's gate did until this function existed.

    JSON Schema cannot express it: the key is computed, and uniqueness spans two arrays.
    """
    if not isinstance(doc, dict) or doc.get("kind") != "RequirementSet":
        return []
    out = []
    for i, req in enumerate(doc.get("spec", {}).get("requirements", []) or []):
        seen: dict[Any, str] = {}
        for section in ("guards", "criteria"):
            for j, p in enumerate(req.get(section, []) or []):
                ident = predicate_identity(p)
                where = f"spec/requirements/{i}/{section}/{j}"
                if ident in seen:
                    out.append(Finding(
                        "identity", path, where,
                        f"identity {ident!r} already used at {seen[ident]} — a rendering "
                        f"could not tell these two predicates apart",
                    ))
                else:
                    seen[ident] = where
    return out


# ----------------------------------------------------------------------------- files


def check_file(path: str, validators: dict[str, Any], schema: bool = True) -> list[Finding]:
    """Every check that applies to one file, in the order a reader wants them.

    ``schema=False`` runs only the checks that bind every YAML file in the repository —
    it parses, and it maps onto JSON. The sketches under ``docs/examples/`` are checked
    that way on purpose: they illustrate constructs the format does not have, so holding
    them to the schema would make them useless. Nothing else may opt out.
    """
    out = check_parses(path)
    if out:
        return out  # nothing below can run on a file that does not parse
    out += check_jsonable(path)
    if not schema:
        return out
    yaml = _yaml()
    docs = [d for d in yaml.safe_load_all(open(path, encoding="utf-8"))]
    if not docs or all(d is None for d in docs):
        return out + [Finding("schema", path, "", "no document — a published file may not be empty")]
    for doc in docs:
        out += check_schema(doc, path, validators)
        out += check_predicate_identity(doc, path)
    return out


def expand(patterns: Iterable[str]) -> list[str]:
    files: list[str] = []
    for pat in patterns:
        files += glob.glob(pat, recursive=True)
    return sorted(set(files))


def main(argv: list[str]) -> int:
    args = argv[1:]
    schema = True
    if args and args[0] == "--no-schema":
        schema, args = False, args[1:]
    if not args:
        print(__doc__)
        return 2
    try:
        validators = load_validators() if schema else {}
    except DependencyMissing as e:
        # A gate that skips itself reads exactly like a passing one.
        print(f"  FAIL  {e}")
        return 2
    files = expand(args)
    if not files:
        print(f"  FAIL  no file matched {' '.join(args)} — nothing was checked")
        return 2
    rc = 0
    for f in files:
        try:
            findings = check_file(f, validators, schema=schema)
        except DependencyMissing as e:
            print(f"  FAIL  {e}")
            return 2
        if findings:
            rc = 1
            for finding in findings:
                print(f"  FAIL  {finding}")
        else:
            print(f"  ok    {f}")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
