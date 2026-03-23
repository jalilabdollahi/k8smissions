# The Undeletable Object

## What Was Broken
The ConfigMap had a custom finalizer `custom.operator.io/cleanup`. Kubernetes deletion is two-phase: mark with `deletionTimestamp`, then wait for all finalizers to be cleared. If the owning controller is gone, the object is stuck forever.

## The Fix
Manually patch the finalizers to empty: `kubectl patch configmap stuck-config -n k8smissions -p '{"metadata":{"finalizers":[]}}' --type=merge`. Kubernetes then completes the deletion.

## Why It Matters
Finalizers prevent accidental deletion of objects with downstream dependencies. Common examples: `kubernetes.io/pvc-protection` on PVCs prevents deletion while pods still mount them. Stuck namespaces (Terminating forever) are almost always caused by finalizers on objects inside them.

## Pro Tip
A stuck namespace is hard to debug with `kubectl get all`. Use: `kubectl api-resources --verbs=list --namespaced -o name | xargs -I{} kubectl get {} -n <ns> 2>/dev/null` to list every object type.

## Concepts
finalizers, deletionTimestamp, garbage collection, object lifecycle, kubectl patch
