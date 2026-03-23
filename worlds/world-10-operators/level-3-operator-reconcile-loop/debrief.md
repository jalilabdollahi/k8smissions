# Stuck Reconciliation

## What Was Broken
The operator deployment had WATCH_NAMESPACE=operators, restricting the watch to its own namespace. The CR was in 'k8smissions' — invisible to the controller. No reconciliation events were generated.

## The Fix
Set WATCH_NAMESPACE to empty string for cluster-wide operation, or to the correct namespace.

## Why It Matters
Operator namespace scope: empty WATCH_NAMESPACE = cluster-wide (needs ClusterRole). Specific namespace = namespace-scoped (needs Role). Most operators support both modes. Cluster-wide is powerful but risky — prefer namespace-scoped for multi-tenant clusters.

## Pro Tip
Check what the operator is reconciling: kubectl logs -n operators deploy/my-operator | grep reconcile. Well-written operators log reconciliation start/end for every CR event.

## Concepts
operator, WATCH_NAMESPACE, controller scope, reconciliation, namespace isolation
