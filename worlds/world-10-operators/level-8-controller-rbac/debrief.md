# Permission Denied in Controller

## What Was Broken
The operator's ClusterRole only granted permissions on the CRD's apiGroup (example.com/workloads). To reconcile the CR, the operator needed to create Deployments, Pods, and Services — for which it had no permissions.

## The Fix
Add RBAC rules for all Kubernetes resources the operator creates or manages.

## Why It Matters
Operator RBAC checklist: the CRD's apiGroup (create/update CR status), the native resources it manages (Deployments, Services, ConfigMaps, Secrets), Events (for status reporting), plus the operator's own namespace if namespace-scoped.

## Pro Tip
Use controller-gen RBAC markers in Go code: //+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete. These auto-generate the ClusterRole from code annotations.

## Concepts
RBAC, ClusterRole, ServiceAccount, operator permissions, forbidden
