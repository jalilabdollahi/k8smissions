# Class Not Found

## What Was Broken
The ResourceClaim specified 'non-existent-fpga-class' which wasn't registered. Dynamic Resource Allocation requires both a ResourceClass (driver registration) and the ResourceClaim to exist.

## The Fix
Create the ResourceClass matching the claim's resourceClassName, or update the claim to reference an existing class.

## Why It Matters
Dynamic Resource Allocation (DRA) is the k8s 1.26+ replacement for device plugins. It allows more flexible resource allocation: partial allocation, shared resources, vendor-specific scheduling. It's analogous to the PVC/StorageClass model for compute devices.

## Pro Tip
Check available resource classes: kubectl get resourceclass. These are cluster-scoped (not namespaced). The driverName must match a registered device driver running as a DaemonSet.

## Concepts
ResourceClaim, ResourceClass, DRA, device allocation, v1alpha2
