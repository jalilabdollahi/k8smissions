## What went wrong

The pod mounts a Volume backed by ConfigMap `app-config`, but this ConfigMap does not exist in the namespace. Kubernetes cannot prepare the Volume, so the container never starts.

## Fix

Add the ConfigMap to manifest.yaml before the Pod:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: k8smissions
data:
  APP_MODE: production
---
apiVersion: v1
kind: Pod
# ... rest of pod spec unchanged
```

## Why this matters

Kubernetes prepares all Volumes before starting any container in the pod. If a referenced ConfigMap or Secret is missing, the pod is stuck in ContainerCreating forever — no error in the container logs, because the container never ran.