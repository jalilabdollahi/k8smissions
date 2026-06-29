## What went wrong

The PDB sets `minAvailable: 3`, which equals the Deployment's replica count. This means zero pods can ever be voluntarily removed — any eviction attempt (node drain, cluster upgrade, node maintenance) is permanently blocked.

## Fix

In manifest.yaml, change the PDB:

```yaml
spec:
  minAvailable: 2
```

This allows 1 pod to be evicted while keeping 2 running — enough for the node drain to proceed.

## Why this matters

PodDisruptionBudgets are a safety mechanism for cluster maintenance. Set `minAvailable` to the minimum number of pods your service can tolerate. A value equal to the replica count means your cluster can never be safely upgraded or maintained — a common mistake when ops and dev teams configure PDBs independently.