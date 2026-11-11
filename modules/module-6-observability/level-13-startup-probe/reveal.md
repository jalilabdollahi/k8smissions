The indexer loads 11 segments for about 55 seconds before it listens. The liveness probe (period 10, threshold 3) runs from the first second and kills the container after about 30 seconds of refused connections, so it never gets to answer.

1. `kubectl logs --previous` ends mid-load; `describe pod` shows `Liveness probe failed: ... connection refused` and `Killing`.
2. Add a startupProbe on `/healthz` with a window of at least 60 seconds, for example `periodSeconds: 5` and `failureThreshold: 18` (90 seconds), through `kubectl patch deploy catalog-indexer`.
3. Liveness stays as it was, so a hang after start-up is still detected within 30 seconds.
