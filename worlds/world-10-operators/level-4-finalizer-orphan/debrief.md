# Orphaned Controller

## What Was Broken
The operator had a finalizer 'database.example.com/cleanup'. When the CR was deleted, the operator's cleanup reconciliation ran but due to a bug, it didn't clean the backend resources. The finalizer was never cleared — resource stuck Terminating.

## The Fix
Fix the operator's cleanup logic to properly clean backend resources and clear the finalizer. For stuck finalizers in emergencies, manually patch them away.

## Why It Matters
Finalizer lifecycle: controller adds finalizer on creation → resource blocked from deletion until finalizer removed → controller runs cleanup on deletionTimestamp set → controller removes finalizer → resource deleted. Missing any step causes a stuck resource.

## Pro Tip
Use ownerReferences instead of finalizers for Kubernetes-native resources. When the CR is deleted with cascading garbage collection enabled, owned resources are automatically cleaned up without explicit operator cleanup code.

## Concepts
finalizers, deletionTimestamp, cleanup, orphaned resources, ownerReferences
