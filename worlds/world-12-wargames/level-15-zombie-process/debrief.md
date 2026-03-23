# Zombie Pod

## What Happened
The application process became a zombie (Z state in Unix — exited but not reaped by its parent). The container runtime still reports the container as Running because PID 1 is technically alive. Without probes Kubernetes has no way to know the app is unresponsive.

## The Fix
Add readiness and liveness probes:
```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 3
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
```

## Key Lessons
- **Probes are not optional for production** — without them Kubernetes is flying blind
- **Readiness** removes pod from Service endpoints when failing
- **Liveness** restarts the container when failing
- **PID 1 and zombie reaping** — use `tini` or Docker's `--init` flag to ensure proper signal handling and zombie reaping
