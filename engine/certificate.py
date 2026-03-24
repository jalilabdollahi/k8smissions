#!/usr/bin/env python3
"""Module completion certificates — markdown save + rich terminal render (#5)."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

from rich import box
from rich.console import Console, Group
from rich.panel import Panel
from rich.rule import Rule
from rich.text import Text


def generate_certificate(player_name: str, module_name: str, module_title: str, earned_xp: int) -> str:
    """Return the certificate as markdown (for saving to disk)."""
    date = datetime.now().strftime("%B %d, %Y")
    return f"""# ★ Module Complete — {module_title}

| Field | Value |
|-------|-------|
| **Agent** | {player_name} |
| **Module** | {module_title} |
| **Date** | {date} |
| **XP Earned** | {earned_xp:,} |

> Mission Control recognizes the successful completion of `{module_name}`.
> You restored every scenario in this module and are cleared for the next one.
"""


def render_certificate_panel(
    player_name: str,
    module_title_str: str,
    module_name: str,
    earned_xp: int,
) -> Panel:
    """Return a beautiful Rich Panel for terminal display (#5)."""
    date = datetime.now().strftime("%B %d, %Y")

    star_line = Text("  ★  ★  ★  ★  ★  ★  ★  ★  ★  ★  ★  ★  ★  ★  ★", style="bold bright_yellow", justify="center")
    blank = Text("")

    header = Text("MISSION CONTROL", style="bold bright_cyan", justify="center")
    subheader = Text("CERTIFICATE OF COMPLETION", style="bold white", justify="center")
    divider = Rule(style="bright_cyan")

    body = Text.assemble(
        ("  Agent:      ", "grey70"),
        (player_name, "bold bright_magenta"),
        "\n",
        ("  Module:      ", "grey70"),
        (module_title_str, "bold bright_yellow"),
        "\n",
        ("  XP Earned:  ", "grey70"),
        (f"{earned_xp:,}", "bold bright_green"),
        "\n",
        ("  Date:       ", "grey70"),
        (date, "white"),
    )

    cleared = Text("  Cleared for next module. Carry on, Agent.", style="italic grey70")

    content = Group(
        blank,
        star_line,
        blank,
        header,
        subheader,
        blank,
        divider,
        blank,
        body,
        blank,
        divider,
        blank,
        cleared,
        blank,
        star_line,
        blank,
    )
    return Panel(
        content,
        title=f"[bold bright_green]  ★  MODULE COMPLETE  ★  [/bold bright_green]",
        border_style="bright_green",
        box=box.DOUBLE_EDGE,
        padding=(1, 2),
    )


def save_certificate(repo_root: Path, module_name: str, certificate_text: str) -> Path:
    output_dir = repo_root / "certificates"
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / f"{module_name}-certificate.md"
    output_path.write_text(certificate_text, encoding="utf-8")
    return output_path
