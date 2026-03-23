# Common Mistakes — The Undeletable Object

## Mistake 1: Using --force --grace-period=0

**Wrong approach:** kubectl delete configmap stuck-config --force --grace-period=0 does NOT remove finalizers

**Correct approach:** Finalizers must be patched out; --force only skips graceful termination

## Mistake 2: Redeploying the operator to clear the finalizer

**Wrong approach:** Redeploying the operator just to run its cleanup — risky when the object is in a bad state

**Correct approach:** Directly patch the finalizer to [] when the operator is gone
