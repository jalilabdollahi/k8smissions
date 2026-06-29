## What went wrong

A Deployment was used for a stateful workload. Deployments treat pods as interchangeable — random names, no ordering guarantees. Databases need stable network identities (`database-0.database-service`) so replicas can discover and connect to each other.

## Fix

In manifest.yaml, change the resource:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
  namespace: k8smissions
spec:
  serviceName: "database-service"   # required field for StatefulSet
  replicas: 3
  # ... rest of spec unchanged
```

## StatefulSet guarantees

- Stable pod names: `database-0`, `database-1`, `database-2`
- Stable DNS: `database-0.database-service.k8smissions.svc.cluster.local`
- Ordered startup: pod N does not start until pod N-1 is Running and Ready
- Ordered shutdown: reverse order