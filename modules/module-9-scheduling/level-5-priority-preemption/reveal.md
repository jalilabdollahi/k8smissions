## What went wrong

The pod is labeled `critical-workload` in its name but assigned the `low-priority` PriorityClass. The scheduler only preempts lower-priority pods to make room for *higher*-priority ones. With the wrong class, the critical pod queues behind everything else.

## Fix

```yaml
spec:
  priorityClassName: high-priority
```

## Why this matters

Pod priority determines two things: scheduling queue order and preemption eligibility. A higher-priority pod that can't schedule will cause the scheduler to look for lower-priority pods to evict to make room. The numeric priority value (set in the PriorityClass) determines relative ordering — not the name. Common production tiers: `system-cluster-critical` (built-in, value 2000000000), `high-priority` (~1000), `default` (0), `low-priority` (~-100). Always use named PriorityClasses rather than raw numeric values — names are more auditable and refactorable.