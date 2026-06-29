## What went wrong

The Service selector requires `app: backend-app` but the pod's label is `app: backend`. Labels are compared as exact string matches — `backend` and `backend-app` are different values. The Service has zero endpoints.

## Fix

In manifest.yaml, under the Service spec:

```yaml
selector:
  app: backend
  tier: api
```

## Why this matters

Kubernetes does not warn you when a Service selector matches nothing — it just returns an empty endpoints list. Always verify with `kubectl get endpoints` after creating a Service. If the list is empty, compare selector to pod labels character by character.