## What went wrong

When `limits.cpu == requests.cpu`, the container gets exactly its reserved CPU share and nothing more. Under load, the Linux CFS (Completely Fair Scheduler) enforces the quota: once the container uses 100ms of CPU in a 100ms window, it's throttled for the rest of the window. This creates bursty latency that looks like slow responses every 100ms.

## Fix

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi
```

## Why this matters

CPU requests determine scheduling placement and guaranteed share. CPU limits determine the throttle ceiling. Setting them equal creates a Guaranteed QoS class (good for predictable latency) but removes all burst capacity. Setting limits higher (or omitting limits entirely) allows the container to use spare CPU on the node without throttling. The right ratio depends on your workload: latency-sensitive services often want limits 3–10x the request; batch jobs often want limit = request for predictable throughput. Prometheus metric `container_cpu_cfs_throttled_seconds_total` reveals throttling in production.