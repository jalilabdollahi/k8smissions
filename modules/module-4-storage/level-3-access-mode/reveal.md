## What went wrong

`ReadWriteOnce` (RWO) restricts the volume to a single node writer. With 3 replicas potentially spreading across nodes, pods on the second and third node are blocked from mounting the volume.

## Fix

In manifest.yaml, change both resources:

```yaml
# PersistentVolume
accessModes:
  - ReadWriteMany

# PersistentVolumeClaim
accessModes:
  - ReadWriteMany
```

## Access mode summary

- `ReadWriteOnce` (RWO) — one node mounts read-write (most common; fine for single-pod workloads)
- `ReadOnlyMany` (ROX) — many nodes mount read-only
- `ReadWriteMany` (RWX) — many nodes mount read-write (requires NFS, CephFS, or similar shared storage)

Note: hostPath volumes in kind support RWX only because it is a single-node cluster. In production, RWX requires network-attached storage.