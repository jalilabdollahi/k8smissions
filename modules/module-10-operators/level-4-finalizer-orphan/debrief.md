## What was broken

A finalizer is a promise: "do not really delete this object until I have cleaned up". `datastore-operator` kept the promise in the wrong order. On deletion it removed its own finalizer first, which lets the API server delete the Datastore immediately, and only then tried to clean up, by fetching the Datastore again to find the backend's name. The object was already gone, the lookup returned 404 and the cleanup quietly did nothing.

## The evidence

The operator log said it itself: "datastore ... not found, nothing to clean up", right after "released datastore ...". A scratch Datastore, created and deleted while watching the log and `kubectl get pods`, makes the sequence visible.

## Why Kubernetes behaved this way

While a finalizer is present, `kubectl delete` only sets `metadata.deletionTimestamp`; the object stays readable so its controller can act on it. The instant the last finalizer is removed, the object is deleted and its data is gone. Nothing in Kubernetes ties the finalizer to the cleanup: the controller must do the work first and remove the finalizer last. Also, a controller only reacts to objects it can still see, so something that leaked before the fix will never be revisited by new code.

## In production

Do cleanup with data you already hold (the object from the list, or names derived from it) and make it idempotent, so a crash between cleanup and release only repeats work. For plain in-cluster children, `ownerReferences` give you this for free through the garbage collector, and finalizers are for external resources (a cloud disk, a DNS record). Sweep for orphans with a label selector.

## Worth remembering

- `kubectl get <kind> <name> -o jsonpath='{.metadata.finalizers}'`
- `kubectl get pods,cm -l data.acme.io/store` finds backends by label
- Last resort for a stuck object: `kubectl patch <kind> <name> --type=merge -p '{"metadata":{"finalizers":null}}'` (and clean up by hand)
