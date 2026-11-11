**What was broken.** A 40-replica Deployment that rolled one pod at a time (`maxSurge: 0`, `maxUnavailable: 1`), with each pod waiting about 10 seconds before it counted as available. The rollout was serial, so its length was 40 times the wave time.

**The evidence.** `kubectl get pods -w` during a restart shows exactly one pod terminating and one starting at a time, and `kubectl get deployment -o yaml` shows both the strategy and `minReadySeconds`. The readiness probe's `initialDelaySeconds` adds to the wave. A single number cannot be pointed at: the duration is waves multiplied by wave length.

**Why Kubernetes behaved this way.** The Deployment controller keeps `available >= replicas - maxUnavailable` and `total <= replicas + maxSurge`. With surge 0 it has to remove an old pod before it may start a new one. `minReadySeconds` delays when a ready pod is counted as available, and the controller moves on only when pods become available. Setting `maxUnavailable: 100%` would be fast but empties the Service of capacity, which breaks the floor.

**The fix.** Allow more surge, keep `maxUnavailable` within the capacity floor, and trim the waits so a wave is a few seconds, not ten.

**In production.** Surge costs real capacity (quota and node room), so check headroom first. Keep `minReadySeconds` for catching crash-on-start, but not longer than that needs. Use `progressDeadlineSeconds` and `kubectl rollout status` as the gate in CI, and a PodDisruptionBudget for voluntary disruption only: it does not limit rolling updates.

**Worth remembering.**
- `kubectl rollout status deployment/<name> --timeout=60s`
- `kubectl get deployment <name> -o jsonpath='{.spec.strategy}'`
- `kubectl rollout history deployment/<name>`
