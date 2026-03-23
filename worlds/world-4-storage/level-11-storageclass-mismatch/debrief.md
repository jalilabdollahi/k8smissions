# The Missing Class

## What Was Broken
The PVC specified `storageClassName: fast-nvme` — a StorageClass that doesn't exist in the cluster. The default provisioner couldn't create a PV, so the PVC sat in Pending indefinitely.

## The Fix
Delete the PVC (PVC storageClassName is immutable) and recreate it with a valid StorageClass name. Use `kubectl get storageclass` to see what's available.

## Why It Matters
PVC Pending with 'no volume plugin matched' or 'storageclass not found' in Events is almost always a StorageClass name typo. Always check `kubectl get storageclass` before naming a storage class in a PVC.

## Pro Tip
StorageClass names are case-sensitive: 'Standard' != 'standard'. The cluster default StorageClass is annotated with `storageclass.kubernetes.io/is-default-class: 'true'`. If you omit `storageClassName` from a PVC, the default is used.

## Concepts
PVC, StorageClass, dynamic provisioning, Pending, volume plugin
