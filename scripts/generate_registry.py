#!/usr/bin/env python3
"""Regenerate levels.json from the level folders.

Run: python3 scripts/generate_registry.py
Folders without a mission.yaml (e.g. _fixtures) are skipped.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sort_key(path: Path) -> tuple[int, str]:
    m = re.search(r"(\d+)", path.name)
    return (int(m.group(1)) if m else 9999, path.name)


def generate_registry() -> Path:
    modules_out = []
    for module_dir in sorted((p for p in (ROOT / "modules").iterdir() if p.is_dir()), key=sort_key):
        levels_out = []
        for level_dir in sorted((p for p in module_dir.iterdir() if p.is_dir()), key=sort_key):
            mission_file = level_dir / "mission.yaml"
            if not mission_file.exists():
                continue
            mission = json.loads(mission_file.read_text(encoding="utf-8"))
            levels_out.append({
                "id": f"{module_dir.name}/{level_dir.name}",
                "name": level_dir.name,
                "path": f"modules/{module_dir.name}/{level_dir.name}",
                "mission": mission,
            })
        if levels_out:
            modules_out.append({"name": module_dir.name, "levels": levels_out})
    registry = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "level_count": sum(len(m["levels"]) for m in modules_out),
        "modules": modules_out,
    }
    out = ROOT / "levels.json"
    out.write_text(json.dumps(registry, indent=2), encoding="utf-8")
    return out


if __name__ == "__main__":
    path = generate_registry()
    reg = json.loads(path.read_text())
    print(f"✅ Registry written → {path.relative_to(ROOT)}")
    print(f"   {len(reg['modules'])} modules, {reg['level_count']} levels")
