#!/usr/bin/env python3
"""Reset helpers for rebuilding level state."""

from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

from rich.console import Console

console = Console()

NAMESPACE = "k8smissions"


def _run(args: list[str], cwd: Path | None = None, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=check)


def _run_best_effort(args: list[str], cwd: Path | None = None) -> None:
    subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=False)


def _wait_for_namespace_deletion(name: str, timeout: int = 45) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        result = subprocess.run(
            ["kubectl", "get", "namespace", name],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            return
        time.sleep(1)
    raise RuntimeError(f"Timed out waiting for namespace '{name}' to delete")


def _cleanup_manifest(level_path: Path, manifest_name: str) -> None:
    manifest = level_path / manifest_name
    if manifest.exists():
        _run_best_effort(["kubectl", "delete", "-f", str(manifest), "--ignore-not-found=true"], cwd=level_path)


def prepare_level(repo_root: Path, level_path: Path) -> None:
    """Clean the environment, recreate the namespace, and apply the broken state."""
    for manifest_name in ("solution.yaml", "broken.yaml", "setup.yaml"):
        _cleanup_manifest(level_path, manifest_name)

    _run_best_effort(["kubectl", "delete", "namespace", NAMESPACE, "--ignore-not-found=true"])
    _wait_for_namespace_deletion(NAMESPACE)

    _run(["kubectl", "create", "namespace", NAMESPACE], check=False)

    rbac_manifest = repo_root / "rbac" / "k8smissions-rbac.yaml"
    if rbac_manifest.exists():
        _run_best_effort(["kubectl", "apply", "-f", str(rbac_manifest)])

    setup_yaml = level_path / "setup.yaml"
    if setup_yaml.exists():
        _run(["kubectl", "apply", "-f", str(setup_yaml)], cwd=level_path)

    setup_script = level_path / "setup.sh"
    if setup_script.exists():
        _run(["bash", str(setup_script)], cwd=level_path)

    broken_yaml = level_path / "broken.yaml"
    if broken_yaml.exists():
        _run(["kubectl", "apply", "-f", str(broken_yaml)], cwd=level_path)


def reset_current_level(repo_root: Path, level_path: Path) -> bool:
    try:
        prepare_level(repo_root, level_path)
    except Exception as exc:  # pragma: no cover - CLI path
        console.print(f"[red]Reset failed:[/red] {exc}")
        return False
    return True


def main() -> int:
    if len(sys.argv) != 2:
        console.print("Usage: python3 engine/reset.py <absolute-level-path>")
        return 1
    repo_root = Path(__file__).resolve().parent.parent
    level_path = Path(sys.argv[1]).resolve()
    return 0 if reset_current_level(repo_root, level_path) else 1


if __name__ == "__main__":
    raise SystemExit(main())
