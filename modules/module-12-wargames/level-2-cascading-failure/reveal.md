## What went wrong

`auth-svc` was scaled to 0 replicas. Its Kubernetes Service still exists but has no endpoints. Every request that passes through auth — the entire API gateway call chain — fails with connection refused, which the gateway surfaces as 5xx errors to clients. A single service being scaled to zero caused a full outage of all downstream services.

## Fix

```yaml
spec:
  replicas: 2
```

## Why this matters

Cascading failures happen when services have synchronous dependencies without circuit breakers. When auth-svc goes to 0, the timeout on each auth call blocks the API gateway thread pool, which then exhausts its own connection pool, which cascades to the load balancer. The fix is simple (scale up); the lesson is architectural:
1. **Circuit breakers**: detect auth-svc being down and fail fast with a cached/degraded response instead of waiting for timeouts
2. **HPA min replicas**: set `minReplicas: 1` or higher on all critical services so HPAs can never scale them to 0
3. **Ownership**: who can run `kubectl scale`? Restrict with RBAC or admission webhooks
4. **Blast radius**: map your dependency graph — know which service failures cascade and how far