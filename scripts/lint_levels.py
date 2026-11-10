#!/usr/bin/env python3
"""Static checks for levels (no cluster needed). See docs/LEVEL_AUTHORING.md.

Usage: scripts/lint_levels.py [filters...]     exit 1 if anything is flagged
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO))
from engine.addons import ADDONS  # noqa: E402

FILES = ["mission.yaml", "validate.sh", "solution.sh", "hint-1.txt", "hint-2.txt", "hint-3.txt",
         "reveal.md", "debrief.md", "common-mistakes.md"]
FIELDS = ["name", "description", "objective", "xp", "difficulty", "expected_time", "concepts", "module", "level"]
XP = {"beginner": 100, "intermediate": 150, "advanced": 200, "expert": 300}
IMAGE = re.compile(r"^\s*-?\s*image:\s*['\"]?([^\s'\"#]+)", re.M)


def lint(level: Path) -> list[str]:
    p: list[str] = []
    for f in FILES:
        if not (level / f).exists():
            p.append(f"missing {f}")
    if not (level / "broken.yaml").exists() and not (level / "setup.sh").exists():
        p.append("needs broken.yaml or setup.sh")
    try:
        m = json.loads((level / "mission.yaml").read_text())
    except Exception as e:
        return p + [f"mission.yaml is not valid JSON: {e}"]
    p += [f"mission.yaml missing '{k}'" for k in FIELDS if k not in m]
    if m.get("level") != level.name or m.get("module") != level.parent.name:
        p.append("mission.yaml module/level do not match the folder")
    if m.get("difficulty") in XP and m.get("xp") != XP[m["difficulty"]]:
        p.append(f"xp should be {XP[m['difficulty']]} for {m['difficulty']}")
    for a in m.get("requires", []):
        if a not in ADDONS:
            p.append(f"unknown add-on in requires: {a}")

    for f in ("broken.yaml", "setup.yaml"):
        if (level / f).exists():
            try:
                list(yaml.safe_load_all((level / f).read_text()))
            except Exception as e:
                p.append(f"{f} is not valid YAML: {str(e).splitlines()[0]}")

    v = (level / "validate.sh").read_text() if (level / "validate.sh").exists() else ""
    code = "\n".join(l for l in v.splitlines() if not l.strip().startswith("#"))
    if re.search(r"\|\|\s*echo[^\n]*;\s*then", code) or re.search(r"^\s*if\b[^\n]*\|\|\s*(echo|true)\b[^\n]*then", code, re.M):
        p.append("validate.sh: '|| echo/true' inside an if condition makes it always true")
    lines = [l.strip() for l in code.splitlines() if l.strip()]
    if lines and lines[-1] != "exit 1":
        p.append("validate.sh must end with 'exit 1' (fail closed); pass only through an explicit check")
    if "kubectl" not in code:
        p.append("validate.sh does not query the cluster")

    for f in ("broken.yaml", "setup.yaml", "setup.sh", "solution.sh"):
        if not (level / f).exists():
            continue
        for line in (level / f).read_text().splitlines():
            mm = IMAGE.search(line) or re.search(r"--image[= ]['\"]?([^\s'\"]+)", line)
            if not mm or "lint: allow-image" in line:
                continue
            img = mm.group(1)
            name = img.split("/")[-1]
            if "$" in img:
                continue
            if ":" not in name and "@" not in name:
                p.append(f"{f}: image without a tag: {img}")
            elif name.endswith(":latest"):
                p.append(f"{f}: image uses :latest: {img}")

    obj = m.get("objective", "")
    if re.search(r"—\s*(fix|change|set|add|increase|reduce|remove|recreate|update|patch|scale)\b", obj, re.I):
        p.append("objective tells the fix ('X is wrong — do Y'); state the goal, not the action")
    return p


def main() -> int:
    filters = sys.argv[1:]
    levels = sorted(x.parent for x in (REPO / "modules").glob("*/*/mission.yaml"))
    if filters:
        levels = [l for l in levels if any(f in f"{l.parent.name}/{l.name}" for f in filters)]
    bad = 0
    for level in levels:
        problems = lint(level)
        if problems:
            bad += 1
            print(f"{level.parent.name}/{level.name}")
            for x in problems:
                print(f"   - {x}")
    print(f"\n{len(levels) - bad}/{len(levels)} levels clean")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
