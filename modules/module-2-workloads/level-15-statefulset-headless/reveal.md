## What went wrong

The Service `db-svc` has a `clusterIP` assigned (not `None`). A StatefulSet's `serviceName` must reference a **headless Service** (`clusterIP: None`). Without this, the DNS subdomain that gives each pod its stable identity (`db-0.db-svc.k8smissions.svc.cluster.local`) cannot be created.

## Fix

In manifest.yaml, rename or replace the Service to be headless:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-headless
  namespace: k8smissions
spec:
  clusterIP: None        # This is what makes it headless
  selector:
    app: db
  ports:
  - port: 3306
    targetPort: 3306
```

And update the StatefulSet:

```yaml
spec:
  serviceName: db-headless
```

## Why headless?

A headless Service (`clusterIP: None`) does not load-balance — instead, DNS returns the individual IP of each pod. This is how `db-0.db-headless` resolves to exactly pod db-0 and nothing else. Databases need to address replicas individually, not through a load balancer.