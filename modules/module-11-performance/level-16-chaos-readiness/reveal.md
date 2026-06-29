## What went wrong

With 2 replicas and no spread constraints, the scheduler can place both pods on the same node (or place them badly balanced). A single node failure can eliminate all replicas. Even with both pods on different nodes, losing one node loses 50% capacity.

## Fix

```yaml
spec:
  replicas: 5
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: resilient
```

## Why this matters

`topologySpreadConstraints` tells the scheduler to distribute pods across topology domains (nodes, zones, regions) such that the count difference between any two domains (`maxSkew`) is at most the configured value. With 5 pods across 5 nodes, `maxSkew: 1` means no node has more than 1 more pod than any other — a single node failure leaves 4/5 capacity intact.

`whenUnsatisfiable: DoNotSchedule` refuses to place pods that would violate the constraint. Use `ScheduleAnyway` to prefer spreading without hard enforcement. For zone-level HA (surviving AZ failures), use `topologyKey: topology.kubernetes.io/zone` instead.