## What went wrong

The pause container (`registry.k8s.io/pause`) does nothing — it's a minimal binary that just sleeps. But its `requests.cpu: 2000m` and `requests.memory: 4Gi` tell the scheduler that 2 full CPUs and 4Gi of memory are reserved on this node. Real workloads can't schedule because from the scheduler's perspective, the capacity is gone.

## Fix

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```

## Why this matters

Balloon pods are a legitimate technique — they're used to pre-warm Cluster Autoscaler by keeping a node alive that would otherwise scale down, so it's available immediately for burst traffic. The key: the balloon pod should have a low PriorityClass and `cluster-autoscaler.kubernetes.io/safe-to-evict: 'true'`, so it gets preempted instantly when real work arrives. An oversized balloon defeats the purpose — it hogs the capacity instead of yielding it. Balloon requests should be small enough that real workloads can always preempt them.