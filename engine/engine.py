#!/usr/bin/env python3
"""K8sMissions main game loop."""

from __future__ import annotations

import json
import os
import re
import readline  # noqa: F401 — enables arrow keys and history in Prompt.ask()
import shlex
import subprocess
import sys
import time
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
        show_module_completion,
        module_title,
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
        show_module_completion,
        module_title,
    )

REPO_ROOT = Path(__file__).resolve().parent.parent
PROGRESS_FILE = REPO_ROOT / "progress.json"
LEVELS_REGISTRY = REPO_ROOT / "levels.json"


# ─────────────────────────────────────────────────────────────────────────────
# Cluster health check (#3)
# ─────────────────────────────────────────────────────────────────────────────

def check_cluster_health() -> bool:
    """Return True if a kubectl-reachable cluster is available."""
    # Try the specific kind context first, then fall back to current context
    for args in [
        ["kubectl", "cluster-info", "--context", "kind-k8smissions"],
        ["kubectl", "cluster-info"],
    ]:
        result = subprocess.run(args, capture_output=True, text=True, check=False, timeout=10)
        if result.returncode == 0:
            return True
    return False


def load_progress() -> dict:
    if not PROGRESS_FILE.exists():
        return {
            "player_name": "",
            "total_xp": 0,
            "completed_levels": [],
            "current_module": "",
            "current_level": "",
            "module_certificates": [],
            "time_per_level": {},
            "level_start_time": None,
        }
    data = json.loads(PROGRESS_FILE.read_text(encoding="utf-8"))
    # Backfill time fields for existing progress files
    data.setdefault("time_per_level", {})
    data.setdefault("level_start_time", None)
    return data


def save_progress(progress: dict) -> None:
    PROGRESS_FILE.write_text(json.dumps(progress, indent=2), encoding="utf-8")


def load_modules() -> list[dict]:
    def sort_key(path: Path) -> tuple[int, str]:
        match = re.search(r"(\d+)", path.name)
        return (int(match.group(1)) if match else 9999, path.name)

    # Fast path: load from pre-built registry if available
    if LEVELS_REGISTRY.exists():
        try:
            registry = json.loads(LEVELS_REGISTRY.read_text(encoding="utf-8"))
            modules = []
            for w in registry.get("modules", []):
                levels = []
                for lv in w.get("levels", []):
                    level_path = REPO_ROOT / lv["path"]
                    if level_path.exists():
                        levels.append({
                            "id": lv["id"],
                            "name": lv["name"],
                            "path": level_path,
                            "mission": lv["mission"],
                        })
                if levels:
                    modules.append({"name": w["name"], "path": REPO_ROOT / "modules" / w["name"], "levels": levels})
            if modules:
                return modules
        except Exception:
            pass  # fall through to directory scan

    # Fallback: scan directories
    modules = []
    modules_dir = REPO_ROOT / "modules"
    for module_dir in sorted((path for path in modules_dir.iterdir() if path.is_dir()), key=sort_key):
        levels = []
        for level_dir in sorted((path for path in module_dir.iterdir() if path.is_dir()), key=sort_key):
            mission_file = level_dir / "mission.yaml"
            if not mission_file.exists():
                continue
            mission = yaml.safe_load(mission_file.read_text(encoding="utf-8")) or {}
            levels.append(
                {
                    "id": f"{module_dir.name}/{level_dir.name}",
                    "name": level_dir.name,
                    "path": level_dir,
                    "mission": mission,
                }
            )
        if levels:
            modules.append({"name": module_dir.name, "path": module_dir, "levels": levels})
    return modules


def compute_max_xp_by_module(modules: list[dict]) -> dict[str, int]:
    """Dynamically compute total possible XP per module from mission files (#11)."""
    return {
        module["name"]: sum(int(level["mission"].get("xp", 0)) for level in module["levels"])
        for module in modules
    }


def build_module_xp(modules: list[dict], completed_levels: set[str]) -> dict[str, int]:
    totals: dict[str, int] = {}
    for module in modules:
        module_total = 0
        for level in module["levels"]:
            if level["id"] in completed_levels:
                module_total += int(level["mission"].get("xp", 0))
        totals[module["name"]] = module_total
    return totals


def current_position(modules: list[dict], progress: dict) -> tuple[int, int]:
    current_module = progress.get("current_module")
    current_level = progress.get("current_level")
    for module_index, module in enumerate(modules):
        if module["name"] != current_module:
            continue
        for level_index, level in enumerate(module["levels"]):
            if level["name"] == current_level:
                return module_index, level_index
    return 0, 0


def advance(modules: list[dict], module_index: int, level_index: int) -> tuple[int | None, int | None]:
    if level_index + 1 < len(modules[module_index]["levels"]):
        return module_index, level_index + 1
    if module_index + 1 < len(modules):
        return module_index + 1, 0
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


def _find_editor() -> str:
    """Return the first usable terminal editor found on PATH."""
    for editor in ("nano", "vim", "vi"):
        if subprocess.run(["which", editor], capture_output=True, check=False).returncode == 0:
            return editor
    return "vi"


def run_edit_resource(resource_spec: str) -> None:
    """Dump a resource to a temp YAML file, open in $EDITOR, then kubectl apply."""
    import tempfile

    parts = resource_spec.strip().split()
    if not parts:
        console.print("[yellow]Usage: edit <type> <name> [-n namespace]  (e.g.  edit pod nginx-broken -n k8smissions)[/yellow]")
        return

    # Extract -n / --namespace if provided, otherwise default to k8smissions
    namespace = "k8smissions"
    filtered = []
    i = 0
    while i < len(parts):
        if parts[i] in ("-n", "--namespace") and i + 1 < len(parts):
            namespace = parts[i + 1]
            i += 2
        elif parts[i].startswith("--namespace="):
            namespace = parts[i].split("=", 1)[1]
            i += 1
        else:
            filtered.append(parts[i])
            i += 1
    parts = filtered

    # Fetch current live YAML
    get_args = ["kubectl", "get"] + parts + ["-n", namespace, "-o", "yaml"]
    result = subprocess.run(get_args, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        console.print(f"[red]{result.stderr.rstrip()}[/red]")
        return

    # Strip server-managed read-only fields so the file is cleanly editable
    try:
        doc = yaml.safe_load(result.stdout) or {}
        doc.pop("status", None)
        meta = doc.get("metadata", {})
        for field in ("resourceVersion", "uid", "creationTimestamp", "generation", "managedFields"):
            meta.pop(field, None)
        annotations = meta.get("annotations", {})
        annotations.pop("kubectl.kubernetes.io/last-applied-configuration", None)
        if not annotations:
            meta.pop("annotations", None)
        clean = yaml.dump(doc, default_flow_style=False, allow_unicode=True)
    except Exception:
        clean = result.stdout

    # Write to temp file
    with tempfile.NamedTemporaryFile(
        suffix=".yaml", prefix="k8smissions-", mode="w",
        delete=False, encoding="utf-8",
    ) as tmp:
        tmp.write(clean)
        tmp_path = tmp.name

    console.print(f"[grey70]Resource written to [bold]{tmp_path}[/bold] — opening editor...[/grey70]")

    editor = os.environ.get("EDITOR") or os.environ.get("VISUAL") or _find_editor()
    start = time.time()
    subprocess.run(shlex.split(editor) + [tmp_path], check=False)
    elapsed = time.time() - start

    # If editor returned almost instantly it's likely a GUI app; wait for user
    if elapsed < 2.0:
        console.print(
            f"[yellow]If you opened a GUI editor, finish editing [bold]{tmp_path}[/bold] "
            "then press Enter to continue.[/yellow]"
        )
        try:
            input()
        except EOFError:
            pass

    from rich.prompt import Confirm
    if not Confirm.ask("[bold bright_cyan]Apply edited manifest?[/bold bright_cyan]", default=True):
        console.print(f"[grey70]Cancelled. Temp file at {tmp_path}[/grey70]")
        return

    apply = subprocess.run(
        ["kubectl", "apply", "-f", tmp_path],
        capture_output=True, text=True, check=False,
    )
    if apply.stdout:
        console.print(apply.stdout.rstrip())

    # Pods are mostly immutable — kubectl apply will fail when changing env vars,
    # volumes, etc.  Offer to delete-and-recreate via kubectl replace --force.
    if apply.returncode != 0 and "may not change fields" in apply.stderr:
        console.print(
            "[yellow]Pods are immutable after creation — the changed fields require "
            "the pod to be deleted and recreated.[/yellow]"
        )
        if Confirm.ask(
            "[bold bright_cyan]Delete and recreate the pod with your changes?[/bold bright_cyan]",
            default=True,
        ):
            replace = subprocess.run(
                ["kubectl", "replace", "--force", "-f", tmp_path],
                capture_output=True, text=True, check=False,
            )
            if replace.stdout:
                console.print(replace.stdout.rstrip())
            if replace.stderr:
                style = "red" if replace.returncode else "yellow"
                console.print(f"[{style}]{replace.stderr.rstrip()}[/{style}]")
            if replace.returncode == 0:
                console.print("[bright_green]✅ Pod recreated with your changes.[/bright_green]")
            else:
                console.print(f"[grey70]Temp file kept at {tmp_path}[/grey70]")
        return

    if apply.returncode == 0:
        console.print("[bright_green]✅ Changes applied.[/bright_green]")
    else:
        if apply.stderr:
            style = "red"
            console.print(f"[{style}]{apply.stderr.rstrip()}[/{style}]")
        console.print(f"[grey70]Temp file kept at {tmp_path}[/grey70]")


def ensure_player_name(progress: dict) -> None:
    if progress.get("player_name"):
        return
    progress["player_name"] = prompt_player_name(progress.get("player_name", ""))
    save_progress(progress)


def ensure_current_level(progress: dict, modules: list[dict]) -> None:
    if not modules:
        raise RuntimeError("No implemented levels were found in modules/")
    module_index, level_index = current_position(modules, progress)
    progress["current_module"] = modules[module_index]["name"]
    progress["current_level"] = modules[module_index]["levels"][level_index]["name"]
    save_progress(progress)


def award_module_certificate(progress: dict, modules: list[dict], module_index: int, completed_levels: set[str]) -> None:
    module = modules[module_index]
    if module["name"] in progress.get("module_certificates", []):
        return

    module_level_ids = {level["id"] for level in module["levels"]}
    if not module_level_ids.issubset(completed_levels):
        return

    module_xp = sum(int(level["mission"].get("xp", 0)) for level in module["levels"] if level["id"] in completed_levels)
    w_title = module_title(module["name"])
    # Save markdown certificate to disk
    certificate_text = generate_certificate(progress["player_name"], module["name"], w_title, module_xp)
    save_certificate(REPO_ROOT, module["name"], certificate_text)
    # Show rich panel in terminal (#5)
    try:
        from engine.certificate import render_certificate_panel
    except ModuleNotFoundError:
        from certificate import render_certificate_panel
    panel = render_certificate_panel(progress["player_name"], w_title, module["name"], module_xp)
    progress.setdefault("module_certificates", []).append(module["name"])
    save_progress(progress)
    show_module_completion(panel)


def complete_level(progress: dict, modules: list[dict], module_index: int, level_index: int, award_xp: bool) -> bool:
    completed_levels = set(progress.get("completed_levels", []))
    level = modules[module_index]["levels"][level_index]
    level_id = level["id"]
    xp = int(level["mission"].get("xp", 0)) if award_xp and level_id not in completed_levels else 0

    # Time tracking (#6): compute elapsed seconds for this level
    elapsed_seconds: int | None = None
    start_ts = progress.get("level_start_time")
    if start_ts is not None:
        elapsed_seconds = max(0, int(time.time() - start_ts))
        progress.setdefault("time_per_level", {})[level_id] = elapsed_seconds
    progress["level_start_time"] = None  # clear start time

    completed_levels.add(level_id)
    progress["completed_levels"] = sorted(completed_levels)
    progress["total_xp"] = int(progress.get("total_xp", 0)) + xp
    save_progress(progress)
    show_victory(
        modules[module_index]["name"],
        level["mission"].get("name", level["name"]),
        xp,
        progress["total_xp"],
        skipped=not award_xp,
        elapsed_seconds=elapsed_seconds,
        expected_time=level["mission"].get("expected_time"),
    )

    # Always show the lesson after a real completion (skip auto-debrief on 'skip' command)
    if award_xp:
        show_post_level_debrief(
            level["path"],
            elapsed_seconds=elapsed_seconds,
            expected_time=level["mission"].get("expected_time"),
        )

    award_module_certificate(progress, modules, module_index, completed_levels)

    next_module, next_level = advance(modules, module_index, level_index)
    if next_module is None:
        console.print("[bold bright_green]All missions complete. Mission Control salutes you.[/bold bright_green]")
        return False

    progress["current_module"] = modules[next_module]["name"]
    progress["current_level"] = modules[next_module]["levels"][next_level]["name"]
    save_progress(progress)
    prepare_level(REPO_ROOT, modules[next_module]["levels"][next_level]["path"])
    return True


_NUMBER_CMDS: dict[str, str] = {
    "1": "check",
    "d": "check-dry",
    "w": "watch",
    "2": "hint",
    "3": "guide",
    "4": "debrief",
    "6": "reset",
    "7": "status",
    "8": "skip",
    "9": "quit",
    "0": "reset-progress",
}


def watch_mode(level_path: Path) -> bool:
    """Auto-run validator every 5 seconds until it passes (#7). Returns True if passed."""
    from rich.panel import Panel
    from rich.text import Text
    interval = 5
    console.print(Panel(
        Text.assemble(
            ("Watch mode active — ", "bright_cyan"),
            ("validator runs every 5s", "white"),
            ("  •  ", "grey50"),
            ("Ctrl+C to cancel", "grey70"),
        ),
        border_style="bright_cyan", padding=(0, 1)
    ))
    attempt = 0
    try:
        while True:
            attempt += 1
            result = run_validator(level_path)
            if result.stdout:
                console.print(result.stdout.rstrip())
            if result.returncode == 0:
                console.print(f"[bold bright_green]✅ Passed on attempt {attempt}[/bold bright_green]")
                return True
            # Countdown
            for remaining in range(interval, 0, -1):
                console.print(f"\r[grey70]  ↺ Attempt {attempt} failed — rechecking in {remaining}s... [/grey70]", end="")
                time.sleep(1)
            console.print()
    except KeyboardInterrupt:
        console.print("\n[yellow]Watch mode cancelled.[/yellow]")
        return False


def game_loop() -> int:
    # Cluster health check (#3)
    from rich.panel import Panel as _Panel
    from rich.text import Text as _Text
    console.print("[grey70]Checking cluster health...[/grey70]", end="\r")
    if not check_cluster_health():
        console.print(_Panel(
            _Text.assemble(
                ("Kubernetes cluster not reachable.\n\n", "bold red"),
                ("Start the cluster with:\n", "white"),
                ("  kind create cluster --name k8smissions\n", "bright_cyan"),
                ("Then run ./install.sh to configure it.", "grey70"),
            ),
            title="[bold red]Cluster Offline[/bold red]",
            border_style="red",
        ))
        return 1
    console.print(" " * 50, end="\r")  # clear the checking message

    modules = load_modules()
    progress = load_progress()
    ensure_player_name(progress)
    ensure_current_level(progress, modules)

    completed_levels = set(progress.get("completed_levels", []))
    xp_by_module = build_module_xp(modules, completed_levels)
    max_xp_by_module = compute_max_xp_by_module(modules)
    max_total_xp = sum(max_xp_by_module.values())
    show_welcome(progress["player_name"], int(progress.get("total_xp", 0)), modules, completed_levels, xp_by_module, max_xp_by_module, max_total_xp)

    module_index, level_index = current_position(modules, progress)
    current_level = modules[module_index]["levels"][level_index]
    prepare_level(REPO_ROOT, current_level["path"])

    # Record level start time (#6)
    if not progress.get("level_start_time"):
        progress["level_start_time"] = time.time()
        save_progress(progress)

    hint_index = 0
    while True:
        modules = load_modules()
        progress = load_progress()
        module_index, level_index = current_position(modules, progress)
        current_level = modules[module_index]["levels"][level_index]
        mission = current_level["mission"]
        show_mission_briefing(module_index + 1, len(modules), level_index + 1, len(modules[module_index]["levels"]), mission)
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
                xp_by_module = build_module_xp(modules, completed_levels)
                max_xp_by_module = compute_max_xp_by_module(modules)
                max_total_xp = sum(max_xp_by_module.values())
                show_status(modules, completed_levels, xp_by_module, int(progress.get("total_xp", 0)), max_xp_by_module, max_total_xp)
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
                # Reset start time on scenario reset (#6)
                progress["level_start_time"] = time.time()
                save_progress(progress)
                console.print("[green]Level reset complete.[/green]")
                continue
            if command == "check":
                result = run_validator(current_level["path"])
                if result.stdout:
                    console.print(result.stdout.rstrip())
                if result.stderr:
                    console.print(f"[yellow]{result.stderr.rstrip()}[/yellow]")
                if result.returncode == 0:
                    if complete_level(progress, modules, module_index, level_index, award_xp=True):
                        progress = load_progress()
                        progress["level_start_time"] = time.time()
                        save_progress(progress)
                        hint_index = 0
                        break
                    return 0
                continue
            if command == "check-dry":
                # Dry-run validator — shows output without awarding XP (#4)
                result = run_validator(current_level["path"])
                console.print("[bold grey70]── Dry Run (no XP awarded) ──[/bold grey70]")
                if result.stdout:
                    console.print(result.stdout.rstrip())
                if result.stderr:
                    console.print(f"[yellow]{result.stderr.rstrip()}[/yellow]")
                verdict = "[bright_green]WOULD PASS[/bright_green]" if result.returncode == 0 else "[red]WOULD FAIL[/red]"
                console.print(f"[grey70]Exit code {result.returncode} → {verdict}[/grey70]")
                continue
            if command == "watch":
                # Watch mode — auto-runs validator every 5s (#7)
                passed = watch_mode(current_level["path"])
                if passed:
                    if complete_level(progress, modules, module_index, level_index, award_xp=True):
                        progress = load_progress()
                        progress["level_start_time"] = time.time()
                        save_progress(progress)
                        hint_index = 0
                        break
                    return 0
                continue
            if command == "skip":
                if complete_level(progress, modules, module_index, level_index, award_xp=False):
                    progress = load_progress()
                    progress["level_start_time"] = time.time()
                    save_progress(progress)
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
                        "current_module": "",
                        "current_level": "",
                        "module_certificates": [],
                        "time_per_level": {},
                        "level_start_time": time.time(),
                    }
                    save_progress(progress)
                    console.print("[bright_green]✅ Progress reset. Restarting from Module 1 Level 1.[/bright_green]")
                    hint_index = 0
                    break  # restart outer loop from level 1
                else:
                    console.print("[grey70]Cancelled.[/grey70]")
                continue
            if command == "safety":
                print_safety_info()
                continue
            if command.startswith("kubectl "):
                run_kubectl(command[len("kubectl "):])
                continue
            if command == "edit":
                console.print("[yellow]Usage: edit <type> <name>  (e.g.  edit pod nginx-broken)[/yellow]")
                continue
            if command.startswith("edit "):
                run_edit_resource(command[5:])
                continue
            # shortcut: "e pod nginx-broken" → edit
            if command.startswith("e "):
                run_edit_resource(command[2:])
                continue
            if command == "e":
                console.print("[yellow]Usage: e <type> <name>  (e.g.  e pod nginx-broken)[/yellow]")
                continue

            # Helpful catch for bare kubectl subcommands like "get po -A"
            _KUBECTL_VERBS = {"get", "describe", "logs", "exec", "apply", "delete",
                              "edit", "patch", "scale", "rollout", "set", "label",
                              "annotate", "top", "drain", "cordon", "uncordon",
                              "port-forward", "proxy", "cp", "auth", "config"}
            first_word = command.split()[0] if command.split() else ""
            if first_word in _KUBECTL_VERBS:
                console.print(
                    f"[yellow]Tip: prefix kubectl commands with [bold]kubectl[/bold] or use [bold]5[/bold].\n"
                    f"  e.g.  [bright_cyan]kubectl {command}[/bright_cyan]  or  [bright_cyan]5 {command}[/bright_cyan][/yellow]"
                )
                continue

            console.print("[yellow]Unknown command. Type 'help' for the available actions.[/yellow]")


if __name__ == "__main__":
    try:
        raise SystemExit(game_loop())
    except KeyboardInterrupt:
        save_progress(load_progress())
        sys.exit(130)
