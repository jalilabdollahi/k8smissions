## What went wrong

All pods in this namespace have the same default priority (0). The scheduler only preempts lower-priority pods when a higher-priority pod needs their resources. Without a PriorityClass and an assigned `priorityClassName`, every pod is equal and nothing gets evicted.

## Fix

Create PriorityClasses and assign them:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: false
description: "Development workloads"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
preemptionPolicy: PreemptLowerPriority
globalDefault: false
description: "Critical production workloads"
```

Then set `priorityClassName: high-priority` on the critical pod and `priorityClassName: low-priority` on the dev pod.

## Why this matters

Pod priority is the mechanism Kubernetes uses to implement capacity reservations without fixed resource allocations. When the cluster is full and a high-priority pod arrives, the scheduler preempts (evicts) lower-priority pods to free space. This is how you guarantee critical services can always schedule, even under resource pressure. Never mix priority classes with equal values if you intend ordering — the numeric gap between classes is what determines preemption order.