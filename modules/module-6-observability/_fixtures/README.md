# Module 6 fixtures

Shared by the levels of module 6. Levels reference these files (`../_fixtures/...`);
nothing is copied into a level folder. Owned by the first-half author; the second
half may only use them.

- `probe.yaml`: pod `probe` (`curlimages/curl:8.10.1`, sleeps). The in-cluster client
  that validators and players use: `kubectl exec probe -- curl ...`.
- `wait-ready.sh`: `wait-ready.sh probe [other-pod]` blocks until the named pods are Ready.
- `min-age.sh`: `min-age.sh [-n namespace] <label-selector>` prints the age in seconds of
  the youngest live pod matching the selector (0 if none). Validators call it so a
  pod must outlive the broken state's failure window before the level counts as fixed.

- `live-pods.sh`: `live-pods.sh [-n namespace] <label-selector>` prints the names of Running pods that are not
  being deleted (kubectl jsonpath cannot filter on a missing `deletionTimestamp`).
- `ensure-probe.sh`: creates pod `probe` if missing and waits for it. Validators call it, so a level
  needs no `setup.sh` just for a client pod.

Usage in a level's `setup.sh`:

    kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
    ../_fixtures/wait-ready.sh probe

Usage in a `validate.sh`:

    age=$(../_fixtures/min-age.sh app=search-api)

Backends are never fixtures: each level builds its own from a stock image so the
failing mechanism stays in the level.
