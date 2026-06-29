## What went wrong

Two mismatches prevent binding:
1. PV capacity is 1Gi but PVC requests 5Gi — a PV must be at least as large as the PVC request
2. PV storageClassName is `standard` but PVC requires `fast` — the class must match exactly

## Fix

In manifest.yaml, update the PV:

```yaml
spec:
  capacity:
    storage: 5Gi
  storageClassName: fast
```

## PV binding rules

Kubernetes binds a PVC to a PV only when ALL of these match:
- `accessModes` — both must include the same mode
- `storageClassName` — must be identical
- `capacity` — PV capacity must be >= PVC request

A mismatch in any one of these leaves the PVC in Pending forever.