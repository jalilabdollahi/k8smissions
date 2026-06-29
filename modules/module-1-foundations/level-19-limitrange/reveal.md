## What went wrong

The namespace has a LimitRange that automatically injects `limits.memory: 32Mi` into any container that does not specify its own. The Python program allocates `bytearray(64 * 1024 * 1024)` — 64MB — which exceeds the injected 32Mi limit. OOMKilled.

## Fix

Add explicit resource limits to the pod in manifest.yaml to override the LimitRange default:

```yaml
resources:
  requests:
    memory: 64Mi
  limits:
    memory: 128Mi
```

## Why this matters

LimitRange is a namespace-level admission policy set by cluster administrators. It silently applies to every pod that does not specify its own limits. When a pod is OOMKilled but has no visible limit in its spec, always check `kubectl describe limitrange -n <namespace>` first.