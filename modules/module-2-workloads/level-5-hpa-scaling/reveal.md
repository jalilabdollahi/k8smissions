## What went wrong

The metrics-server Deployment has `replicas: 0`. No metrics-server pod is running, so the Kubernetes Metrics API has no data to serve. The HPA checks that API every 15 seconds and gets nothing — it shows `<unknown>` and makes no scaling decisions.

## Fix

In manifest.yaml, change the metrics-server Deployment replicas:

```yaml
replicas: 1
```

## Why this matters

In a real cluster, metrics-server is installed cluster-wide as an add-on (not in the application namespace). Here it is simulated. But the lesson is the same: before creating an HPA, always verify that `kubectl top pods` works — if it does, the Metrics API is available and the HPA will function.