## What went wrong

`required` anti-affinity with `topologyKey: kubernetes.io/hostname` means each pod must be on a different node. With 3 replicas and 2 nodes, the third pod violates the constraint on every available node — it can never schedule.

## Fix

```yaml
spec:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: distributed
          topologyKey: kubernetes.io/hostname
```

## Why this matters

This is one of the most common scheduling mistakes in small clusters. Required anti-affinity with hostname topology is effectively a constraint that `replicas <= node count`. It works fine in a large cluster but permanently blocks pods in smaller environments. `preferred` anti-affinity gives you the spread you want when nodes are available, but falls back to co-scheduling when necessary. If you truly need one-pod-per-node for correctness (e.g., a DaemonSet-like workload), use a DaemonSet instead — which is designed for exactly this pattern.