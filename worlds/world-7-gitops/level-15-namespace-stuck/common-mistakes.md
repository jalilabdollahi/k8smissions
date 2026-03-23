# Common Mistakes — Zombie Namespace

## Mistake 1: Deleting the namespace again

**Wrong approach:** Re-running kubectl delete namespace — has no effect on an already-Terminating namespace

**Correct approach:** Find and clear the finalizers on objects inside the namespace

## Mistake 2: Removing the namespace finalizer directly without clearing object finalizers

**Wrong approach:** Patching namespace finalizers to null — may leave orphaned objects in etcd

**Correct approach:** Clear object finalizers first, then the namespace finalizer resolves naturally
