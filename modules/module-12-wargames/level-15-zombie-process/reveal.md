## What went wrong

Without probes, Kubernetes only knows the container is 'Running' — meaning its process is alive. A zombie process (or hung process that doesn't respond to HTTP) keeps PID 1 alive, so the container never transitions to Failed. The pod stays in Service endpoints and receives traffic that is silently dropped.

## Fix

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 3
  periodSeconds: 5
  failureThreshold: 3
livenessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3
```

## Why this matters

Two probes serve different purposes:
- **readinessProbe**: 'is this pod ready to serve traffic?' — failure removes it from Service endpoints (stops routing new requests)
- **livenessProbe**: 'is this pod fundamentally alive?' — failure restarts the container (self-healing)

For a zombie: readinessProbe removes it from endpoints immediately; livenessProbe restarts it after `failureThreshold × periodSeconds` seconds. The `initialDelaySeconds` gap prevents the liveness probe from restarting the container before it finishes startup. Always implement both probes for production HTTP services — the cost is negligible, the protection is essential.