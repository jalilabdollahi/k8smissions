## What went wrong

Liveness and readiness probes have different jobs. The liveness probe asks: 'is the container alive and should it continue running?' The readiness probe asks: 'is the container ready to receive traffic?' Using a readiness endpoint for liveness means that any moment the app isn't fully ready (including startup) causes Kubernetes to kill and restart the container.

## Fix

```yaml
readinessProbe:
  httpGet:
    path: /api/v1/ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Why this matters

The three probe types serve three distinct purposes:
- **livenessProbe**: Is the container stuck or deadlocked? Failure → restart the container.
- **readinessProbe**: Is the container ready to serve traffic? Failure → remove from Service endpoints (no restart).
- **startupProbe**: Has the container finished its slow initialization? Failure → don't start liveness/readiness yet.

A liveness endpoint should always be fast and cheap — a simple in-memory check. Never point liveness at an endpoint that depends on a database, cache, or slow initialization.