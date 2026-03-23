# StorageClass Missing

## Situation
PVC references storageClassName: "fast-ssd" which doesn't exist. PVC stays Pending forever.

## Successful Fix
Change storageClassName to "standard" (kind default) OR create the "fast-ssd" StorageClass

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for StorageClass Missing.

## Concepts
StorageClass, dynamic vs static provisioning, kubectl get storageclass, default storage class
