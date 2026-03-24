# Locked Out

## What Happened
During a service account rotation, the RoleBinding was deleted but not recreated. The ServiceAccount exists and the Role exists, but without the binding the SA has zero permissions — all API calls return 403 Forbidden.

## The Fix
```bash
kubectl create rolebinding app-rb \
  --role=app-role \
  --serviceaccount=k8smissions:app-sa \
  -n k8smissions
```

## Key Lessons
- **RBAC triple**: ServiceAccount + Role + RoleBinding — all three must exist
- **Auth check**: `kubectl auth can-i list pods --as=system:serviceaccount:k8smissions:app-sa -n k8smissions`
- **Rotation safety**: create new SA + RoleBinding before deleting old ones
- **Audit logs**: 403 errors from specific SAs are visible in the API server audit log
