#!/usr/bin/env python3
"""Player profile helpers."""

from __future__ import annotations

import getpass

from rich.prompt import Prompt


def prompt_player_name(current_name: str = "") -> str:
    """Prompt for a player name, preserving existing value when present."""
    default_name = current_name or getpass.getuser() or "K8s Agent"
    name = Prompt.ask("Agent callsign", default=default_name).strip()
    return name or default_name
