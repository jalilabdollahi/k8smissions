## What went wrong

Both the Pod and the Service have `namespace: default` in their metadata. Kubernetes created them in `default`, not in `k8smissions` where the game expects them.

## Fix (two steps)

**Step 1** — Delete the misplaced resources:
```bash
kubectl delete pod client-app -n default
kubectl delete service backend-service -n default
```

**Step 2** — Fix the namespace in manifest.yaml for both resources:
```yaml
metadata:
  namespace: k8smissions
```
Then apply the file.

## Why this matters

Namespaces are isolation boundaries. A Service in namespace A cannot automatically reach Pods in namespace B (without a fully-qualified DNS name like `svc.namespace.svc.cluster.local`). Mismatched namespaces are a common mistake when moving resources between environments.