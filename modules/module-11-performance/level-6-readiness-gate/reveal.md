## What went wrong

Without a `readinessProbe`, kubelet marks the container as ready immediately when it starts running. The rolling update controller sees the new pod as ready and proceeds to terminate the old pod — before the Java application has loaded its Spring context, opened database connections, and warmed its caches. The brief window where both old and new pods are in transition creates the 502 errors.

## Fix

```yaml
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 5
  failureThreshold: 3
```

## Why this matters

Readiness probes gate traffic routing — a pod not passing its readiness probe is removed from Service endpoint lists and receives no traffic. This is distinct from liveness probes (which restart failing containers). The `initialDelaySeconds` skips probing during known-slow startup. The `periodSeconds` and `failureThreshold` control how quickly readiness is detected and lost. For JVM applications, `initialDelaySeconds: 30–60` is typical. For containerized apps exposing a `/health/ready` endpoint (Spring Actuator, Quarkus health, Go health checks), the probe should verify actual readiness — not just 'process is running'.