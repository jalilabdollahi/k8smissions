## What went wrong

The ArgoCD Application targets the `webapp-prod` namespace, but that namespace was never created. ArgoCD cannot deploy resources into a namespace that doesn't exist, so the application stays OutOfSync.

## Fix

Create the namespace and deploy the application:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: webapp-prod
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-app
  namespace: webapp-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-app
  template:
    metadata:
      labels:
        app: webapp-app
    spec:
      containers:
      - name: webapp-app
        image: nginx:1.27.4
```

Also update the ConfigMap status to Synced:
```yaml
data:
  status: Synced
```

## Why this matters

In production ArgoCD setups, set `syncOptions: [CreateNamespace=true]` in the Application spec to allow ArgoCD to create the namespace automatically as part of the sync. ArgoCD's sync model compares desired state (Git) to actual state (cluster) across three dimensions: resource existence, spec content, and health status. All three must align for an application to be `Synced` and `Healthy`.