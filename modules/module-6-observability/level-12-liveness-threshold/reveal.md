## What went wrong

With `failureThreshold: 1`, the liveness probe has zero tolerance for transient delays. Any momentary hiccup — a busy node, a GC pause, a network blip — causes a probe miss, which immediately triggers a pod restart. This creates a cycle of unnecessary restarts that can cascade into service disruption.

## Fix

```yaml
livenessProbe:
  exec:
    command:
    - ls
    - /
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3
```

## Why this matters

The four probe timing fields work together:
- `initialDelaySeconds`: how long to wait before the first probe
- `periodSeconds`: how often to probe
- `failureThreshold`: consecutive failures before action is taken
- `successThreshold`: consecutive successes needed to mark healthy again (default: 1)

Total time before restart = `failureThreshold × periodSeconds`. With the fix above, the pod tolerates 30 seconds of probe failures before being restarted — enough to survive any transient delay in a healthy cluster. The Kubernetes defaults (3 failures, 10s period) are sensible starting points for most applications.