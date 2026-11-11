# Module 12 fixtures

Shared by the wargame levels. The first-half author (levels 1-9) owns this directory; the
second half uses it read-only. Apps and controllers are never fixtures: every level carries its
own small stdlib-Python script in a ConfigMap (run by `python:3.12-alpine`), because the fault
lives in the script's configuration.

## lib.sh

`. ../_fixtures/lib.sh` from a level's `validate.sh` or `setup.sh` (cwd = level directory).
Needs `kubectl` and `jq`; `$NS` defaults to `k8smissions`.

| function | what it does |
|---|---|
| `ok` / `bad` | print a line starting with a check or cross mark |
| `ensure_probe` | starts (once) a `curlimages/curl` pod `probe` (label `app=probe` only, so it is "an outsider" for NetworkPolicies) |
| `pcurl <curl args>` | curl from the probe pod, silent, 5 s limit |
| `live_pods <sel>`, `ready_count <sel>`, `restart_sum <sel>` | Running/Ready/restart counts of non-terminating pods by label selector |
| `rollout_done <deploy> <n>` | true when the Deployment has exactly `n` updated, available and Ready replicas and the controller has observed the latest generation |
| `wait_rollout <deploy> [secs]` | blocks until the rollout is complete (for `setup.sh`) |

`solution.sh` runs in an empty directory and cannot source this file; it uses plain `kubectl`.

## certs/ (level 9, committed, never regenerated at run time)

`gen-certs.sh` documents how they were made. They are signed by module 10's `ca-a`
(`../../module-10-operators/_fixtures/certs/ca-a`, read-only reuse) so the players can issue
fresh ones with the CA key that level 9 puts in Secret `internal-ca`.

| dir | contents |
|---|---|
| `certs/ledger-expired/` | `tls.crt`/`tls.key`, serverAuth, SANs `ledger`, `ledger.k8smissions[.svc[.cluster.local]]`, valid 2024-01-01 to 2024-04-01 |
| `certs/gateway-expired/` | clientAuth leaf `CN=gateway-client`, same dates |
| `certs/ca.crt` | copy of module 10's `ca-a` certificate |

## Other module fixtures reused (read-only)

- level 7 mounts module 10's `server.py` (webhook server) and `certs/good`, `certs/ca-a`, `certs/ca-b`.
- level 9 mounts module 10's `certs/ca-a` (CA certificate and key).

## Measured behaviours (kind 1.36)

- Recreating an `immutable` ConfigMap under the same name while pods that reference it are still
  on the node leaves the kubelet serving the old cached object: replacement pods start with the
  old values (spiked in level 3). Levels roll forward to a new name instead.
