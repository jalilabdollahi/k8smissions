# Shared Storage Chaos

## Situation
StatefulSet has 3 replicas all mounting the same single PVC. Data corruption between pods. Each pod should have its own PVC.

## Successful Fix
Remove the shared PVC reference, add volumeClaimTemplates so Kubernetes creates one PVC per pod automatically

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Shared Storage Chaos.

## Concepts
StatefulSet volumeClaimTemplates, per-pod storage, dynamic provisioning, pod-0/pod-1/pod-2 storage isolation
