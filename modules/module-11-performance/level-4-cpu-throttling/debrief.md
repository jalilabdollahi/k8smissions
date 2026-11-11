**What was broken.** quote-api spends about 10ms of CPU per request. Its container had a 100m CPU limit and a 50m request. At light load that is fine; under 15 requests per second per pod the work no longer fits, and the kernel freezes the container until the next period. Latency went from 20ms to hundreds of milliseconds and some callers timed out, while `kubectl top` showed usage below the limit.

**The evidence.** `cat /sys/fs/cgroup/cpu.stat` inside the container: `nr_periods` is the number of 100ms scheduling periods and `nr_throttled` how many of them ended with the container frozen. Under load they rise almost together, and `throttled_usec` shows the total time lost. `kubectl top` averages over about a minute, so it cannot see a container that is throttled for 90ms of every 100ms in bursts.

**Why Kubernetes behaved this way.** A CPU limit is not a speed limit, it is a quota: `limit x 100ms` of CPU time per period (the CFS bandwidth controller). Once a burst spends the quota the container stops, even if the node is idle. A CPU request is different: it only gives scheduling weight and a guaranteed share when the node is busy. Memory limits kill, CPU limits pause.

**The fix.** Raise the limit well above the burst demand, or remove it, and keep the request near real use so the pod stays Burstable and is still scheduled sensibly.

**In production.** Many teams run latency-sensitive services with a CPU request and no CPU limit, and alert on `container_cpu_cfs_throttled_periods_total / container_cpu_cfs_periods_total`. Multi-threaded runtimes burn quota faster than their average suggests. Cap noisy neighbours with requests and quotas, not with tight limits.

**Worth remembering.**
- `kubectl exec <pod> -- cat /sys/fs/cgroup/cpu.stat`
- `kubectl top pod --containers`
- `kubectl set resources deployment/<name> --limits=cpu=<n>`
