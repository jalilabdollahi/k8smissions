## What was broken

`site-operator` built `ownerReferences` from a constant uid that was copied from one particular Site when the code was written. For the Deployment and ConfigMap of every other Site the reference pointed at an owner that does not exist, and the Service got no reference at all. The two faults look unrelated: children that vanish, and a child that never goes away.

## The evidence

`kubectl get deploy site-storefront -o jsonpath='{.metadata.ownerReferences}'` showed a `uid` that matches no Site. `kubectl get site storefront -o jsonpath='{.metadata.uid}'` gave another. `kubectl get deploy -w` showed `site-*` Deployments being created again every few seconds, and the Service had `ownerReferences: null`.

## Why Kubernetes behaved this way

The garbage collector builds a graph from `ownerReferences`. When it processes a dependent it checks, for each owner, whether an object with that `kind`, `name` and `uid` exists. A live object with a different uid does not count: it is a different incarnation, so the dependent is deleted. This protects against deleting a Site and recreating it and inheriting its children by accident. An object without references is never touched, which is why the Service leaked and why deleting the Site left it behind.

## In production

Never hand-write uids: take them from the live parent (`controllerutil.SetControllerReference` does it). Set `controller: true` and `blockOwnerDeletion: true` for a clean foreground delete. For cross-namespace or cluster-scoped owners, ownerReferences are not allowed; use finalizers instead. Orphans left by buggy operators have to be found (`kubectl get svc -A -o json | jq` for missing owners) and cleaned up by hand.

## Worth remembering

- `kubectl get <kind> <name> -o jsonpath='{.metadata.ownerReferences}'`
- `kubectl delete <cr> --cascade=foreground` waits for the children; `--cascade=orphan` leaves them.
- `kubectl get <kind> -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].name`
