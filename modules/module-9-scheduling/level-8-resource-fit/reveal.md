## What went wrong

The pod requests `memory: 100Gi`. Kubernetes schedules a pod atomically on a single node — it cannot split resource usage across nodes (that's what distributed computing frameworks like Spark are for). No node has 100Gi allocatable memory, so the scheduler reports `Insufficient memory` on every node.

## Fix

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 200m
    memory: 512Mi
```

## Why this matters

Resource requests serve two purposes: scheduling placement (the scheduler sums requests to determine if a node has space) and QoS classification (requests vs. limits ratio determines whether a pod is Guaranteed, Burstable, or BestEffort). A request that exceeds any node's allocatable memory will keep the pod Pending forever — it's not a question of cluster size or adding nodes, because the pod needs 100Gi on a *single* node. Always size requests based on what the application actually needs at steady state, verified by profiling, not by theoretical maximums.