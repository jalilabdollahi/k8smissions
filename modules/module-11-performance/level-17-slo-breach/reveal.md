## What went wrong

`failureThreshold: 10` × `periodSeconds: 10` = 100 seconds before the container is restarted. At 99.9% availability, the monthly error budget is 43.8 minutes. Even a single incident consuming 100 seconds of downtime eats ~3.8% of the monthly budget. Multiple incidents per month quickly exhaust it.

## Fix

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
```

Detection-to-restart time: 3 × 10s = 30 seconds maximum.

## Why this matters

Liveness probe tuning directly impacts availability SLO compliance:
- `failureThreshold: 3, periodSeconds: 10` → max 30s to detect and restart
- `failureThreshold: 10, periodSeconds: 10` → max 100s to detect and restart

The right `failureThreshold` depends on your workload. Too low (1–2) causes false-positive restarts on transient GC pauses or slow responses. Too high (10+) delays recovery from real crashes. Three is a common production default: it tolerates a single missed check without restarting, but acts quickly on sustained failures. Remember: liveness probes kill and restart containers — readiness probes (level 6) stop traffic routing. Use both together.