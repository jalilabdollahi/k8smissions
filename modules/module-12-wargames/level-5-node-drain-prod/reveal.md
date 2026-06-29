## What went wrong

`minAvailable: 3` with only 2 replicas creates a mathematically impossible constraint: `allowed_disruptions = replicas - minAvailable = 2 - 3 = -1`, clamped to 0. No pod can ever be evicted. Node drains, cluster autoscaler scale-downs, and rolling updates are all permanently blocked.

## Fix

```yaml
spec:
  minAvailable: 1
```

With `minAvailable: 1` and 2 replicas: `allowed = 2 - 1 = 1` — one pod can be drained at a time while one remains available.

## Why this matters

PDB constraints must satisfy: `minAvailable < replicas` (or equivalently `maxUnavailable >= 1`). Violations cause silent operational blockers — the cluster appears healthy, pods appear Running, but node maintenance is impossible. The operationally safer alternative:
```yaml
spec:
  maxUnavailable: 1  # scales automatically with replica count
```

Using `maxUnavailable` instead of `minAvailable` is more resilient to accidental scale-down: if replicas drops to 1, `minAvailable: 1` still blocks everything, but `maxUnavailable: 1` with 1 replica = `minAvailable: 0` = drains can proceed. Always verify with `kubectl describe pdb` that `ALLOWED DISRUPTIONS > 0`.