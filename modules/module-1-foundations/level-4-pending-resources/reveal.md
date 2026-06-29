## What went wrong

`memory: 999Gi` and `cpu: 999` are larger than any node in the cluster can provide. The scheduler checks every node and finds none that can satisfy the request — so the pod stays Pending forever.

## Fix

Set realistic values in manifest.yaml:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

## Why this matters

`requests` is what the scheduler uses to decide where to place the pod — it guarantees that amount is available. `limits` is the ceiling the container cannot exceed. Both should reflect what the application actually needs.