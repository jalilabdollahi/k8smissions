# Module 1 fixtures

Shared by the levels of module 1. Levels reference these files from `setup.sh`
(`../_fixtures/...`); nothing is copied into a level folder. Owned by the
first-half author; the second half may only use them.

- `probe.yaml`: pod `probe` (`curlimages/curl:8.10.1`, sleeps). The in-cluster
  client that validators and players use: `kubectl exec probe -- curl ...`.
- `wait-ready.sh`: `wait-ready.sh probe [other-pod...]` blocks until the named pods are Ready.

Usage in a level's `setup.sh`:

    kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
    ../_fixtures/wait-ready.sh probe

Backends are never fixtures: each level builds its own from a stock image so the
failing mechanism stays in the level.
