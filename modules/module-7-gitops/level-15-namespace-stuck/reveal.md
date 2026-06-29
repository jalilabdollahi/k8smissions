## What went wrong

Finalizers are strings added to a resource's metadata that block deletion until they are removed. The controller that registered `some.controller.io/cleanup` was deleted without first clearing the finalizer from the ConfigMap. Kubernetes waits forever for the finalizer to be cleared — which can never happen now.

## Fix

Force-remove the finalizer from the ConfigMap:

```bash
kubectl patch configmap stuck-resource -n zombie-ns \
  --type=json \
  -p='[{"op":"remove","path":"/metadata/finalizers"}]'
```

Or via the manifest, set:

```yaml
metadata:
  finalizers: []
```

Once all resource finalizers are cleared, the namespace finalizer clears automatically and the namespace deletion completes.

## Why this matters

Finalizers are Kubernetes' mechanism for ordered cleanup: operators register a finalizer on resources they manage, do their cleanup work when deletion is requested, then remove the finalizer to allow deletion to proceed. The failure mode is when the operator is deleted without cleaning up its finalizers first — leaving orphaned finalizers that block deletion permanently. Always check `metadata.finalizers` when a resource refuses to delete. The nuclear option (force-deleting a namespace via the API server proxy) bypasses finalizers entirely but can leave orphaned resources in etcd.