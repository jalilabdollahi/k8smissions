#!/usr/bin/env python3
"""Regenerate levels.json without rebuilding level directories.

Run: python3 scripts/generate_registry.py
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from scripts.build_levels import generate_registry

if __name__ == "__main__":
    out = generate_registry()
    print(f"✅ Registry written → {out.relative_to(ROOT)}")
    import json
    reg = json.loads(out.read_text())
    print(f"   {len(reg['worlds'])} worlds, {reg['level_count']} levels")
