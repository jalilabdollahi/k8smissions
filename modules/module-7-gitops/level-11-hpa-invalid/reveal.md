## What went wrong

The HPA spec has `minReplicas: 10` and `maxReplicas: 3`. The Kubernetes API server accepts this manifest (it's valid YAML), but the HPA controller cannot reconcile it — you cannot have a minimum higher than a maximum. The HPA enters a permanent error state and the Deployment stays at whatever replica count it was at.

## Fix

```yaml
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Why this matters

HPA constraints: `1 <= minReplicas <= maxReplicas`. The HPA controller scales within this range based on the metric target. When CPU utilization exceeds 70%, it scales up; when utilization drops below the target, it scales down (after a cool-down period). A common production mistake is setting `minReplicas` too high and then wondering why costs are elevated — the HPA will never scale below `minReplicas` regardless of how low utilization drops.