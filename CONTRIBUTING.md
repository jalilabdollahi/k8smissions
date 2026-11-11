# Contributing to K8sMissions

Thanks for helping. K8sMissions only works if every level is real: a believable
incident on a real cluster, a fix the player has to find, and a check that proves
the fix by behaviour. Please read these first:

- [`docs/LEVEL_AUTHORING.md`](docs/LEVEL_AUTHORING.md): the level contract (files,
  `mission.yaml` fields, validator and solution rules, hints, debriefs).
- [`docs/curriculum/README.md`](docs/curriculum/README.md): module scopes and which
  module owns which topic.
- `docs/curriculum/<module>.md`: the design map for each module, one row per level.

## Changing or adding a level

1. Update the module's map row first, so overlaps with other levels are caught on
   paper. Each level needs its own failing mechanism and its own fix.
2. Write every file of the level by hand. Never generate levels or their texts
   from a shared template.
3. Don't rename or delete existing level folders. The folder name is the level id
   in players' `progress.json`. New levels get the next free number in their module.
4. Test until all three pass:

   ```bash
   venv/bin/python scripts/test_levels.py <module>/<level> --mirror
   venv/bin/python scripts/lint_levels.py <module>/<level>
   venv/bin/python scripts/check_duplicates.py <module>/<level>
   ```

   `test_levels.py` creates its own kind cluster from `kind-config.yaml` (never the
   game cluster). It checks that the validator fails on an empty cluster and on the
   broken state, passes after `solution.sh`, and that cleanup leaves nothing behind.
5. `play.sh` rebuilds the registry (`levels.json`) on every start. To refresh it
   without starting the game: `venv/bin/python scripts/generate_registry.py`.

## Engine architecture

```
game_loop()
  └── outer loop: load modules and progress, prepare_level(), show briefing
        └── inner loop: prompt → dispatch command
              ├── check / check-dry / watch → run_validator()
              ├── hint / reveal             → hints, then the answer for -50% XP
              ├── debrief / guide / status / skip / reset-progress
              └── reset                     → prepare_level()
```

- `engine/reset.py` `prepare_level()` returns the cluster to a clean baseline. It
  deletes objects labelled `k8smissions/managed=true` (cluster-scoped ones too),
  level namespaces, and mission `cleanup` entries, and it resets node taints, labels,
  cordons and extended resources. Then it ensures the level's add-ons, runs
  `setup.sh` and applies `broken.yaml`, labelling what they create.
- `engine/addons.py` installs pinned metrics-server, ingress-nginx, Tekton and
  Argo CD (core) on demand.
- `scripts/test_levels.py` imports the same functions, so the tests exercise exactly
  what players get.

**`progress.json` fields:** `player_name`, `total_xp`, `completed_levels`
(`module/level` ids), `current_module`, `current_level`, `module_certificates`,
`time_per_level`, `level_start_time`.

## Code style

- Python 3.9+ with `from __future__ import annotations`; UI output goes through
  `engine/ui.py`.
- Level scripts use `$NS` (set by the engine and the tests) and stay compatible with
  macOS bash 3.2.
- Difficulty and XP: beginner 100, intermediate 150, advanced 200, expert 300.
