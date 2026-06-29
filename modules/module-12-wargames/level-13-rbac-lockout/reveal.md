## What went wrong

Kubernetes RBAC requires three objects to work: **ServiceAccount** (the identity) + **Role** (the permission list) + **RoleBinding** (connects identity to permissions). Deleting the RoleBinding during rotation severed the connection — the ServiceAccount became permissionless instantly, with no graceful period.

## Fix

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rb
  namespace: k8smissions
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: k8smissions
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

RBAC changes take effect immediately — no pod restart needed.

## Why this matters

Safe ServiceAccount rotation:
1. Create the NEW ServiceAccount (e.g., `app-sa-v2`)
2. Create a RoleBinding for the new SA to the existing Role
3. Update the Deployment to use `serviceAccountName: app-sa-v2` → rolling restart
4. Wait for all pods to use the new SA
5. Only then delete the old SA and its RoleBinding

Deleting the old SA before step 3 creates a permission gap. Use `kubectl auth can-i` as `app-sa` to verify permissions before and after rotation. `kubectl auth can-i --list --as=...` shows all granted permissions.