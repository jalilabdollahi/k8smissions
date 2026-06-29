## What went wrong

The ResourceQuota caps the namespace at 2 CPUs total (`requests.cpu: "2"`). The pod asks for 2500m (2.5 CPUs) — 25% more than the whole namespace is allowed. Kubernetes never even tries to find a node; the quota check fails at the API server before scheduling begins.

## Fix

Reduce the pod's resource requests to fit within the quota:

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

## Why this matters

ResourceQuotas are a namespace-level governance tool: they prevent any single team or workload from starving others. When a pod's requests exceed the quota, it is rejected at admission — `kubectl apply` succeeds but the pod never schedules. Always check `kubectl describe resourcequota` before setting large resource requests, and size requests to what the application actually needs, not its theoretical maximum.