## What went wrong

The container runs `while true; do :; done` — a tight infinite loop that spins the CPU at 100%. It has a `requests.cpu: 100m` declaration (used for scheduling) but no `limits.cpu`, so the scheduler places it politely but the container then consumes all available CPU unchecked.

## Fix

```yaml
resources:
  requests:
    cpu: 100m
    memory: 32Mi
  limits:
    cpu: 200m
    memory: 64Mi
```

## Why this matters

In Kubernetes, `requests` is a scheduling hint — it tells the scheduler how much resource to reserve. `limits` is the enforcement ceiling — the kernel will throttle CPU or OOM-kill the container if it exceeds the limit. A pod without CPU limits is a noisy neighbor: it can absorb spare capacity without bound and degrade every other pod on the node. `kubectl top pods` is the real-time view; for historical usage, you need Prometheus or a similar metrics store.