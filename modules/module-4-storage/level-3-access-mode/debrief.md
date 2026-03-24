# Only One Can Write

## Situation
Three pods on different nodes need to share a volume for writing. PVC is ReadWriteOnce — only allows one writer.

## Successful Fix
Delete PVC (immutable spec), recreate with ReadWriteMany Note: Simulated on kind (single-node) but concept matters for production multi-node clusters

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Only One Can Write.

## Concepts
Access modes (RWO, RWX, ROX), PVC immutability, multi-pod shared storage, NFS/EFS for RWX
