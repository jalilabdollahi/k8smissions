# DB Down — Incident Response

## What Happened
The primary database pod was deleted (simulating a node failure or accidental kubectl delete). The application deployment had a readiness probe checking connectivity to the database, so all pods became unready when the DB vanished.

## The Fix
1. Restore the database pod: `kubectl apply -f solution.yaml`
2. Recreate the service that the app uses to find the DB
3. Once the DB is reachable the readiness probe passes and app pods become ready again

## Key Lessons
- **Readiness probes protect users** — even though app pods were crashing, the service stopped routing traffic to them
- **Services decouple discovery** — the app uses a Service DNS name, not a pod IP, so restoring the pod + service is enough
- **In production**: use StatefulSets for databases, not bare pods, and use PersistentVolumeClaims so data survives pod deletion

## Helpful Commands
```bash
kubectl get pods -n k8smissions
kubectl describe pod db-primary -n k8smissions
kubectl get endpoints db-service -n k8smissions
```
