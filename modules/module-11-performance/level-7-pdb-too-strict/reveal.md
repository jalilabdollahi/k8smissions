## What went wrong

`minAvailable: 3` with `replicas: 3` means the PDB allows zero disruptions: `allowed_disruptions = replicas - minAvailable = 3 - 3 = 0`. Every eviction attempt (node drain, cluster autoscaler scale-down, rolling update) is blocked. Nodes can never be drained for maintenance.

## Fix

```yaml
spec:
  minAvailable: 2
```

This allows `3 - 2 = 1` disruption at a time — one pod can be evicted while 2 remain available.

## Why this matters

PDBs must be sized relative to the actual replica count. Common mistake: setting `minAvailable` equal to `replicas`, which makes the PDB completely block disruptions. Better: use `maxUnavailable: 1` (absolute) or `maxUnavailable: 33%` (percentage) which automatically scales with replica count changes. A PDB that blocks all disruptions is worse than no PDB — it prevents maintenance without providing any actual benefit. Always verify `kubectl describe pdb` shows `ALLOWED DISRUPTIONS > 0` after creating a PDB.