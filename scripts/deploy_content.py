#!/usr/bin/env python3
"""
deploy_content.py — Write hint files, reveal.md, and update mission.yaml descriptions
from the moduleN_content.json files into the corresponding level folders.

Usage:
    python3 scripts/deploy_content.py           # deploy all modules
    python3 scripts/deploy_content.py --module 5  # deploy a single module
    python3 scripts/deploy_content.py --dry-run   # preview without writing
"""

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent

MODULE_DIRS = {
    1:  "module-1-foundations",
    2:  "module-2-workloads",
    3:  "module-3-networking",
    4:  "module-4-storage",
    5:  "module-5-security",
    6:  "module-6-observability",
    7:  "module-7-gitops",
    8:  "module-8-cicd",
    9:  "module-9-scheduling",
    10: "module-10-operators",
    11: "module-11-performance",
    12: "module-12-wargames",
}


def load_levels(content_path: Path) -> dict:
    """Return a flat {level_id: {description, hint1, hint2, hint3, reveal}} dict."""
    data = json.loads(content_path.read_text())
    levels = data["levels"]
    if isinstance(levels, list):
        # Modules 1-4 use a list with an 'id' field per entry
        return {item["id"]: item for item in levels}
    # Modules 5-12 use a dict keyed by level id
    return levels


def deploy_module(module_num: int, dry_run: bool = False) -> tuple[int, int]:
    """Deploy one module's content. Returns (ok_count, error_count)."""
    content_path = REPO_ROOT / f"module{module_num}_content.json"
    if not content_path.exists():
        print(f"  [SKIP] {content_path.name} not found")
        return 0, 0

    module_dir = REPO_ROOT / "modules" / MODULE_DIRS[module_num]
    if not module_dir.exists():
        print(f"  [ERROR] module dir not found: {module_dir}")
        return 0, 1

    levels = load_levels(content_path)
    ok = err = 0

    for level_id, content in levels.items():
        level_dir = module_dir / level_id
        if not level_dir.exists():
            print(f"  [WARN]  level dir missing: {MODULE_DIRS[module_num]}/{level_id}")
            err += 1
            continue

        mission_path = level_dir / "mission.yaml"
        if not mission_path.exists():
            print(f"  [WARN]  mission.yaml missing in {level_id}")
            err += 1
            continue

        if not dry_run:
            # Write hint files (plain text, no trailing newline games)
            (level_dir / "hint-1.txt").write_text(content["hint1"])
            (level_dir / "hint-2.txt").write_text(content["hint2"])
            (level_dir / "hint-3.txt").write_text(content["hint3"])

            # Write reveal.md
            (level_dir / "reveal.md").write_text(content["reveal"])

            # Update description in mission.yaml (it's actually JSON despite the name)
            mission = json.loads(mission_path.read_text())
            mission["description"] = content["description"]
            mission_path.write_text(json.dumps(mission, indent=2, ensure_ascii=False) + "\n")

        print(f"  {'[DRY]' if dry_run else '[OK] '} {MODULE_DIRS[module_num]}/{level_id}")
        ok += 1

    return ok, err


def rebuild_registry() -> int:
    """Regenerate levels.json by scanning all mission.yaml files. Returns level count."""
    import re

    def sort_key(name: str) -> tuple[int, str]:
        m = re.search(r"(\d+)", name)
        return (int(m.group(1)) if m else 9999, name)

    modules_dir = REPO_ROOT / "modules"
    modules_out = []
    for module_dir in sorted((p for p in modules_dir.iterdir() if p.is_dir()), key=lambda p: sort_key(p.name)):
        levels_out = []
        for level_dir in sorted((p for p in module_dir.iterdir() if p.is_dir()), key=lambda p: sort_key(p.name)):
            mission_file = level_dir / "mission.yaml"
            if not mission_file.exists():
                continue
            try:
                mission = json.loads(mission_file.read_text())
            except Exception:
                mission = {}
            levels_out.append({
                "id": f"{module_dir.name}/{level_dir.name}",
                "name": level_dir.name,
                "path": f"modules/{module_dir.name}/{level_dir.name}",
                "mission": mission,
            })
        if levels_out:
            modules_out.append({"name": module_dir.name, "levels": levels_out})

    from datetime import datetime, timezone
    registry = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "level_count": sum(len(m["levels"]) for m in modules_out),
        "modules": modules_out,
    }
    (REPO_ROOT / "levels.json").write_text(json.dumps(registry, indent=2, ensure_ascii=False))
    return registry["level_count"]


def main():
    parser = argparse.ArgumentParser(description="Deploy K8sMissions content files")
    parser.add_argument("--module", type=int, choices=range(1, 13),
                        help="Deploy only this module number (1-12)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print what would be written without writing anything")
    args = parser.parse_args()

    targets = [args.module] if args.module else list(range(1, 13))
    total_ok = total_err = 0

    for num in targets:
        print(f"\nModule {num}: {MODULE_DIRS[num]}")
        ok, err = deploy_module(num, dry_run=args.dry_run)
        total_ok += ok
        total_err += err

    prefix = "DRY RUN — " if args.dry_run else ""
    print(f"\n{prefix}Done: {total_ok} levels updated, {total_err} errors/warnings")

    if not args.dry_run:
        count = rebuild_registry()
        print(f"levels.json rebuilt: {count} levels")

    sys.exit(1 if total_err else 0)


if __name__ == "__main__":
    main()
