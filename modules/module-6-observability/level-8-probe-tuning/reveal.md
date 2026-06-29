## What went wrong

The app takes time to initialize before its `/healthz` endpoint is available. The liveness probe fires after only 5 seconds (`initialDelaySeconds: 5`), gets no response, and kills the container. This repeats forever.

## Fix

Add a `startupProbe` that gives the app a protected startup window:

```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

With `failureThreshold: 30` and `periodSeconds: 5`, the startup probe gives the app up to 150 seconds to become available before giving up. While the startup probe is active, the liveness probe is disabled.

## Why this matters

`startupProbe` was added specifically to solve the slow-start problem. Before it existed, engineers had to set very large `initialDelaySeconds` on the liveness probe — which delayed failure detection for the entire pod lifetime. The startup probe runs first and hands off to the liveness probe once it succeeds. The math: `failureThreshold × periodSeconds` = maximum startup budget. For Java apps, this is often 60–180 seconds.