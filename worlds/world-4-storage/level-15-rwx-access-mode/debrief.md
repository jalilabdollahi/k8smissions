# The Exclusive Mount

## What Was Broken
The PVC used `ReadWriteOnce` — at most one node can have the volume mounted at a time. Multiple pods on different nodes trying to use the same PVC caused some pods to be blocked with 'Multi-Attach error'.

## The Fix
Delete and recreate the PVC with `ReadWriteMany`. Ensure the StorageClass supports RWX — NFS, CephFS, and Azure Files support it; AWS EBS and local storage do not.

## Why It Matters
Access modes: RWO (one node, read-write), ROX (multi-node, read-only), RWX (multi-node, read-write), RWOP (one pod only). Most cloud-provider block storage only supports RWO. For shared writes, use a network file system (NFS, Ceph, GlusterFS).

## Pro Tip
Check if a StorageClass supports RWX with `kubectl describe storageclass <name>` — look for the provisioner and cross-reference its docs. Requesting RWX from a RWO-only provisioner leaves the PVC in Pending.

## Concepts
PVC, accessModes, ReadWriteOnce, ReadWriteMany, Multi-Attach error, NFS
