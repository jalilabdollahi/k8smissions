## What went wrong

`spec.replicas: 0` tells the Deployment controller to maintain exactly zero running pods. Kubernetes did not make an error — it followed the spec perfectly.

## Fix

Change the replicas count in manifest.yaml:

```yaml
spec:
  replicas: 3
```

## Why this matters

Setting replicas to 0 is a deliberate operation in production — it lets you stop a workload without deleting it or its configuration. When you are ready to restart, you scale back up. If you ever wonder why a Deployment is empty, check replicas before anything else.