## What went wrong

The namespace quota caps the total CPU requests at 500m. A single pod (`quota-buster`) claims 400m — 80% of the total. Any new pod requesting more than 100m CPU will be rejected at the API server with a quota exceeded error, even if nodes have gigabytes of free CPU capacity.

## Fix

Reduce the pod's resource requests to leave headroom for other pods:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 100Mi
  limits:
    cpu: 200m
    memory: 200Mi
```

## Why this matters

ResourceQuota enforces *namespace-level* aggregate limits, not per-pod limits. A single over-requesting pod can block the entire namespace. The right tool for per-pod ceilings is a `LimitRange`, which sets default and maximum request values per container. Together, ResourceQuota and LimitRange form a two-layer governance model: the quota controls the namespace total, the LimitRange prevents any single container from claiming an unreasonable share of it.