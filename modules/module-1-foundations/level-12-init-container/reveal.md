## What went wrong

The init container waits until `backend-service.k8smissions.svc.cluster.local` resolves in DNS. That Service does not exist, so the init container loops forever and the main container never starts.

## Fix

Add the missing Service to manifest.yaml before the Pod:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: k8smissions
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Pod
# ... rest of pod spec unchanged
```

## Why this matters

Using an init container to wait for a dependency is a legitimate Kubernetes pattern — it enforces startup ordering. The mistake here was not the pattern but the missing dependency it was checking for.