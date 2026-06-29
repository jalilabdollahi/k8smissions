## What went wrong

The `LowNodeUtilization` strategy is configured with correct thresholds but `enabled: false`. The Descheduler reads this policy and skips the strategy entirely — no evictions happen and the imbalance persists.

## Fix

```yaml
apiVersion: policy/v1alpha1
kind: DeschedulerPolicy
strategies:
  LowNodeUtilization:
    enabled: true
    params:
      nodeResourceUtilizationThresholds:
        thresholds:
          cpu: 20
          memory: 20
          pods: 20
        targetThresholds:
          cpu: 50
          memory: 50
          pods: 50
```

## Why this matters

Kubernetes schedules pods at creation time but never moves them after placement. Over time, clusters become imbalanced: early pods fill the first nodes that had space; later pods pile on while other nodes sit empty. The Descheduler complements the scheduler by evicting pods from overloaded nodes (above `targetThresholds`) so the scheduler can replicate them on underutilized nodes (below `thresholds`). This improves availability (fewer pods per node means less blast radius per failure) and resource efficiency. The Descheduler typically runs as a CronJob every 5–10 minutes.