## What was broken

ConfigMap `export-lock` had been deleted, but carried a finalizer, `backup.acme.io/release`, placed by a backup operator. The operator was uninstalled, so the cleanup it was supposed to perform, and the removal of its finalizer, never happened. The object stayed in `Terminating` with its old data, and its name stayed taken, so creating a new `export-lock` failed.

## The evidence

`kubectl get configmap export-lock -o yaml` showed `metadata.deletionTimestamp` (the delete was requested) and `metadata.finalizers` with the operator's key. `kubectl delete` and `kubectl delete --force --grace-period=0` printed success and changed nothing, and `kubectl create` said the object already exists or is being deleted.

## Why Kubernetes behaved this way

Deleting an object that has finalizers only sets `deletionTimestamp`. The object is kept until every finalizer has been removed, which is how controllers get a chance to release external resources first. Force and grace period concern pods and the kubelet; they do not bypass finalizers. If the controller is gone, the object waits forever.

## The fix

Confirm the finalizer's owner no longer exists and that nothing external needs releasing, then clear it: `kubectl patch configmap export-lock --type=merge -p '{"metadata":{"finalizers":null}}'`. The object vanishes immediately and a new `export-lock` with `owner=billing` can be created.

## In production

Removing a finalizer by hand is a last resort: whatever the controller would have cleaned up (volumes, DNS records, cloud resources) is left behind. Uninstall operators in the right order: delete their custom resources first, then the operator. The same pattern explains namespaces stuck in `Terminating`.

## Commands worth remembering

- `kubectl get <kind> <name> -o jsonpath='{.metadata.finalizers}'`
- `kubectl patch <kind> <name> --type=merge -p '{"metadata":{"finalizers":null}}'`
- `kubectl get all,cm -A | grep Terminating`
