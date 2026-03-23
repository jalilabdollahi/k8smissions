# Zombie Namespace

## What Was Broken
The namespace had a `kubernetes` finalizer waiting for all objects inside to be cleaned up. A ConfigMap with `some.controller.io/cleanup` finalizer was never cleared (its operator was already deleted). The object blocked namespace deletion indefinitely.

## The Fix
Clear the finalizer on every stuck object inside the namespace. Once all objects have empty finalizers, Kubernetes finishes removing them and the namespace finalizer resolves automatically.

## Why It Matters
Stuck namespaces are a classic Kubernetes ops problem. The most powerful tool: `kubectl get api-resources --verbs=list --namespaced -o name | xargs -I{} kubectl get {} -n <ns> --ignore-not-found 2>/dev/null` to list every object type. Then filter by finalizers.

## Pro Tip
The nuclear option: `kubectl patch namespace zombie-ns -p '{"metadata":{"finalizers":null}}' --type=merge` removes the namespace finalizer directly. This can leave orphaned objects in etcd. Use only when all objects are confirmed gone.

## Concepts
namespace, Terminating, finalizers, garbage collection, operator cleanup
