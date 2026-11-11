**What was broken.** `ledger-api` had a slow liveness probe and no readiness probe. When a pod wedged (process alive, every request hangs), it kept receiving a quarter of all traffic for about 100 seconds until liveness finally restarted it.

**The evidence.** The client log showed success dropping to about 94% (one attempt in four hung, and the single retry had a one in four chance of hitting the same pod). `kubectl get endpoints` still listed all four pod IPs while one was wedged. The probe settings were readable in the Deployment: `periodSeconds: 10` times `failureThreshold: 10` is 100 seconds.

**Why Kubernetes behaved this way.** Without a readiness probe a container counts as Ready as soon as it starts; nothing removes a pod from the endpoints while it is running, however broken. Liveness only restarts. The error budget burns during the detection time: the fraction of traffic that goes to the bad pod times its length. Readiness has to be the fast control (seconds), liveness the slow safety net.

**The fix.** Readiness on a path that also hangs when the app is wedged, with a short period and threshold of 2 or less, and a liveness probe that reacts within about 15 seconds but needs more than one failure, because healthy pods answer slowly now and then.

**In production.** Give readiness and liveness different paths and different meanings: readiness may check dependencies and load, liveness must only check that the process itself is stuck. Use `startupProbe` for slow boots. Compute the burn rate from an SLI (success ratio) and alert on fast and slow windows together.

**Worth remembering.**
- `kubectl get endpoints <svc> -w`
- `kubectl explain pod.spec.containers.readinessProbe`
- `kubectl describe pod <pod>` (Events show `Readiness probe failed`, `Liveness probe failed`)
