## What went wrong

Both Deployments have 5 replicas. Since the Service selector matches all pods with `app: myapp`, Kubernetes distributes traffic evenly across all 10 pods — 50% to stable, 50% to canary. A canary should expose only 10% of users to the new version.

## Fix

In manifest.yaml:

```yaml
# app-stable
spec:
  replicas: 9

# app-canary
spec:
  replicas: 1
```

## Why this matters

This is how Kubernetes-native canary deployments work: replica count controls traffic percentage. 1 out of 10 pods = ~10% traffic to canary. Tools like Argo Rollouts or Flagger automate this pattern and add metrics-based promotion/rollback — but the underlying mechanism is the same replica ratio.