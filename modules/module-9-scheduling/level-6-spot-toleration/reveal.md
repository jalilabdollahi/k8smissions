## What went wrong

The pod is doubly locked to spot nodes: the `nodeSelector` requires `node-type: spot`, and it only tolerates the spot taint. When spot nodes are reclaimed, the pod has nowhere to go — it can't reach on-demand nodes.

## Fix

```yaml
spec:
  tolerations:
  - key: spot
    operator: Equal
    value: 'true'
    effect: NoSchedule
  - key: on-demand
    operator: Equal
    value: 'true'
    effect: NoSchedule
  # Remove nodeSelector entirely
  containers:
  - name: batch
    ...
```

## Why this matters

Spot/preemptible nodes are cost-effective for batch workloads but can be reclaimed at any time. The resilient pattern: tolerate both spot and on-demand taints, but prefer spot using `nodeAffinity.preferredDuringScheduling` rather than hard-pinning with `nodeSelector`. This gives you spot pricing when available and automatic fallback to on-demand when reclaimed — no human intervention required. Never use `nodeSelector` for fault-tolerant workloads that need to survive node loss.