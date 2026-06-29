## What went wrong

The Deployment has 2 replicas but the PDB says `minAvailable: 3`. Kubernetes can never satisfy this — you cannot have 3 available pods when only 2 exist. As a result, `AllowedDisruptions` is permanently 0 and any eviction (drain, rolling update, autoscaler) is blocked.

## Fix

Either increase replicas to 3 or lower `minAvailable` to a value the Deployment can satisfy:

```yaml
# Option A: keep replicas at 2, relax the PDB
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
  namespace: k8smissions
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: web
```

Or increase replicas and keep `minAvailable: 2`:

```yaml
# In the Deployment:
spec:
  replicas: 3
```

## Why this matters

PodDisruptionBudgets protect availability during voluntary disruptions — cluster upgrades, node drains, and rolling updates all go through the eviction API. A PDB that can never be satisfied is worse than no PDB: it silently blocks all maintenance operations. The rule of thumb: `minAvailable` should always be strictly less than `replicas`, leaving at least one pod that can be disrupted.