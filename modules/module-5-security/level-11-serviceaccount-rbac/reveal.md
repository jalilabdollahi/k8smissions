## What went wrong

The ServiceAccount `config-reader-sa` exists but has no RBAC resources backing it. When the pod calls the Kubernetes API to list ConfigMaps, the API server checks the ServiceAccount's permissions, finds none, and returns HTTP 403 Forbidden.

## Fix

Create a Role scoped to configmaps and bind it to the ServiceAccount:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: configmap-reader
  namespace: k8smissions
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: config-reader-binding
  namespace: k8smissions
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: configmap-reader
subjects:
- kind: ServiceAccount
  name: config-reader-sa
  namespace: k8smissions
```

## Why this matters

This is the same RBAC pattern as level 1, but applied to ConfigMaps instead of Pods. The lesson to reinforce: ServiceAccounts are identities, not permission grants. You can verify the fix before the pod even restarts with: `kubectl auth can-i list configmaps --as=system:serviceaccount:k8smissions:config-reader-sa -n k8smissions`. That command should return `yes` once the RoleBinding is applied.