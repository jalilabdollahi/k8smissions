#!/usr/bin/env python3
"""Rich UI helpers for the Mission Control experience."""

from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Iterable

from rich import box
from rich.columns import Columns
from rich.console import Console, Group
from rich.markdown import Markdown
from rich.panel import Panel
from rich.prompt import Prompt
from rich.rule import Rule
from rich.table import Table
from rich.text import Text

if os.name != "nt":
    import select
    import termios
    import tty
else:
    import msvcrt  # type: ignore[import]

console = Console()

WORLD_TOTAL_XP = {
    "world-1-foundations": 2050,
    "world-2-workloads": 2050,
    "world-3-networking": 2350,
    "world-4-storage": 2450,
    "world-5-security": 3150,
    "world-6-observability": 2900,
    "world-7-gitops": 4050,
    "world-8-cicd": 6200,
    "world-9-scheduling": 6200,
    "world-10-operators": 6200,
    "world-11-performance": 6200,
    "world-12-wargames": 6600,
}

WORLD_TITLES = {
    "world-1-foundations": "Foundations",
    "world-2-workloads": "Workloads",
    "world-3-networking": "Networking",
    "world-4-storage": "Storage",
    "world-5-security": "Security",
    "world-6-observability": "Observability",
    "world-7-gitops": "GitOps",
    "world-8-cicd": "CI/CD & Pipelines",
    "world-9-scheduling": "Advanced Scheduling",
    "world-10-operators": "Operators & CRDs",
    "world-11-performance": "Performance & SRE",
    "world-12-wargames": "Production War Games",
}

DIFFICULTY_STARS = {
    "beginner": "★☆☆☆☆",
    "intermediate": "★★★☆☆",
    "advanced": "★★★★☆",
    "expert": "★★★★★",
}


def world_title(world_name: str) -> str:
    return WORLD_TITLES.get(world_name, world_name.replace("-", " ").title())


def total_world_xp(world_name: str) -> int:
    return WORLD_TOTAL_XP.get(world_name, 0)


_ASCII_LOGO = """\
 ██╗  ██╗ █████╗ ███████╗    ███╗   ███╗██╗███████╗███████╗██╗ ██████╗ ███╗   ██╗███████╗
 ██║ ██╔╝██╔══██╗██╔════╝    ████╗ ████║██║██╔════╝██╔════╝██║██╔═══██╗████╗  ██║██╔════╝
 █████╔╝ ╚█████╔╝███████╗    ██╔████╔██║██║███████╗███████╗██║██║   ██║██╔██╗ ██║███████╗
 ██╔═██╗ ██╔══██╗╚════██║    ██║╚██╔╝██║██║╚════██║╚════██║██║██║   ██║██║╚██╗██║╚════██║
 ██║  ██╗╚█████╔╝███████║    ██║ ╚═╝ ██║██║███████║███████║██║╚██████╔╝██║ ╚████║███████║
 ╚═╝  ╚═╝ ╚════╝ ╚══════╝    ╚═╝     ╚═╝╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝"""


def welcome_panel(player_name: str, total_xp: int) -> Panel:
    logo = Text(_ASCII_LOGO, style="bold bright_cyan")
    subtitle = Text("  200 challenges  •  12 worlds  •  Real Kubernetes", style="grey70")
    agent = Text.assemble(
        ("  Agent: ", "grey70"),
        (player_name or "Unassigned", "bold bright_magenta"),
        ("    XP: ", "grey70"),
        (f"{total_xp:,} / 50,200", "bold bright_magenta"),
    )
    body = Group(logo, Text(""), subtitle, Text(""), agent)
    return Panel(body, border_style="bright_cyan", box=box.ROUNDED, padding=(1, 2))


def progress_rows(worlds: list[dict], completed_levels: set[str], total_xp_by_world: dict[str, int]) -> Table:
    table = Table(box=box.SIMPLE_HEAVY, expand=True)
    table.add_column("World", style="bright_cyan", ratio=2)
    table.add_column("Progress", style="white", ratio=3)
    table.add_column("XP", justify="right", style="bright_magenta")
    for world in worlds:
        level_ids = {level["id"] for level in world["levels"]}
        completed = len(level_ids & completed_levels)
        total = len(world["levels"])
        xp = total_xp_by_world.get(world["name"], 0)
        table.add_row(
            world_title(world["name"]),
            f"{completed}/{total}",
            f"{xp:,} / {total_world_xp(world['name']):,}",
        )
    return table


def show_welcome(player_name: str, total_xp: int, worlds: list[dict], completed_levels: set[str], total_xp_by_world: dict[str, int]) -> None:
    console.print(welcome_panel(player_name, total_xp))
    console.print(progress_rows(worlds, completed_levels, total_xp_by_world))


def show_mission_briefing(world_index: int, world_count: int, level_index: int, level_count: int, mission: dict) -> None:
    difficulty = mission.get("difficulty", "beginner")
    meta_line = Text.assemble(
        (f"World {world_index}/{world_count} • Level {level_index}/{level_count}", "bright_cyan"),
        ("    ", ""),
        (DIFFICULTY_STARS.get(difficulty, "★★☆☆☆"), "bright_yellow"),
        ("  ", ""),
        (difficulty.title(), "bright_yellow"),
        ("    Est: ", "grey70"),
        (mission.get("expected_time", "5m"), "white"),
    )
    content = Group(
        meta_line,
        Rule(style="grey50"),
        Text(f"NAME: {mission.get('name', 'Unknown Mission')}", style="bold white"),
        Text(""),
        Text(f"SITUATION: {mission.get('description', '')}", style="white"),
        Text(f"OBJECTIVE: {mission.get('objective', '')}", style="bright_green"),
        Text(f"XP REWARD: +{mission.get('xp', 0)} XP", style="bright_magenta"),
        Text(f"CONCEPTS: {' • '.join(mission.get('concepts', []))}", style="grey70"),
    )
    console.print(
        Panel(
            content,
            title="[bold bright_cyan]MISSION BRIEFING[/bold bright_cyan]",
            border_style="bright_cyan",
            box=box.ROUNDED,
            padding=(1, 2),
        )
    )


def show_victory(world_name: str, level_name: str, xp_earned: int, total_xp: int, skipped: bool = False) -> None:
    status = "MISSION SKIPPED" if skipped else "MISSION ACCOMPLISHED"
    color = "bright_yellow" if skipped else "bright_green"
    body = Group(
        Text(status, style=f"bold {color}"),
        Text(f"{world_title(world_name)} • {level_name}", style="white"),
        Text(f"XP Earned: +{xp_earned}  |  Total: {total_xp}", style="bright_magenta"),
    )
    console.print(Panel(body, border_style=color, box=box.DOUBLE, padding=(1, 2)))


def show_world_completion(certificate_text: str) -> None:
    console.print(Panel(Markdown(certificate_text), border_style="bright_green", box=box.DOUBLE_EDGE))


def show_status(worlds: list[dict], completed_levels: set[str], total_xp_by_world: dict[str, int], total_xp: int) -> None:
    console.print(Rule("[bright_cyan]Mission Progress[/bright_cyan]"))
    console.print(progress_rows(worlds, completed_levels, total_xp_by_world))
    console.print(Panel(Text(f"Total XP: {total_xp:,} / 19,000", style="bold bright_magenta"), border_style="bright_magenta"))


# ─────────────────────────────────────────────────────────────────────────────
# Paginated display
# ─────────────────────────────────────────────────────────────────────────────

class PaginatedDisplay:
    """Display long markdown content page-by-page (like `man` or `less`)."""

    def __init__(self, lines_per_page: int | None = None) -> None:
        self.lines_per_page = lines_per_page or self._detect_height()

    @staticmethod
    def _detect_height() -> int:
        try:
            return max(10, console.size.height - 8)
        except Exception:
            return 22

    # ── keypress ──────────────────────────────────────────────────────────────
    @staticmethod
    def _getkey() -> str:
        if os.name == "nt":
            while True:
                ch = msvcrt.getwch()  # type: ignore[name-defined]
                if ch in ("\x00", "\xe0"):
                    msvcrt.getwch()  # type: ignore[name-defined]
                    continue
                return "\n" if ch == "\r" else ch
        # Open /dev/tty directly — bypasses stdin buffering from Rich / subprocesses
        with open("/dev/tty", "rb") as tty_dev:
            fd = tty_dev.fileno()
            old = termios.tcgetattr(fd)  # type: ignore[name-defined]
            try:
                tty.setraw(fd)  # type: ignore[name-defined]
                ch = tty_dev.read(1).decode("utf-8", errors="replace")
                if ch == "\x1b" and select.select([tty_dev], [], [], 0.05)[0]:  # type: ignore[name-defined]
                    tty_dev.read(2)  # discard rest of escape sequence
                    return ""
                return "\n" if ch == "\r" else ch
            finally:
                termios.tcsetattr(fd, termios.TCSADRAIN, old)  # type: ignore[name-defined]

    # ── page boundary helpers ─────────────────────────────────────────────────
    @staticmethod
    def _code_states(lines: list[str]) -> list[bool]:
        states: list[bool] = []
        inside = False
        for line in lines:
            states.append(inside)
            if line.strip().startswith("```"):
                inside = not inside
        return states

    def _page_ranges(self, lines: list[str]) -> list[tuple[int, int]]:
        code_states = self._code_states(lines)
        ranges: list[tuple[int, int]] = []
        start = 0
        total = len(lines)
        while start < total:
            end = min(start + self.lines_per_page, total)
            # Never split inside a fenced code block
            while end < total and code_states[end - 1]:
                end += 1
            if end == start:
                end = min(start + self.lines_per_page, total)
            ranges.append((start, end))
            start = end
        return ranges or [(0, 0)]

    # ── render ────────────────────────────────────────────────────────────────
    def _render(self, content: str, title: str, border: str, page: int, total: int) -> None:
        console.print("\033[2J\033[H", end="")  # clear screen
        page_tag = f"  [Page {page}/{total}]" if total > 1 else ""
        console.print(
            Panel(
                Markdown(content),
                title=f"[bold {border}]{title}{page_tag}[/bold {border}]",
                border_style=border,
                box=box.DOUBLE,
                padding=(1, 2),
            )
        )

    def _nav_hint(self, page: int, total: int) -> None:
        parts = ["[dim]Navigate:[/dim]", "[bright_cyan]Space/Enter[/bright_cyan] → next"]
        if page > 1:
            parts.append("[bright_cyan]b[/bright_cyan] ← back")
        if total > 1:
            parts.append("[bright_cyan]g[/bright_cyan] ⏮ start")
        parts.append("[bright_cyan]q[/bright_cyan] ✕ skip")
        if page == total:
            parts.append("[dim](Enter to finish)[/dim]")
        console.print("  " + "  •  ".join(parts))

    def show(self, text: str, title: str = "Content", border: str = "bright_green") -> None:
        lines = text.split("\n")
        ranges = self._page_ranges(lines)
        total = len(ranges)

        idx = 0
        while True:
            s, e = ranges[idx]
            self._render("\n".join(lines[s:e]), title, border, idx + 1, total)
            console.print()
            self._nav_hint(idx + 1, total)
            key = self._getkey()
            if not key:
                continue
            k = key.lower()
            if k in ("\n", " ", ""):
                if idx == total - 1:
                    break
                idx = min(total - 1, idx + 1)
            elif k == "b" and idx > 0:
                idx -= 1
            elif k == "g":
                idx = 0
            elif k == "q":
                break
        console.print()


_pager = PaginatedDisplay()


# ─────────────────────────────────────────────────────────────────────────────
# Command menu
# ─────────────────────────────────────────────────────────────────────────────

def show_help() -> None:
    """Print a neatly grouped command reference panel."""

    def _section(title: str, rows: list[tuple[str, str, str]], color: str) -> Text:
        t = Text()
        t.append(f"  {title}\n", style=f"bold {color}")
        t.append(f"  {'─' * 54}\n", style="grey50")
        for num, cmd, desc in rows:
            t.append(f"  {num} ", style="grey50")
            t.append(f"{cmd:<16}", style=f"bold {color}")
            t.append(f"{desc}\n", style="white")
        return t

    diagnostic = _section(
        "DIAGNOSE",
        [
            ("1", "check",         "Run the validator — confirm your fix works"),
            ("2", "hint",          "Reveal the next hint  (up to 3)"),
            ("3", "guide",         "Show the full walkthrough / solution.yaml"),
            ("4", "debrief",       "Re-read the lesson for this level"),
        ],
        "bright_cyan",
    )

    cluster = _section(
        "CLUSTER",
        [
            ("5", "kubectl <cmd>", "Pass kubectl command through safety guards"),
            ("6", "reset",         "Rebuild the broken scenario from scratch"),
        ],
        "bright_yellow",
    )

    navigation = _section(
        "NAVIGATION",
        [
            ("7", "status",         "Show XP progress across all worlds"),
            ("8", "skip",           "Advance to next level  (no XP awarded)"),
            ("9", "quit",           "Save progress and exit"),
            ("0", "reset-progress", "Wipe all XP and start over from Level 1"),
        ],
        "grey70",
    )

    body = Text()
    body.append_text(diagnostic)
    body.append("\n")
    body.append_text(cluster)
    body.append("\n")
    body.append_text(navigation)

    console.print(
        Panel(
            body,
            title="[bold white]COMMAND REFERENCE[/bold white]",
            border_style="grey50",
            box=box.ROUNDED,
            padding=(0, 1),
        )
    )


# ─────────────────────────────────────────────────────────────────────────────
# Post-level debrief  (auto-shown on level completion)
# ─────────────────────────────────────────────────────────────────────────────

def show_post_level_debrief(level_path: Path) -> None:
    """Paginate debrief.md then common-mistakes.md after a level passes."""
    debrief = level_path / "debrief.md"
    mistakes = level_path / "common-mistakes.md"

    has_debrief = debrief.exists()
    has_mistakes = mistakes.exists()

    if not has_debrief and not has_mistakes:
        return

    console.print()
    console.print(
        Panel(
            Text.assemble(
                ("  Level Complete — reading lesson  ", "bold bright_green"),
                ("(q to skip)", "grey70"),
            ),
            border_style="bright_green",
            box=box.HEAVY_EDGE,
            padding=(0, 1),
        )
    )
    console.print()

    if has_debrief:
        _pager.show(
            debrief.read_text(encoding="utf-8"),
            title="Mission Debrief",
            border="bright_green",
        )

    if has_mistakes:
        _pager.show(
            mistakes.read_text(encoding="utf-8"),
            title="Common Mistakes",
            border="bright_yellow",
        )


# ─────────────────────────────────────────────────────────────────────────────
# Markdown helpers
# ─────────────────────────────────────────────────────────────────────────────

def render_markdown(title: str, markdown_text: str, border_style: str = "bright_cyan") -> None:
    """Paginate arbitrary markdown content."""
    _pager.show(markdown_text, title=title, border=border_style)


def show_guidance(title: str, lines: Iterable[str], style: str = "bright_yellow") -> None:
    body = Text("\n".join(lines), style="white")
    console.print(Panel(body, title=f"[bold {style}]{title}[/bold {style}]", border_style=style, box=box.ROUNDED, padding=(1, 2)))
