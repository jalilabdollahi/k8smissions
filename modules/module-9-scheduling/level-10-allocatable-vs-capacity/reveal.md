## What went wrong

A node with `Capacity.memory: 6Gi` has a lower `Allocatable.memory` because the kubelet reserves memory for itself and system processes (`--kube-reserved`, `--system-reserved`). If allocatable is 5.4Gi and the pod requests 5Gi, plus existing pod requests, there's not enough allocatable memory — even though the raw node capacity looks sufficient.

## Fix

```yaml
resources:
  requests:
    cpu: 100m
    memory: 1Gi
  limits:
    cpu: 200m
    memory: 2Gi
```

## Why this matters

Always size pod requests against `Allocatable`, not `Capacity`. The formula:
```
Allocatable = Capacity - kube-reserved - system-reserved - eviction-threshold
```
Check it with `kubectl describe node | grep Allocatable`. A common mistake: calculating "I need 90% of 6Gi so I'll request 5.4Gi" — but allocatable may already be 5.2Gi after reserves, leaving only 200Mi free. The scheduler also sums all existing pod requests against allocatable, so even a node with low actual utilization may show `Insufficient memory` if many pods have reserved capacity.