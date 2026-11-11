# Module 5 fixtures

Shared by the levels of module 5. Levels reference these files from `setup.sh`
(`../_fixtures/...`); nothing is copied into a level folder. Owned by the
first-half author; the second half may only use them.

- `probe.yaml`: pod `probe` (`curlimages/curl:8.10.1`, sleeps). The in-cluster client
  that validators and players use: `kubectl exec probe -- curl ...`.
- `wait-ready.sh`: `wait-ready.sh probe [other-pod]` blocks until the named pods are Ready.

Usage in a level's `setup.sh`:

    kubectl -n "$NS" apply -f ../_fixtures/probe.yaml
    ../_fixtures/wait-ready.sh probe

Backends and API clients are never fixtures: each level builds its own from a
stock image (`busybox:1.36`, `nginx:1.27-alpine`, `python:3.12-alpine`,
`curlimages/curl:8.10.1`) so the failing mechanism stays in the level.
