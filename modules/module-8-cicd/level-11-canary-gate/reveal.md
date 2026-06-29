## What went wrong

`pause: {}` in an Argo Rollout canary strategy creates a manual gate — the rollout waits for a human to run `kubectl argo rollouts promote api-rollout` before continuing. With no `duration`, the wait is infinite.

## Fix

```yaml
strategy:
  canary:
    steps:
    - setWeight: 20
    - pause:
        duration: 10m
    - setWeight: 50
    - pause:
        duration: 5m
    - setWeight: 100
```

To immediately unblock a paused rollout without changing the spec:
```bash
kubectl argo rollouts promote api-rollout -n k8smissions
```

## Why this matters

Canary strategies balance safety and speed. Indefinite `pause: {}` gates are useful when human judgment is required (e.g., QA sign-off). Timed `pause: {duration: 10m}` gates are useful for automated soak periods — give the canary time to accumulate metrics, then auto-promote if analysis passes. For fully automated canaries, pair the pause with an `AnalysisRun` that watches error rate and latency metrics and automatically aborts the rollout if thresholds are breached.