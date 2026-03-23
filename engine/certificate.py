#!/usr/bin/env python3
"""World completion certificates."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path


def generate_certificate(player_name: str, world_name: str, world_title: str, earned_xp: int) -> str:
    date = datetime.now().strftime("%B %d, %Y")
    return f"""# World Complete

**Agent:** {player_name}

**World:** {world_title}

**Date:** {date}

**XP Earned In World:** {earned_xp:,}

Mission Control recognizes the successful completion of `{world_name}`.
You restored every scenario in this world and are cleared for the next one.
"""


def save_certificate(repo_root: Path, world_name: str, certificate_text: str) -> Path:
    output_dir = repo_root / "certificates"
    output_dir.mkdir(exist_ok=True)
    output_path = output_dir / f"{world_name}-certificate.md"
    output_path.write_text(certificate_text, encoding="utf-8")
    return output_path
