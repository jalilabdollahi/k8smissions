## What was broken

`catalog-indexer` needs about 55 seconds to load its index before it opens port 8080. Its liveness probe began immediately with a 10 second period and three allowed failures, so the kubelet restarted the container at about 30 seconds. The load restarted from scratch every time and the pods never reached Ready.

## The evidence

The previous log stopped at "loading index segment 6/11" or so, never reaching "listening". The pod events said `Liveness probe failed: ... connection refused` followed by `Killing`. A refused connection means nothing listened yet, not that the app was broken.

## Why Kubernetes behaves this way

Liveness and readiness probes begin as soon as the container starts, unless an `initialDelaySeconds` is set. If a `startupProbe` is defined, the kubelet runs only that probe until it succeeds once; during that time liveness and readiness are disabled. If the startup probe exhausts its `failureThreshold` the container is killed, so the window `periodSeconds x failureThreshold` must cover the slowest boot. Its default (period 10, threshold 3) gives only 30 seconds, which is no better than the liveness probe.

## The fix

Add a startupProbe with a window comfortably over 55 seconds, for example every 5 seconds up to 18 times. Liveness stays strict for steady-state detection. The alternative, a large `initialDelaySeconds` on liveness, also lets the pod boot but delays detection for every restart and every rollout forever.

## In production

Size the window from measured start times in the slowest environment, not from your laptop, and watch the start-up duration over time: a startup window that slowly becomes too tight is a classic cause of failed deploys.

## Commands worth remembering

- `kubectl explain pod.spec.containers.startupProbe`
- `kubectl logs <pod> --previous`
- `kubectl describe pod <pod>` (Events: Unhealthy, Killing)
