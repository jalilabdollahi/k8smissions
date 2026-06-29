## What went wrong

Kubernetes denies every API call made by `deploy-sa` because it has no RBAC permissions. The `kubectl apply` inside the Task pod is rejected with 403 Forbidden before any resource is created or updated.

## Fix

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deploy-role
  namespace: k8smissions
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["services", "configmaps"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deploy-rb
  namespace: k8smissions
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deploy-role
subjects:
- kind: ServiceAccount
  name: deploy-sa
  namespace: k8smissions
```

## Why this matters

CI/CD pipelines that deploy to Kubernetes must authenticate as a ServiceAccount with explicit RBAC permissions. The principle of least privilege applies: grant only the verbs and resource types the pipeline actually deploys. Avoid using `cluster-admin` for pipeline SAs — if a pipeline is compromised, a scoped Role limits the blast radius to the specific namespace and resource types the pipeline manages.