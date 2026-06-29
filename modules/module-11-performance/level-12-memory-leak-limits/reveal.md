## What went wrong

Without a memory limit, the container's cgroup has no memory ceiling. As memory leaks accumulate, the container grows until the entire node runs out of memory. At that point, the Linux OOM killer selects processes to kill based on OOM score — often killing other pods, not the leaky one. The leaky pod (having the most memory) actually has a negative OOM adjustment and may survive while innocent pods are killed.

## Fix

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Why this matters

Memory limits enforce container-level isolation. When a container exceeds its memory limit, the kernel OOM-kills only that container — Kubernetes then restarts it based on the `restartPolicy`. This is contained blast radius vs. node-wide OOM. Trade-offs:
- Setting limits too low: frequent OOMKills even for healthy memory growth
- Setting limits too high: insufficient isolation from memory leaks

A memory leak should be fixed, not just contained — but limits prevent blast radius while the fix ships. Monitor `container_oom_events_total` in Prometheus. Consider setting `limits.memory` to 2× `requests.memory` for containers with known variable memory usage.