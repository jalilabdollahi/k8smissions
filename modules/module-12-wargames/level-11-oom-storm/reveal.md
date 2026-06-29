## What went wrong

When `limits.memory == requests.memory`, the container has zero headroom for memory bursts. The Guaranteed QoS class means: use exactly this much memory, and if you exceed it even briefly, the kernel OOM-kills the container immediately. A shared library update that temporarily allocates extra memory killed all three services simultaneously.

## Fix

```yaml
resources:
  requests:
    memory: "64Mi"
  limits:
    memory: "256Mi"  # 4x headroom
```

Apply to all three Deployments (`svc-alpha`, `svc-beta`, `svc-gamma`).

## Why this matters

Memory QoS classes:
- **Guaranteed** (`limits == requests`): highest scheduling priority, OOMKilled first among competing allocations — zero burst tolerance
- **Burstable** (`limits > requests`): can burst above requests up to limits — correct for most production services
- **BestEffort** (no limits or requests): lowest priority, evicted first under pressure — appropriate only for low-priority batch

For production services that handle memory spikes: set `limits` at 2–4× `requests`. Monitor `container_oom_events_total` in Prometheus. The goal is limits high enough to absorb normal spikes, but low enough to contain actual leaks before they kill other pods.