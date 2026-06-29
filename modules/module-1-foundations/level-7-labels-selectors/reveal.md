## What went wrong

The Service selector specifies `app: frontend`, but the pod has label `app: backend`. The selector matches zero pods, so the Endpoints list is empty and traffic has nowhere to go.

## Fix

In manifest.yaml, under the Service spec, change the selector:

```yaml
spec:
  selector:
    app: backend
    tier: api
```

## Why this matters

Label selectors are how Kubernetes loosely couples Services to Pods — a Service does not reference a pod by name, only by labels. This makes it easy to add or replace pods without touching the Service, but a single typo in a label or selector silently breaks routing.