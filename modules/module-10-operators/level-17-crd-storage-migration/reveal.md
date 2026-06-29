## What went wrong

The correct CRD version removal process:
1. Add new version (v1) with `storage: true`; keep old version (v1alpha1) with `served: true, storage: false`
2. Migrate all stored objects to v1 (reapply each object using the new API version)
3. Only then remove v1alpha1 from the CRD

The old version was removed (step 3) without completing the migration (step 2). Objects still in etcd as v1alpha1 are now unreadable.

## Fix

```yaml
versions:
- name: v1alpha1
  served: true
  storage: false
- name: v1
  served: true
  storage: true
```

After adding v1alpha1 back, migrate all objects:
```bash
kubectl get configs.example.com -o json | \
  jq '.items[] | .apiVersion = "example.com/v1"' | \
  kubectl apply -f -
```

Then verify no v1alpha1 objects remain before removing the version again.

## Why this matters

CRD version removal is irreversible once objects are deleted from etcd. The safe migration order is critical: always keep an old version served (even if not the storage version) until you've confirmed all objects have been migrated. Use `kubectl get --all-namespaces` on the old version to verify zero results before removing it from the CRD.