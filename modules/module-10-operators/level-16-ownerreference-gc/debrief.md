# Orphaned Resources

## What Was Broken
The operator created Deployments and Services without setting ownerReferences. Kubernetes garbage collection only cleans up resources where the owner UID exists. Without ownerReferences, deleting the CR left the child resources running.

## The Fix
Set ownerReferences on all resources created by the operator, pointing to the managing CR with controller: true.

## Why It Matters
ownerReferences for cross-namespace is not supported — owner and owned resources must be in the same namespace. For cluster-scoped resources (like ClusterRoles) owned by namespace-scoped CRs, use finalizers for cleanup.

## Pro Tip
In controller-runtime: use ctrl.SetControllerReference(myapp, deployment, r.Scheme) to automatically set ownerReferences correctly including the UID and GVK.

## Concepts
ownerReferences, garbage collection, cascading delete, operator, resource lifecycle
