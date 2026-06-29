## What went wrong

The metrics-server Deployment has `replicas: 0`. This is a valid Kubernetes configuration — it means the Deployment exists but is scaled down to nothing. With no running pods, the Metrics API returns no data and `kubectl top` fails.

## Fix

```yaml
spec:
  replicas: 1
```

## Why this matters

The Metrics API (`metrics.k8s.io`) is not built into Kubernetes — it requires a separately deployed metrics-server. Without it, `kubectl top`, Horizontal Pod Autoscaler, and Vertical Pod Autoscaler all stop working. In production, this is typically installed via the metrics-server Helm chart or a cluster addon. The `replicas: 0` pattern is commonly used to disable a component without deleting it — reversible by scaling back up.