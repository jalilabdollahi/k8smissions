## What went wrong

The container runs as user 1000. The PVC volume is mounted with ownership root:root (0:0). User 1000 has no write permission on a root-owned directory.

## Fix

Add `fsGroup` to the pod-level securityContext in manifest.yaml:

```yaml
spec:
  securityContext:
    fsGroup: 1000   # pod-level
  containers:
  - name: app
    securityContext:
      runAsUser: 1000
      runAsGroup: 1000   # container-level
```

Kubernetes changes the volume's group ownership to `fsGroup` before mounting it. Since the container's runAsGroup is also 1000, it has write access.

## fsGroup vs runAsGroup

- `runAsGroup` — the primary group of the process inside the container
- `fsGroup` — the group ownership applied to mounted volumes (set once at pod startup)

These are on different levels: `fsGroup` is pod-level (applies to all volumes), `runAsGroup` is container-level (affects only that container's process).