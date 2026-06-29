## What went wrong

The Secret `db-credentials` was deleted while the Deployment was still running. The pods were in `Running` state before deletion because they had already injected the secret values at start time. But when kubelet attempted to restart any pod (for any reason), it could no longer find the secret — resulting in `CreateContainerConfigError` on all pods.

## Fix

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: k8smissions
type: Opaque
stringData:
  username: appuser
  password: securepass123
```

## Why this matters

Secret deletion is immediately visible to pods on their next restart, but running pods may continue with their already-injected values until they restart. The safe credential rotation procedure:
1. Create the new Secret with a new name (e.g., `db-credentials-v2`)
2. Update the Deployment to reference the new Secret → triggers a rolling update
3. Verify all pods are Running with the new Secret
4. Delete the old Secret

Never delete the old Secret until all pods have successfully restarted with the new one. Use `kubectl annotate deployment ... secret-rotation-date=$(date)` to track rotation history.