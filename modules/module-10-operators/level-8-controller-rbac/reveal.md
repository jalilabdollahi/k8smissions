## What went wrong

The operator's ClusterRole is too narrow. It can read/write its own CRDs but cannot touch the downstream Kubernetes resources it creates (Deployments, Services, ConfigMaps, Pods). It also can't update the status subresource, which requires a separate rule.

## Fix

```yaml
rules:
- apiGroups: ["example.com"]
  resources: ["workloads", "workloads/status"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

## Why this matters

Operator RBAC must cover every Kubernetes resource the operator touches — both reading (to build the desired state) and writing (to reconcile toward it). The `status` subresource is separate from the main resource: `update` on `workloads` doesn't grant `update` on `workloads/status`. Common operator RBAC checklist: CR read/write, CR status update, event create (for emitting Kubernetes events), and all owned resource types. The `controller-gen` tool generates RBAC markers from Go annotations to keep this list current automatically.