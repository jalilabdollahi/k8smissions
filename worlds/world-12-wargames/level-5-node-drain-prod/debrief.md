# Surprise Drain

## What Happened
The PodDisruptionBudget required minAvailable:3 but the Deployment only has 2 replicas. This means 0 pods can ever be evicted — even disrupting one pod would drop below the minimum of 3 (which is impossible to satisfy with only 2).

## The Fix
```bash
kubectl patch pdb critical-pdb -n k8smissions -p '{"spec":{"minAvailable":1}}'
```

## Key Lessons
- **PDB math**: minAvailable must be strictly less than the number of replicas, or maxUnavailable must be at least 1
- **Node maintenance requires working PDBs** — if PDBs are misconfigured, nodes can never be drained
- **maxUnavailable vs minAvailable** — prefer maxUnavailable for more predictable drain behavior
- **Production practice**: always test drain in staging before production maintenance windows

## Drain Command
```bash
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```
