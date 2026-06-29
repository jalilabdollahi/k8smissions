## What went wrong

The operator uses `WATCH_NAMESPACE` to configure its controller-runtime cache scope. With `value: operators`, the informer only indexes objects from the `operators` namespace — CRs in `k8smissions` are never received by the controller. The operator logs show no errors because from its perspective, nothing happened.

## Fix

```yaml
env:
- name: WATCH_NAMESPACE
  value: ''
```

An empty string tells controller-runtime to watch all namespaces.

## Why this matters

Namespace-scoped operators are a common deployment pattern for multi-tenant clusters — each operator instance manages its own namespace. Cluster-scoped operators (empty WATCH_NAMESPACE) manage all namespaces. The choice affects RBAC requirements: a cluster-scoped operator needs a ClusterRole, while a namespace-scoped operator can use a Role. When CRs exist in unexpected places and the operator silently ignores them, always check watch scope first.