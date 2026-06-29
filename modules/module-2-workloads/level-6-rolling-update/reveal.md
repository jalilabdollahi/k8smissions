## What went wrong

`maxUnavailable: 100%` with `maxSurge: 0` tells Kubernetes: 'you can take down all 3 pods before creating any new ones'. This is essentially the Recreate strategy written in RollingUpdate form. The service had zero running pods during the entire update window.

## Fix

In manifest.yaml:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

## Rule of thumb

- `maxUnavailable: 1` → at most 1 pod down at any time
- `maxSurge: 1` → one extra pod can be created during the update
- Result: 3 replicas always has at least 2 running while new ones are being prepared