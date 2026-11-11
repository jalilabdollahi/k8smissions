## What was broken

`critical-api` had `strategy.type: Recreate`, copied from a staging manifest where downtime did not matter. With `Recreate`, the Deployment scales the old ReplicaSet to zero, waits for those pods to be gone, and only then starts the new ones. During that window the Service has no endpoints at all.

## The evidence

At rest nothing looked wrong. The clue was in `get deployment -o yaml` (`strategy: type: Recreate`) and, during a release, in `get pods -w`: all four pods terminating at the same moment, then four new ones appearing. A poll through the Service showed a continuous run of failures.

## Why Kubernetes behaves this way

`Recreate` exists for software that must never run two versions at once (a single-writer database, a schema migration). `RollingUpdate` trades that for availability: it starts a surge pod, waits for it to be Ready, retires an old pod, and repeats, bounded by `maxSurge` and `maxUnavailable`.

## The fix

Set the strategy back to `RollingUpdate`. Tuning only `maxUnavailable` under `Recreate` is rejected by the API server, because those fields belong to the other strategy.

## In production

Rolling updates are only as safe as the readiness probe: a pod must be Ready only when it can serve, and old pods should drain with a `preStop` pause so in-flight requests finish (module 7 revisits graceful shutdown). For zero capacity loss set `maxUnavailable: 0`.

## Commands worth remembering

- `kubectl rollout status deployment/<name>`
- `kubectl explain deployment.spec.strategy`
- `kubectl get deployment <name> -o jsonpath='{.spec.strategy}'`
