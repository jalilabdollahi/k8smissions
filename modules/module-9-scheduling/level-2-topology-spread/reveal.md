## What went wrong

Without scheduling constraints, the scheduler places pods wherever there is available capacity — often the same node. Four replicas on one node means one node failure takes down 100% of the service despite having 4 replicas.

## Fix

```yaml
spec:
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: ha-app
```

## Why this matters

`TopologySpreadConstraint` is the modern replacement for `podAntiAffinity` for pod distribution. `maxSkew: 1` means the difference in pod count between any two topology domains (nodes in this case) cannot exceed 1. For 4 pods across 2 nodes, that means 2 pods per node — a 50/50 split. `whenUnsatisfiable: DoNotSchedule` enforces this hard; use `ScheduleAnyway` for a soft preference. For zone-level spread (more relevant for production), use `topologyKey: topology.kubernetes.io/zone`.