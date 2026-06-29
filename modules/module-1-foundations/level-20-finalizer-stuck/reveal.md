## What went wrong

The finalizer `custom.operator.io/cleanup` is registered on the ConfigMap. Kubernetes holds off on deleting the object until some operator removes the finalizer — signalling that cleanup is done. That operator does not exist, so the ConfigMap is stuck in Terminating forever.

## Fix

Remove the finalizer directly using kubectl patch:

```bash
kubectl patch configmap stuck-config -n k8smissions \
  --type=json \
  -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
```

Once the finalizer list is empty, Kubernetes immediately completes the deletion.

## Why this matters

Finalizers are a legitimate Kubernetes mechanism — for example, a storage driver uses them to ensure a PersistentVolume is released before the claim is deleted. When the responsible controller crashes or is removed while finalizers remain on objects, those objects get stuck. Manually patching out the finalizer is the standard recovery procedure.