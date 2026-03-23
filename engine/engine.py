#!/usr/bin/env python3
"""K8sMissions main game loop."""

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

import yaml
from rich.console import Console
from rich.prompt import Prompt
from rich.syntax import Syntax

try:
    from engine.certificate import generate_certificate, save_certificate
    from engine.player import prompt_player_name
    from engine.reset import prepare_level
    from engine.safety import print_safety_info, validate_kubectl_command
    from engine.ui import (
        console,
        render_markdown,
        show_guidance,
        show_help,
        show_mission_briefing,
        show_post_level_debrief,
        show_status,
        show_victory,
        show_welcome,
        show_world_completion,
        world_title,
    )
except ModuleNotFoundError:
    from certificate import generate_certificate, save_certificate
    from player import prompt_player_name
    from reset import prepare_level
    from safety import print_safety_info, validate_kubectl_command
    from ui import (
        console,
        render_markdown,
        show_guidance,
        show_help,
        show_mission_briefing,
        show_post_level_debrief,
        show_status,
        show_victory,
        show_welcome,
        show_world_completion,
        world_title,
    )

REPO_ROOT = Path(__file__).resolve().parent.parent
PROGRESS_FILE = REPO_ROOT / "progress.json"


def load_progress() -> dict:
    if not PROGRESS_FILE.exists():
        return {
            "player_name": "",
            "total_xp": 0,
            "completed_levels": [],
            "current_world": "",
            "current_level": "",
            "world_certificates": [],
        }
    return json.loads(PROGRESS_FILE.read_text(encoding="utf-8"))


def save_progress(progress: dict) -> None:
    PROGRESS_FILE.write_text(json.dumps(progress, indent=2), encoding="utf-8")


def load_worlds() -> list[dict]:
    def sort_key(path: Path) -> tuple[int, str]:
        match = re.search(r"(\d+)", path.name)
        return (int(match.group(1)) if match else 9999, path.name)

    worlds = []
    worlds_dir = REPO_ROOT / "worlds"
    for world_dir in sorted((path for path in worlds_dir.iterdir() if path.is_dir()), key=sort_key):
        levels = []
        for level_dir in sorted((path for path in world_dir.iterdir() if path.is_dir()), key=sort_key):
            mission_file = level_dir / "mission.yaml"
            if not mission_file.exists():
                continue
            mission = yaml.safe_load(mission_file.read_text(encoding="utf-8")) or {}
            levels.append(
                {
                    "id": f"{world_dir.name}/{level_dir.name}",
                    "name": level_dir.name,
                    "path": level_dir,
                    "mission": mission,
                }
            )
        if levels:
            worlds.append({"name": world_dir.name, "path": world_dir, "levels": levels})
    return worlds


def build_world_xp(worlds: list[dict], completed_levels: set[str]) -> dict[str, int]:
    totals: dict[str, int] = {}
    for world in worlds:
        world_total = 0
        for level in world["levels"]:
            if level["id"] in completed_levels:
                world_total += int(level["mission"].get("xp", 0))
        totals[world["name"]] = world_total
    return totals


def current_position(worlds: list[dict], progress: dict) -> tuple[int, int]:
    current_world = progress.get("current_world")
    current_level = progress.get("current_level")
    for world_index, world in enumerate(worlds):
        if world["name"] != current_world:
            continue
        for level_index, level in enumerate(world["levels"]):
            if level["name"] == current_level:
                return world_index, level_index
    return 0, 0


def advance(worlds: list[dict], world_index: int, level_index: int) -> tuple[int | None, int | None]:
    if level_index + 1 < len(worlds[world_index]["levels"]):
        return world_index, level_index + 1
    if world_index + 1 < len(worlds):
        return world_index + 1, 0
    return None, None


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def show_debrief(level_path: Path) -> None:
    """Show debrief + common-mistakes (paginated). Delegates to ui helper."""
    if not (level_path / "debrief.md").exists() and not (level_path / "common-mistakes.md").exists():
        console.print("[yellow]No debrief available for this level.[/yellow]")
        return
    show_post_level_debrief(level_path)


def show_guide(level_path: Path) -> None:
    guide_path = level_path / "solution-guide.md"
    if guide_path.exists():
        render_markdown("Walkthrough", guide_path.read_text(encoding="utf-8"), "bright_yellow")
        return

    solution_path = level_path / "solution.yaml"
    if not solution_path.exists():
        console.print("[yellow]No guide available for this level.[/yellow]")
        return

    syntax = Syntax(solution_path.read_text(encoding="utf-8"), "yaml", theme="ansi_dark", line_numbers=False)
    console.print(syntax)


def run_validator(level_path: Path) -> subprocess.CompletedProcess[str]:
    validator = level_path / "validate.sh"
    if not validator.exists():
        raise FileNotFoundError(f"validate.sh missing in {level_path}")
    return subprocess.run(["bash", str(validator)], cwd=level_path, capture_output=True, text=True, check=False)


def run_kubectl(raw_command: str) -> None:
    full_command = f"kubectl {raw_command}".strip()
    if not validate_kubectl_command(full_command, interactive=True):
        return
    args = shlex.split(full_command)
    result = subprocess.run(args, capture_output=True, text=True, check=False)
    if result.stdout:
        console.print(result.stdout.rstrip())
    if result.stderr:
        style = "red" if result.returncode else "yellow"
        console.print(f"[{style}]{result.stderr.rstrip()}[/{style}]")


def ensure_player_name(progress: dict) -> None:
    if progress.get("player_name"):
        return
    progress["player_name"] = prompt_player_name(progress.get("player_name", ""))
    save_progress(progress)


def ensure_current_level(progress: dict, worlds: list[dict]) -> None:
    if not worlds:
        raise RuntimeError("No implemented levels were found in worlds/")
    world_index, level_index = current_position(worlds, progress)
    progress["current_world"] = worlds[world_index]["name"]
    progress["current_level"] = worlds[world_index]["levels"][level_index]["name"]
    save_progress(progress)


def award_world_certificate(progress: dict, worlds: list[dict], world_index: int, completed_levels: set[str]) -> None:
    world = worlds[world_index]
    if world["name"] in progress.get("world_certificates", []):
        return

    world_level_ids = {level["id"] for level in world["levels"]}
    if not world_level_ids.issubset(completed_levels):
        return

    world_xp = sum(int(level["mission"].get("xp", 0)) for level in world["levels"] if level["id"] in completed_levels)
    certificate_text = generate_certificate(
        progress["player_name"],
        world["name"],
        world_title(world["name"]),
        world_xp,
    )
    save_certificate(REPO_ROOT, world["name"], certificate_text)
    progress.setdefault("world_certificates", []).append(world["name"])
    save_progress(progress)
    show_world_completion(certificate_text)


def complete_level(progress: dict, worlds: list[dict], world_index: int, level_index: int, award_xp: bool) -> bool:
    completed_levels = set(progress.get("completed_levels", []))
    level = worlds[world_index]["levels"][level_index]
    level_id = level["id"]
    xp = int(level["mission"].get("xp", 0)) if award_xp and level_id not in completed_levels else 0

    completed_levels.add(level_id)
    progress["completed_levels"] = sorted(completed_levels)
    progress["total_xp"] = int(progress.get("total_xp", 0)) + xp
    save_progress(progress)
    show_victory(worlds[world_index]["name"], level["mission"].get("name", level["name"]), xp, progress["total_xp"], skipped=not award_xp)

    # Always show the lesson after a real completion (skip auto-debrief on 'skip' command)
    if award_xp:
        show_post_level_debrief(level["path"])

    award_world_certificate(progress, worlds, world_index, completed_levels)

    next_world, next_level = advance(worlds, world_index, level_index)
    if next_world is None:
        console.print("[bold bright_green]All missions complete. Mission Control salutes you.[/bold bright_green]")
        return False

    progress["current_world"] = worlds[next_world]["name"]
    progress["current_level"] = worlds[next_world]["levels"][next_level]["name"]
    save_progress(progress)
    prepare_level(REPO_ROOT, worlds[next_world]["levels"][next_level]["path"])
    return True


_NUMBER_CMDS: dict[str, str] = {
    "1": "check",
    "2": "hint",
    "3": "guide",
    "4": "debrief",
    "6": "reset",
    "7": "status",
    "8": "skip",
    "9": "quit",
    "0": "reset-progress",
}


def game_loop() -> int:
    worlds = load_worlds()
    progress = load_progress()
    ensure_player_name(progress)
    ensure_current_level(progress, worlds)

    completed_levels = set(progress.get("completed_levels", []))
    xp_by_world = build_world_xp(worlds, completed_levels)
    show_welcome(progress["player_name"], int(progress.get("total_xp", 0)), worlds, completed_levels, xp_by_world)

    world_index, level_index = current_position(worlds, progress)
    current_level = worlds[world_index]["levels"][level_index]
    prepare_level(REPO_ROOT, current_level["path"])

    hint_index = 0
    while True:
        worlds = load_worlds()
        progress = load_progress()
        world_index, level_index = current_position(worlds, progress)
        current_level = worlds[world_index]["levels"][level_index]
        mission = current_level["mission"]
        show_mission_briefing(world_index + 1, len(worlds), level_index + 1, len(worlds[world_index]["levels"]), mission)
        show_help()

        while True:
            command = Prompt.ask("[bold bright_cyan]mission-control[/bold bright_cyan]", default="check").strip()
            if not command:
                continue

            # numeric shortcuts: "5 get pods" → "kubectl get pods"
            if command.startswith("5 "):
                run_kubectl(command[2:])
                continue
            if command == "5":
                console.print("[yellow]Usage: 5 <kubectl args>  (e.g.  5 get pods)[/yellow]")
                continue
            command = _NUMBER_CMDS.get(command, command)

            if command in {"quit", "exit"}:
                save_progress(progress)
                return 0
            if command in {"help", "?"}:
                show_help()
                continue
            if command == "status":
                completed_levels = set(progress.get("completed_levels", []))
                xp_by_world = build_world_xp(worlds, completed_levels)
                show_status(worlds, completed_levels, xp_by_world, int(progress.get("total_xp", 0)))
                continue
            if command == "debrief":
                show_debrief(current_level["path"])
                continue
            if command == "guide":
                show_guide(current_level["path"])
                continue
            if command == "hint":
                hint_index += 1
                hint_path = current_level["path"] / f"hint-{min(hint_index, 3)}.txt"
                if hint_path.exists():
                    show_guidance(f"Hint {min(hint_index, 3)}", [read_text(hint_path)])
                else:
                    console.print("[yellow]No more hints for this mission.[/yellow]")
                continue
            if command == "reset":
                prepare_level(REPO_ROOT, current_level["path"])
                hint_index = 0
                console.print("[green]Level reset complete.[/green]")
                continue
            if command == "check":
                result = run_validator(current_level["path"])
                if result.stdout:
                    console.print(result.stdout.rstrip())
                if result.stderr:
                    console.print(f"[yellow]{result.stderr.rstrip()}[/yellow]")
                if result.returncode == 0:
                    if complete_level(progress, worlds, world_index, level_index, award_xp=True):
                        hint_index = 0
                        break
                    return 0
                continue
            if command == "skip":
                if complete_level(progress, worlds, world_index, level_index, award_xp=False):
                    hint_index = 0
                    break
                return 0
            if command == "reset-progress":
                confirm = Prompt.ask(
                    "[bold bright_red]⚠️  Wipe ALL progress and start over? [y/N][/bold bright_red]",
                    default="N",
                ).strip().lower()
                if confirm == "y":
                    player = progress.get("player_name", "")
                    progress = {
                        "player_name": player,
                        "total_xp": 0,
                        "completed_levels": [],
                        "current_world": "",
                        "current_level": "",
                        "world_certificates": [],
                    }
                    save_progress(progress)
                    console.print("[bright_green]✅ Progress reset. Restarting from World 1 Level 1.[/bright_green]")
                    hint_index = 0
                    break  # restart outer loop from level 1
                else:
                    console.print("[grey70]Cancelled.[/grey70]")
                continue
            if command == "safety":
                print_safety_info()
                continue
            if command.startswith("kubectl "):
                run_kubectl(command[len("kubectl ") :])
                continue

            console.print("[yellow]Unknown command. Type 'help' for the available actions.[/yellow]")


if __name__ == "__main__":
    try:
        raise SystemExit(game_loop())
    except KeyboardInterrupt:
        save_progress(load_progress())
        sys.exit(130)
