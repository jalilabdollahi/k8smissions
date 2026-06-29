## What went wrong

The Service selector `version: blue` matches only the old blue Deployment's pods. The green Deployment was deployed but no one updated the Service to point to it. Green pods are running with no traffic.

## Fix

In manifest.yaml, under the Service spec:

```yaml
spec:
  selector:
    app: myapp
    version: green
```

## Blue-green deployment pattern

This is the core mechanic of blue-green deploys: both versions run simultaneously, but the Service selector controls which one receives traffic. Switching is instant — one field change. Rolling back is equally instant — switch the selector back to blue. No pod restarts required.