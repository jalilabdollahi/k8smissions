## What went wrong

`emptyDir: {}` — this volume is created fresh every time the pod starts. Any file written to it is lost the moment the pod is deleted or rescheduled. For user uploads or any persistent data, emptyDir is the wrong choice.

## Fix

In manifest.yaml, add a PVC and change the volume:

```yaml
# Add before the Pod
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
  namespace: k8smissions
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
# In the Pod spec, replace emptyDir:
volumes:
- name: data
  persistentVolumeClaim:
    claimName: app-data
```

## When emptyDir is correct

emptyDir is useful for: scratch space, caches, sharing files between containers in the same pod. Never use it for data that must survive pod restarts.