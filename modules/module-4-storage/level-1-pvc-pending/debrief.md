# PVC Won't Bind

## Situation
Pod stuck in ContainerCreating. PVC is in Pending state because no PV matches its storage request (PV has 1Gi, PVC requests 5Gi).

## Successful Fix
Update PVC to request 1Gi  OR create a larger PV

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for PVC Won't Bind.

## Concepts
PV/PVC binding, capacity matching, StorageClass, kubectl get pv pvc
