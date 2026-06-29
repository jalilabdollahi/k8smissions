## What went wrong

The app sleeps 120 seconds before touching `/tmp/ready`. The liveness probe starts at 10s and kills the container at 40s (10 + 3×10). The container is killed 80 seconds before it can ever succeed. Without a startup probe, there is no way to give a slow-starting app a protected initialization window.

## Fix

Add a `startupProbe` that covers the full startup window:

```yaml
startupProbe:
  exec:
    command:
    - test
    - -f
    - /tmp/ready
  failureThreshold: 30
  periodSeconds: 5
livenessProbe:
  exec:
    command:
    - test
    - -f
    - /tmp/ready
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 3
```

`30 × 5s = 150s` startup budget — enough for the 120s boot. While the startup probe is active, the liveness probe is suspended entirely.

## Why this matters

The startup probe solves a fundamental tension: slow-starting apps need time, but liveness probes need to act fast when a running app deadlocks. The startup probe separates these two concerns cleanly. Once it succeeds once, it stops running and hands off to liveness. This pattern is essential for JVM-based services, databases loading large datasets, and any application with a non-trivial initialization sequence.