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

MODULE_TOTAL_XP = {
    "module-1-foundations": 3025,
    "module-2-workloads": 2950,
    "module-3-networking": 3275,
    "module-4-storage": 3375,
    "module-5-security": 4300,
    "module-6-observability": 3800,
    "module-7-gitops": 5100,
    "module-8-cicd": 5425,
    "module-9-scheduling": 5775,
    "module-10-operators": 6225,
    "module-11-performance": 6075,
    "module-12-wargames": 6600,
}

MODULE_TITLES = {
    "module-1-foundations": "Foundations",
    "module-2-workloads": "Workloads",
    "module-3-networking": "Networking",
    "module-4-storage": "Storage",
    "module-5-security": "Security",
    "module-6-observability": "Observability",
    "module-7-gitops": "GitOps",
    "module-8-cicd": "CI/CD & Pipelines",
    "module-9-scheduling": "Advanced Scheduling",
    "module-10-operators": "Operators & CRDs",
    "module-11-performance": "Performance & SRE",
    "module-12-wargames": "Production War Games",
}

DIFFICULTY_STARS = {
    "beginner": "★☆☆☆☆",
    "intermediate": "★★★☆☆",
    "advanced": "★★★★☆",
    "expert": "★★★★★",
}


def module_title(module_name: str) -> str:
    return MODULE_TITLES.get(module_name, module_name.replace("-", " ").title())


def total_module_xp(module_name: str) -> int:
    return MODULE_TOTAL_XP.get(module_name, 0)


_ASCII_LOGO = """\
 ██╗  ██╗ █████╗ ███████╗    ███╗   ███╗██╗███████╗███████╗██╗ ██████╗ ███╗   ██╗███████╗
 ██║ ██╔╝██╔══██╗██╔════╝    ████╗ ████║██║██╔════╝██╔════╝██║██╔═══██╗████╗  ██║██╔════╝
 █████╔╝ ╚█████╔╝███████╗    ██╔████╔██║██║███████╗███████╗██║██║   ██║██╔██╗ ██║███████╗
 ██╔═██╗ ██╔══██╗╚════██║    ██║╚██╔╝██║██║╚════██║╚════██║██║██║   ██║██║╚██╗██║╚════██║
 ██║  ██╗╚█████╔╝███████║    ██║ ╚═╝ ██║██║███████║███████║██║╚██████╔╝██║ ╚████║███████║
 ╚═╝  ╚═╝ ╚════╝ ╚══════╝    ╚═╝     ╚═╝╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝"""


def welcome_panel(player_name: str, total_xp: int, max_total_xp: int | None = None) -> Panel:
    logo = Text(_ASCII_LOGO, style="bold bright_cyan")
    subtitle = Text("  200 challenges  •  12 modules  •  Real Kubernetes", style="grey70")
    attribution = Text("  Design and implementation by: Jalil Abdollahi", style="bold white")
    contact = Text("  jalil.abdollahi@gmail.com", style="bright_magenta")
    agent = Text.assemble(
        ("  Agent: ", "grey70"),
        (player_name or "Unassigned", "bold bright_magenta"),
        ("    XP: ", "grey70"),
        (f"{total_xp:,} / {(max_total_xp or 55925):,}", "bold bright_magenta"),
    )
    body = Group(logo, Text(""), attribution, contact, Text(""), subtitle, Text(""), agent)
    return Panel(body, border_style="bright_cyan", box=box.ROUNDED, padding=(1, 2))


def progress_rows(
    modules: list[dict],
    completed_levels: set[str],
    total_xp_by_module: dict[str, int],
    max_xp_by_module: dict[str, int] | None = None,
) -> Table:
    table = Table(box=box.SIMPLE_HEAVY, expand=True)
    table.add_column("Module", style="bright_cyan", ratio=2)
    table.add_column("Progress", style="white", ratio=3)
    table.add_column("XP", justify="right", style="bright_magenta")
    for module in modules:
        level_ids = {level["id"] for level in module["levels"]}
        completed = len(level_ids & completed_levels)
        total = len(module["levels"])
        xp = total_xp_by_module.get(module["name"], 0)
        # Use dynamic max XP if provided, fall back to hardcoded dict (#11)
        if max_xp_by_module is not None:
            max_xp = max_xp_by_module.get(module["name"], total_module_xp(module["name"]))
        else:
            max_xp = total_module_xp(module["name"])
        table.add_row(
            module_title(module["name"]),
            f"{completed}/{total}",
            f"{xp:,} / {max_xp:,}",
        )
    return table


def show_welcome(
    player_name: str,
    total_xp: int,
    modules: list[dict],
    completed_levels: set[str],
    total_xp_by_module: dict[str, int],
    max_xp_by_module: dict[str, int] | None = None,
    max_total_xp: int | None = None,
) -> None:
    effective_max = max_total_xp or sum(MODULE_TOTAL_XP.values())
    console.print(welcome_panel(player_name, total_xp, effective_max))
    console.print(progress_rows(modules, completed_levels, total_xp_by_module, max_xp_by_module))


def show_mission_briefing(module_index: int, module_count: int, level_index: int, level_count: int, mission: dict) -> None:
    difficulty = mission.get("difficulty", "beginner")
    meta_line = Text.assemble(
        (f"Module {module_index}/{module_count} • Level {level_index}/{level_count}", "bright_cyan"),
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


def show_victory(
    module_name: str,
    level_name: str,
    xp_earned: int,
    total_xp: int,
    skipped: bool = False,
    elapsed_seconds: int | None = None,
    expected_time: str | None = None,
) -> None:
    status = "MISSION SKIPPED" if skipped else "MISSION ACCOMPLISHED"
    color = "bright_yellow" if skipped else "bright_green"
    time_line: list[object] = []
    if elapsed_seconds is not None and not skipped:
        mins, secs = divmod(elapsed_seconds, 60)
        actual_str = f"{mins}m {secs:02d}s" if mins else f"{secs}s"
        time_line.append(Text(f"Time: {actual_str}" + (f"  (est. {expected_time})" if expected_time else ""), style="grey70"))
    body = Group(
        Text(status, style=f"bold {color}"),
        Text(f"{module_title(module_name)} • {level_name}", style="white"),
        Text(f"XP Earned: +{xp_earned}  |  Total: {total_xp}", style="bright_magenta"),
        *time_line,
    )
    console.print(Panel(body, border_style=color, box=box.DOUBLE, padding=(1, 2)))


def show_module_completion(certificate_panel: object) -> None:
    """Display the certificate panel returned by render_certificate_panel()."""
    console.print(certificate_panel)


def show_status(
    modules: list[dict],
    completed_levels: set[str],
    total_xp_by_module: dict[str, int],
    total_xp: int,
    max_xp_by_module: dict[str, int] | None = None,
    max_total_xp: int | None = None,
) -> None:
    effective_max = max_total_xp or sum(MODULE_TOTAL_XP.values())
    console.print(Rule("[bright_cyan]Mission Progress[/bright_cyan]"))
    console.print(progress_rows(modules, completed_levels, total_xp_by_module, max_xp_by_module))
    console.print(Panel(Text(f"Total XP: {total_xp:,} / {effective_max:,}", style="bold bright_magenta"), border_style="bright_magenta"))


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
        console.clear()  # clear screen
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

    def show(self, text: str, title: str = "Content", border: str = "bright_green", clear_first: bool = True) -> None:
        lines = text.split("\n")
        ranges = self._page_ranges(lines)
        total = len(ranges)

        idx = 0
        while True:
            s, e = ranges[idx]
            # Optionally skip clearing on the very first page so prior output
            # (e.g. the victory panel) remains visible above the first page.
            if idx == 0 and not clear_first:
                page_tag = f"  [Page {idx + 1}/{total}]" if total > 1 else ""
                console.print()
                console.print(
                    Panel(
                        Markdown("\n".join(lines[s:e])),
                        title=f"[bold {border}]{title}{page_tag}[/bold {border}]",
                        border_style=border,
                        box=box.DOUBLE,
                        padding=(1, 2),
                    )
                )
            else:
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
            ("1", "check",      "Run the validator — confirm your fix works"),
            ("d", "check-dry",  "Dry-run validator (shows result, no XP)"),
            ("w", "watch",      "Auto-run validator every 5s until pass"),
            ("2", "hint",       "Reveal the next hint  (up to 3)"),
            ("3", "guide",      "Show the full walkthrough / solution.yaml"),
            ("4", "debrief",    "Re-read the lesson for this level"),
        ],
        "bright_cyan",
    )

    cluster = _section(
        "CLUSTER",
        [
            ("5", "kubectl <cmd>",    "Pass kubectl command through safety guards"),
            ("e", "edit <type> <name>", "Dump resource to file, edit, then apply"),
            ("6", "reset",            "Rebuild the broken scenario from scratch"),
        ],
        "bright_yellow",
    )

    navigation = _section(
        "NAVIGATION",
        [
            ("7", "status",         "Show XP progress across all modules"),
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

def show_post_level_debrief(
    level_path: Path,
    elapsed_seconds: int | None = None,
    expected_time: str | None = None,
) -> None:
    """Paginate debrief.md then common-mistakes.md after a level passes."""
    debrief = level_path / "debrief.md"
    mistakes = level_path / "common-mistakes.md"

    has_debrief = debrief.exists()
    has_mistakes = mistakes.exists()

    if not has_debrief and not has_mistakes:
        return

    # Build the intro line — include elapsed time so it's visible even after
    # the victory panel scrolls away
    time_suffix = ""
    if elapsed_seconds is not None:
        mins, secs = divmod(elapsed_seconds, 60)
        actual = f"{mins}m {secs:02d}s" if mins else f"{secs}s"
        time_suffix = f"  ·  ⏱ {actual}" + (f" (est. {expected_time})" if expected_time else "")

    console.print()
    console.print(
        Panel(
            Text.assemble(
                ("  Level Complete — reading lesson", "bold bright_green"),
                (time_suffix, "bright_yellow"),
                ("   (q to skip)", "grey70"),
            ),
            border_style="bright_green",
            box=box.HEAVY_EDGE,
            padding=(0, 1),
        )
    )

    if has_debrief:
        # clear_first=False keeps the victory panel + intro banner above the first page
        _pager.show(
            debrief.read_text(encoding="utf-8"),
            title="Mission Debrief",
            border="bright_green",
            clear_first=False,
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
