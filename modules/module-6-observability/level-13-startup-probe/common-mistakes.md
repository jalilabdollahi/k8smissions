# Common Mistakes — The Slow Starter

## Mistake 1: Setting initialDelaySeconds: 120 on liveness probe

**Wrong approach:** Large initialDelay delays liveness checking after every restart — if app deadlocks at 130s it takes 250s to detect

**Correct approach:** Use startupProbe for boot time; keep liveness probe with a small delay

## Mistake 2: Setting startupProbe failureThreshold too low

**Wrong approach:** failureThreshold: 5, periodSeconds: 5 gives 25s window — still not enough for 120s boot

**Correct approach:** Calculate: max_startup_seconds / periodSeconds = minimum failureThreshold
