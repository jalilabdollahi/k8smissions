#!/usr/bin/env python3
"""Backfill missing common-mistakes docs for existing levels."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from common_mistakes_templates import render_common_mistakes

ROOT = Path(__file__).resolve().parents[1]
WORLDS = ROOT / "worlds"


def extract_validate(debrief_text: str) -> str:
    match = re.search(
        r"## What To Validate\s+(.*?)(?:\n## |\Z)",
        debrief_text,
        re.DOTALL,
    )
    if not match:
        return "Run the validator after the fix."
    return " ".join(line.strip() for line in match.group(1).strip().splitlines() if line.strip())


def level_payload(level_dir: Path) -> dict:
    mission = json.loads((level_dir / "mission.yaml").read_text(encoding="utf-8"))
    debrief = (level_dir / "debrief.md").read_text(encoding="utf-8")
    return {
        "world": level_dir.parent.name,
        "dir_name": level_dir.name,
        "name": mission.get("name", level_dir.name),
        "description": mission.get("description", ""),
        "fix": mission.get("objective", ""),
        "validate": extract_validate(debrief),
        "concepts": mission.get("concepts", []),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="regenerate files even if common-mistakes.md already exists",
    )
    args = parser.parse_args()

    created = 0
    for level_dir in sorted(WORLDS.glob("world-*/level-*")):
        target = level_dir / "common-mistakes.md"
        if target.exists() and not args.overwrite:
            continue
        target.write_text(render_common_mistakes(level_payload(level_dir)), encoding="utf-8")
        created += 1
        print(f"created {target.relative_to(ROOT)}")
    print(f"\nCreated {created} missing common-mistakes.md files.")


if __name__ == "__main__":
    main()
