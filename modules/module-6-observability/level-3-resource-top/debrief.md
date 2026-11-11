## What was broken

Each `thumbnailer` pod runs two containers. The `exporter` sidecar spins in a busy loop and has only a CPU request, no limit, so it takes whatever CPU the node has free. The `app` container, the one everybody watches, is idle.

## The evidence

`kubectl top pod` sums the containers, so it blamed the whole pod and the owners saw an idle web server. `kubectl top pod --containers` broke the number down and showed `exporter` at roughly 1000m next to `app` at 0m. Reading the pod spec confirmed a request of 50m and no limit.

## Why Kubernetes behaves this way

A CPU request is only a scheduling weight and a guarantee under contention. Without a limit nothing stops a container from using idle cycles. A limit becomes a CFS quota in the container's cgroup (`cpu.max`), which is what the kubelet and the kernel actually enforce. Limits are per container, so the pod-level `top` view cannot say where to put one.

## The fix

Add a CPU limit to the `exporter` container only. A limit on `app` would have throttled the wrong process, and the sidecar would have kept running unbounded.

## In production

Alert on per-container usage, not pod totals. Size the limit from observed usage rather than a round number, and remember that a limit that is too low shows up as throttling (`container_cpu_cfs_throttled_seconds_total`), not as restarts. `top` data lags by up to a minute.

## Commands worth remembering

- `kubectl top pod --containers --sort-by=cpu`
- `kubectl top node`
- `kubectl exec <pod> -c <container> -- cat /sys/fs/cgroup/cpu.max`
