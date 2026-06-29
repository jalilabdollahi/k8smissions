## What went wrong

`limits.memory: 64Mi` — the container is allowed to use at most 64 megabytes. The Python program allocates ~128MB, exceeds the limit, and the Linux kernel sends SIGKILL (exit code 137, also shown as OOMKilled).

## Fix

Increase the memory limit in manifest.yaml:

```yaml
resources:
  limits:
    memory: 256Mi
  requests:
    memory: 64Mi
```

## Why this matters

OOMKilled is one of the most common production issues in Kubernetes. Set limits high enough to survive peak usage. Use `kubectl top pod` to observe actual memory consumption before deciding on the right limit.