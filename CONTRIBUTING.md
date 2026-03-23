# Contributing to K8sMissions

Thank you for improving K8sMissions! This guide explains how the project is structured and how to add new levels, worlds, and engine features.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Level Format](#level-format)
3. [WORLD_DESCRIPTION.txt Format](#world_descriptiontxt-format)
4. [Adding a New Level](#adding-a-new-level)
5. [Adding a New World](#adding-a-new-world)
6. [Engine Architecture](#engine-architecture)
7. [Regenerating the Level Registry](#regenerating-the-level-registry)
8. [Code Style](#code-style)

---

## Project Structure

```
k8smissions/
├── play.sh                  # Game launcher
├── install.sh               # One-time setup script
├── levels.json              # Auto-generated level registry (do not edit by hand)
├── progress.json            # Player save file (auto-managed)
├── engine/
│   ├── engine.py            # Main game loop
│   ├── ui.py                # Rich terminal UI helpers
│   ├── certificate.py       # World completion certificates
│   ├── player.py            # Player name prompt
│   ├── reset.py             # Level reset / broken state setup
│   └── safety.py            # kubectl safety guards
├── worlds/
│   ├── world-1-foundations/
│   │   ├── WORLD_DESCRIPTION.txt
│   │   ├── level-1-first-pod/
│   │   │   ├── mission.yaml
│   │   │   ├── broken.yaml
│   │   │   ├── solution.yaml
│   │   │   ├── validate.sh
│   │   │   ├── hint-1.txt
│   │   │   ├── hint-2.txt
│   │   │   ├── hint-3.txt
│   │   │   ├── debrief.md
│   │   │   └── common-mistakes.md
│   │   └── ...
│   └── ...
├── scripts/
│   ├── build_levels.py      # Regenerates level directories from WORLD_DESCRIPTION.txt
│   └── generate_registry.py # Regenerates levels.json registry
├── completion/
│   ├── k8smissions.bash     # Bash tab completion
│   └── k8smissions.zsh      # Zsh tab completion
└── certificates/            # Generated world certificates (auto-created)
```

---

## Level Format

Each level lives in its own directory under `worlds/<world-name>/level-N-<slug>/` and contains **9 required files**:

### `mission.yaml`

JSON (parsed as YAML) describing the mission metadata:

```json
{
  "name": "Short human-readable name",
  "description": "What the player observes — symptoms only, no root cause spoilers",
  "objective": "The X is broken because Y — fix Z",
  "xp": 150,
  "difficulty": "beginner|intermediate|advanced|expert",
  "expected_time": "10m",
  "concepts": ["pod lifecycle", "readiness probes"],
  "world": "world-1-foundations",
  "level": "level-3-readiness"
}
```

**Rules for `description`:** Describe only what the player can *observe* — error messages, pod states, output in the terminal. **Do not reveal the root cause.**

**Rules for `objective`:** State what is broken and what to fix. A good template: `"The <component> is <broken state> — fix <action>"`.

### `broken.yaml`

Kubernetes manifest(s) that set up the broken scenario. Applied to the `k8smissions` namespace by `reset.py` when the level starts or is reset.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  namespace: k8smissions
spec:
  containers:
  - name: app
    image: nginx:doesnotexist99   # intentionally broken
```

> Multiple documents in one file are supported (separated by `---`).

### `solution.yaml`

The fixed manifest(s). Displayed when the player runs `guide`. Not applied automatically — the player must apply it themselves.

### `validate.sh`

Bash script that tests whether the player's fix is correct. Must exit `0` on success, non-zero on failure. Output is shown to the player.

```bash
#!/bin/bash
set -euo pipefail
NS="k8smissions"

STATUS=$(kubectl get pod my-pod -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ]; then
  echo "✅ PASS: pod is Running"
  exit 0
fi
echo "❌ FAIL: pod status='$STATUS'"
exit 1
```

**Important:** Always use `NS="k8smissions"` and pass `-n "$NS"` to all kubectl commands.

### `hint-1.txt`, `hint-2.txt`, `hint-3.txt`

Progressive hints. `hint-1` should be vague (what to look for), `hint-2` more specific (which command to run), `hint-3` almost a direct answer.

### `debrief.md`

Post-level lesson explaining:
- What happened (root cause)
- The fix with exact commands
- Key Kubernetes concepts
- Relevant `kubectl` commands

### `common-mistakes.md`

A list of common errors players make on this level. Use `## ❌` headers for each mistake.

---

## `WORLD_DESCRIPTION.txt` Format

Each world directory contains a `WORLD_DESCRIPTION.txt` used by `scripts/build_levels.py` to scaffold level directories. Format:

```
LEVEL 1 — level-slug
Name:         Human Readable Name
Difficulty:   beginner
XP:           100
Time est.:    5m
Description:  What the player sees (symptoms)
Objective:    The X is broken — fix Y
Broken state: Describe what broken.yaml should set up
Fix:          What the solution should do
Validate:     What validate.sh should check
Concepts:     pod, image, kubectl
Hint 1:       Broad direction hint
Hint 2:       More specific hint
Hint 3:       Near-answer hint
Debrief:      Learning points for the lesson
Folder:       level-1-slug-name
```

---

## Adding a New Level

### Option A: Manual (recommended for complex war-game scenarios)

1. Create the directory:
   ```bash
   mkdir -p worlds/world-N-name/level-M-slug
   ```

2. Create all 9 files (`mission.yaml`, `broken.yaml`, `solution.yaml`, `validate.sh`, `hint-1/2/3.txt`, `debrief.md`, `common-mistakes.md`)

3. Regenerate the registry:
   ```bash
   python3 scripts/generate_registry.py
   ```

4. Test your level:
   ```bash
   ./play.sh
   # Navigate to your level with 'skip', then test it
   ```

### Option B: Via WORLD_DESCRIPTION.txt (for scaffolding)

1. Add a new `LEVEL N — slug` block to the world's `WORLD_DESCRIPTION.txt`
2. Run `python3 scripts/build_levels.py` (⚠️ this **clears** existing level directories in that world)
3. Fill in generated stub files with real content

---

## Adding a New World

1. Create the world directory: `worlds/world-N-name/`
2. Add a `WORLD_DESCRIPTION.txt` describing the theme
3. Create level directories with all 9 files each
4. Add the world to `engine/ui.py` `WORLD_TITLES` dict (used as display name fallback):
   ```python
   WORLD_TITLES = {
       ...
       "world-N-name": "Human Readable Title",
   }
   ```
5. Regenerate the registry: `python3 scripts/generate_registry.py`

> **XP totals** are now computed dynamically from `mission.yaml` files — no need to update `WORLD_TOTAL_XP` manually.

---

## Engine Architecture

The engine is fully event-driven with a simple inner/outer loop:

```
game_loop()
  └── outer while: load worlds, load progress, show briefing
        └── inner while: Prompt.ask → dispatch command
              ├── check      → run_validator() → complete_level() on pass
              ├── check-dry  → run_validator() (no XP)
              ├── watch      → watch_mode() (auto-check every 5s)
              ├── hint       → show_guidance()
              ├── guide      → show_guide()
              ├── debrief    → show_post_level_debrief()
              ├── reset      → prepare_level()
              ├── status     → show_status()
              ├── skip       → complete_level(award_xp=False)
              └── reset-progress → wipe progress.json
```

**`progress.json` fields:**

| Field | Type | Description |
|-------|------|-------------|
| `player_name` | string | Agent callsign |
| `total_xp` | int | Accumulated XP |
| `completed_levels` | list[str] | Level IDs (`world/level` format) |
| `current_world` | string | Active world directory name |
| `current_level` | string | Active level directory name |
| `world_certificates` | list[str] | Worlds with earned certificates |
| `time_per_level` | dict[str, int] | Seconds taken per level ID |
| `level_start_time` | float\|null | Unix timestamp when current level started |

---

## Regenerating the Level Registry

After adding or modifying levels, regenerate `levels.json` so the engine loads quickly without scanning directories:

```bash
python3 scripts/generate_registry.py
```

The engine will automatically use `levels.json` if it exists, and fall back to directory scanning otherwise.

---

## Code Style

- Python 3.10+ with `from __future__ import annotations`
- All UI output goes through `engine/ui.py` — never print directly from engine.py
- `validate.sh` scripts must use `set -euo pipefail` and always set `NS="k8smissions"`
- All Kubernetes manifests must use `namespace: k8smissions`
- Difficulties: `beginner` | `intermediate` | `advanced` | `expert`
- XP ranges: beginner 50–100, intermediate 100–200, advanced 200–300, expert 300–500
