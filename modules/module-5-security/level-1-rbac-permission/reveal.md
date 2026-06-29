## What went wrong

In Kubernetes, a ServiceAccount has **zero permissions by default**. The pod-reader ServiceAccount was created, but no one ever granted it the right to call the pods API. Every request the pod makes is rejected with HTTP 403 Forbidden.

## Fix

Add a Role that allows reading pods, then bind it to the ServiceAccount:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader-role
  namespace: k8smissions
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: k8smissions
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader-role
subjects:
- kind: ServiceAccount
  name: pod-reader
  namespace: k8smissions
```

## Why this matters

This is the core of Kubernetes RBAC: the **Role** defines *what* is allowed (verbs on resources), and the **RoleBinding** says *who* gets those permissions. Neither alone is enough. The principle of least privilege means granting only `get`, `list`, `watch` — not `create`, `delete`, or `patch` — when read-only access is all that's needed.