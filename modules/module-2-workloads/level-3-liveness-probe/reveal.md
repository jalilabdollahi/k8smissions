## What went wrong

The liveness probe sends `GET /nonexistent-healthz` to port 80. Nginx does not have a route for that path and returns HTTP 404. Kubernetes treats any non-2xx response as probe failure. After `failureThreshold: 2` consecutive failures, it kills and restarts the container — even though the container itself was perfectly healthy.

## Fix

Change the probe path to one nginx actually serves:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
```

## Why this matters

A misconfigured liveness probe is one of the nastiest production problems — the application works fine but Kubernetes keeps killing it. Always validate that your probe endpoint returns 200 before deploying. A probe hitting a non-existent path creates an infinite restart loop that is indistinguishable from a real crash at first glance.