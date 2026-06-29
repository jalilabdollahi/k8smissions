## What went wrong

The container runs `sleep 20 && nginx -g 'daemon off;'`. For the first 20 seconds, nothing is listening on port 80. Without a readiness probe, Kubernetes adds the pod to the Service endpoints the moment the container process starts — and traffic immediately starts arriving at a port with nothing behind it.

## Fix

Add a readiness probe that waits until after the sleep:

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 22
  periodSeconds: 5
  successThreshold: 1
```

## Liveness vs Readiness

- **livenessProbe** — is the container alive? If not, kill and restart it.
- **readinessProbe** — is the container ready to receive traffic? If not, remove it from Service endpoints (but do not restart it).

You need both for slow-starting applications.