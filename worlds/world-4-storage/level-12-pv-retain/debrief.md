# Deleted Data

## What Was Broken
The PV had `reclaimPolicy: Delete`. When the PVC was removed, Kubernetes deleted the PV and the associated storage (hostPath data, or cloud disk). Data was permanently lost.

## The Fix
Patch the PV to use `reclaimPolicy: Retain`. After deletion, the PV enters Released state. To reuse it, remove the `claimRef` and a new PVC can bind to it.

## Why It Matters
The default StorageClass-provisioned PV often has Delete policy — designed for ephemeral dev data. For databases and user data, always use Retain. Some teams use Recycle (deprecated) or write custom cleanup automation triggered on Released PVs.

## Pro Tip
You can patch reclaimPolicy on a live PV at any time — it doesn't affect bound PVCs. Do this before anyone deletes the PVC to protect important data.

## Concepts
PersistentVolume, reclaimPolicy, Retain, Delete, Released state, data safety
