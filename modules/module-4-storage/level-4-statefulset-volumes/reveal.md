## What went wrong

All 3 postgres pods mount the same PVC via `spec.volumes.persistentVolumeClaim`. Kubernetes allows this, but it means all pods share the same directory — disastrous for a database.

## Fix

Remove the `volumes` block and add `volumeClaimTemplates` to the StatefulSet spec:

```yaml
volumeClaimTemplates:
- metadata:
    name: database-storage
  spec:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 5Gi
    storageClassName: standard
```

With this, Kubernetes creates:
- `database-storage-postgres-cluster-0` for pod 0
- `database-storage-postgres-cluster-1` for pod 1
- `database-storage-postgres-cluster-2` for pod 2

Each pod gets isolated storage that survives pod restarts.