## What went wrong

No `readinessProbe` is defined on either pod. Kubernetes marks a container Ready immediately after it starts — it has no way to know whether the application inside is actually handling requests. Traffic is sent to pods before they are ready, causing intermittent failures during restarts or rolling updates.

## Fix

Add a readinessProbe to each pod in manifest.yaml:

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 1
```

## Why this matters

Readiness probes are not optional for production workloads. Without one, every rolling update sends traffic to half-started pods. With one, Kubernetes waits for a passing health check before adding the pod to the Service endpoints.