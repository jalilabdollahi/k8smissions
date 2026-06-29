## What went wrong

The `db-primary` Pod and `db-service` Service were deleted. The app server Deployment's readinessProbe runs `nc -z db-service 5432` on every check. Without the Service, the DNS name doesn't resolve and the probe returns non-zero immediately — Kubernetes marks all 3 pods NotReady and removes them from Service endpoints. No traffic can be served.

## Fix

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: db-primary
  namespace: k8smissions
  labels:
    app: db
spec:
  containers:
  - name: db
    image: busybox:1.36
    command: ["/bin/sh", "-c", "sleep 3600"]
    ports:
    - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: db-service
  namespace: k8smissions
spec:
  selector:
    app: db
  ports:
  - port: 5432
    targetPort: 5432
```

## Why this matters

ReadinessProbes create a hard dependency between app pods and their downstream dependencies. This is by design — it prevents traffic from reaching pods that can't serve requests. But it also means deleting the database Service instantly marks all app pods NotReady. In production: use circuit breakers and graceful degradation so apps can continue serving cached/degraded responses when the database is briefly unreachable. Never delete Services without first scaling down Deployments that depend on them.