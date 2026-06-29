## What went wrong

Three independent performance issues compounding:
1. **DNS amplification**: short name `api-svc` generates 5 DNS queries per lookup (ndots:5 default searches all suffixes)
2. **CPU throttling**: `limits.cpu == requests.cpu` leaves no burst capacity, causing CFS throttle on any load spike
3. **Serial rollout**: `maxSurge: 0, maxUnavailable: 1` with 50 replicas = 50 sequential replacements

## Fix

```yaml
# Fix 1: DNS pod
spec:
  dnsConfig:
    options:
    - name: ndots
      value: '2'
  containers:
  - command:
    - /bin/sh
    - -c
    - while true; do nslookup api-svc.k8smissions.svc.cluster.local; sleep 1; done
---
# Fix 2: API deployment CPU limit
resources:
  requests:
    cpu: 200m
  limits:
    cpu: 2000m
---
# Fix 3: Rollout strategy
strategy:
  rollingUpdate:
    maxSurge: 10
    maxUnavailable: 0
```

## Why this matters

Performance problems rarely announce themselves clearly. The skill is knowing where to look:
- **DNS**: check ndots, look at kube-dns CPU, count queries/second
- **CPU throttling**: `container_cpu_cfs_throttled_seconds_total` in Prometheus; compare limit vs. usage
- **Rollout velocity**: `kubectl rollout status` shows progress; check `maxSurge`/`maxUnavailable` when it's slow

Each fix is independent — order doesn't matter. But in production, fix the highest-impact issue first: CPU throttling causes user-visible latency; slow rollouts create deployment risk windows; DNS overhead adds latency at scale.