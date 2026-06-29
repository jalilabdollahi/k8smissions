## What went wrong

`maxSurge: 0, maxUnavailable: 1` produces a serialized replacement: terminate 1 old pod → wait for new pod to be Ready → repeat 99 more times. With 100 replicas and ~20 seconds per pod, this takes 33 minutes. This also means every deployment keeps 99/100 capacity during the update, which is cautious but extremely slow.

## Fix

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 10
    maxUnavailable: 0
```

Now 10 new pods are created simultaneously (10% surge), and when they become Ready, 10 old pods are terminated. The rollout takes ~100/10 = 10 sequential batches instead of 100 sequential pods.

## Why this matters

`maxSurge` and `maxUnavailable` control the rollout rate and resource cost:
- `maxSurge: N`: up to N extra pods above `replicas` during rollout (requires extra capacity)
- `maxUnavailable: N`: up to N pods can be unavailable at once (risky if N is large)
- `maxSurge: 25%, maxUnavailable: 25%` is a common balanced default

For critical services: set `maxUnavailable: 0` (no capacity reduction) and `maxSurge` as high as your cluster can absorb. For resource-constrained clusters: increase `maxUnavailable` to avoid needing surge capacity.