## What went wrong

Setting both `maxSurge: 0` and `maxUnavailable: 0` is a logical deadlock:
- Kubernetes cannot scale up (maxSurge: 0 → no extra pods allowed)
- Kubernetes cannot scale down (maxUnavailable: 0 → cannot remove any running pod)
- Therefore nothing can change

## Fix

In manifest.yaml, allow at least one direction of movement:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1         # Can create 1 extra pod to start the update
    maxUnavailable: 0   # Keep all 3 running until new ones are ready
```

## Why this matters

This is a subtle but catastrophic misconfiguration. The Deployment appears healthy (pods are running), but it can never be updated. You might discover this only during an incident when you need to push a hotfix — and nothing happens.