## Patching storedVersions first

The API server accepts it, the Job then removes v1alpha1 and reports success, and every `kubectl get configs` fails with `request to convert CR from an invalid group/version`. The objects were never rewritten, so they are still stored as v1alpha1, a version that no longer exists. Rewrite first.

## Rewriting before switching the storage version

`kubectl replace` stores the objects in the current storage version, which is still `v1alpha1`, so nothing changes. Mark `v1` as storage first.

## Removing v1alpha1 from the CRD by hand

The API server rejects it while `storedVersions` still lists it ("must remain in spec.versions until a storage migration"). That check protects your data; satisfy it by migrating, not by bypassing it.
