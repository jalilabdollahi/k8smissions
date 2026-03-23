#!/usr/bin/env python3
"""Safety checks for user-entered kubectl commands."""

from __future__ import annotations

import re

from rich.console import Console
from rich.panel import Panel
from rich.prompt import Confirm

console = Console()

DANGEROUS_PATTERNS = [
    (
        r"kubectl\s+delete\s+namespace\s+(kube-system|kube-public|kube-node-lease|default)",
        "BLOCKED: deleting critical namespaces is not allowed.",
        "critical",
    ),
    (
        r"kubectl\s+delete\s+node",
        "BLOCKED: deleting nodes is not allowed.",
        "critical",
    ),
    (
        r"kubectl\s+delete\s+crd",
        "BLOCKED: deleting CRDs is not allowed.",
        "critical",
    ),
    (
        r"kubectl\s+delete\s+.*\s+--all-namespaces",
        "BLOCKED: cluster-wide deletions are not allowed.",
        "critical",
    ),
    (
        r"kubectl\s+delete\s+namespace\s+k8smissions",
        "Warning: deleting the k8smissions namespace will erase the current level state.",
        "warning",
    ),
    (
        r"kubectl\s+delete\s+\w+\s+--all(\s|$)",
        "Warning: this deletes every resource of that type in the namespace.",
        "warning",
    ),
    (
        r"kubectl\s+delete\s+pv(\s|$)",
        "Warning: deleting PersistentVolumes may cause data loss.",
        "warning",
    ),
]

RISKY_PATTERNS = [
    r"kubectl\s+delete\s+namespace",
    r"kubectl\s+drain\s+",
    r"kubectl\s+cordon\s+",
]

ALLOWED_NAMESPACES = {"k8smissions", "default", "kube-system"}


def _check(command: str) -> tuple[bool, str, str]:
    lowered = command.lower().strip()
    for pattern, message, severity in DANGEROUS_PATTERNS:
        if re.search(pattern, lowered, re.IGNORECASE):
            return False, message, severity

    namespace_match = re.search(r"(?:-n|--namespace)\s+([^\s]+)", lowered)
    if namespace_match:
        namespace = namespace_match.group(1)
        if namespace not in ALLOWED_NAMESPACES:
            return False, f"Warning: this game expects namespace 'k8smissions', not '{namespace}'.", "warning"

    return True, "", "safe"


def validate_kubectl_command(command: str, interactive: bool = True) -> bool:
    is_safe, message, severity = _check(command)
    if not is_safe and severity == "critical":
        console.print(
            Panel(
                f"[bold red]{message}[/bold red]\n\n[dim]Stay inside the training environment.[/dim]",
                title="[bold red]Safety Guard[/bold red]",
                border_style="red",
            )
        )
        return False

    if not is_safe and severity == "warning" and interactive:
        console.print(
            Panel(
                f"[bold yellow]{message}[/bold yellow]\n\n[dim]Proceed only if you mean to change the current exercise state.[/dim]",
                title="[bold yellow]Caution[/bold yellow]",
                border_style="yellow",
            )
        )
        if not Confirm.ask("Run this command?", default=False):
            return False

    if interactive:
        for pattern in RISKY_PATTERNS:
            if re.search(pattern, command, re.IGNORECASE):
                if not Confirm.ask("This is a risky kubectl operation. Continue?", default=False):
                    return False
                break

    return True


def print_safety_info() -> None:
    console.print(
        Panel(
            "Blocked: deleting system namespaces, nodes, CRDs, or cluster-wide deletes.\n"
            "Warned: deleting the k8smissions namespace, --all deletes, and PV deletes.",
            title="[bold bright_cyan]K8sMissions Safety[/bold bright_cyan]",
            border_style="bright_cyan",
        )
    )
