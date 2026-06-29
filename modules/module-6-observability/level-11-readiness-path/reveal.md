## What went wrong

The readiness probe sends `GET /healthz HTTP/1.1` to port 80. Nginx has no `/healthz` route, so it returns 404. A non-2xx response counts as a probe failure. After `failureThreshold` consecutive failures, the pod is marked NotReady and removed from the Service's endpoint list.

## Fix

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Why this matters

Readiness probes control Service routing — a pod that fails readiness gets no traffic, but is not restarted. This is the right behavior during initialization or when a dependency is temporarily unavailable. The path you probe must actually exist on the server. For production nginx deployments, add a dedicated `/healthz` location block in your nginx.conf, or use a TCP probe (`tcpSocket`) as a simpler alternative: if nginx is listening, the port is open.