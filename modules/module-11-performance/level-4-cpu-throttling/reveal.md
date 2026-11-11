Each quote costs about 10ms of CPU. The container has a 100m limit, which is 10ms of CPU per 100ms period, so a pod can serve about one request per period and everything else waits for the next period. Average usage looks fine; the time spent frozen only shows in the cgroup's `cpu.stat`.

1. `kubectl exec deploy/quote-api -- cat /sys/fs/cgroup/cpu.stat` under load: `nr_throttled` climbs almost as fast as `nr_periods`.
2. `kubectl set resources deployment/quote-api --requests=cpu=100m --limits=cpu=500m` raises the limit well above the burst demand and keeps a request.
3. Re-read `cpu.stat`: throttling stops and p95 returns to the 10 to 20ms range.

Removing the limit also works as long as the CPU request stays.
