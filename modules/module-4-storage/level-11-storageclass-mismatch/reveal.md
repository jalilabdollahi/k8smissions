## What went wrong

`storageClassName: fast-nvme` — this StorageClass does not exist. No provisioner is registered for it. The PVC waits indefinitely for a PV that will never come.

## Fix

In manifest.yaml:

```yaml
spec:
  storageClassName: standard
```

## How to find available StorageClasses

```bash
kubectl get storageclass
```

Look for `(default)` — that class is used when no storageClassName is specified. You can also omit `storageClassName` entirely to use the default, but being explicit is better for clarity.

## Difference from level-5

Level 5 had a pod blocked by the pending PVC. This level isolates the PVC problem alone — same root cause, but here you see that a PVC can be stuck even before any pod tries to use it.