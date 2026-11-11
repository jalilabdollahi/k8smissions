## What was broken

The old `checkout-v1` Deployment was removed with `--cascade=orphan`, which deletes only the Deployment and leaves its ReplicaSet and pods alive. The ReplicaSet kept three `v1` pods running, and because they carry `app=checkout`, Service `checkout` kept routing to them next to the new `v2` pods.

## The evidence

Half of the answers said `v1`. `get pods` showed pods that came back after each delete, `get pods -o yaml` pointed to a ReplicaSet owner, and that ReplicaSet's `ownerReferences` was empty, so no Deployment managed it any more.

## Why Kubernetes behaves this way

Owners and dependents are linked by `ownerReferences`. A normal delete cascades through them, but `--cascade=orphan` removes the links and keeps the dependents. An orphaned ReplicaSet is still a working controller: it counts pods by its selector and replaces any that go missing. Deleting pods is therefore pointless; delete the controller.

## The fix

Delete the ownerless ReplicaSet. The default cascade then removes its pods. The new Deployment never adopted them because its selector includes `track=stable`, which the old pods lack.

## In production

Use `--cascade=orphan` deliberately, for example to hand pods to another controller, and clean up afterwards. List ownerless objects with `get rs -o jsonpath` over `ownerReferences`, and keep Service selectors narrower than a single label shared across generations.

## Commands worth remembering

- `kubectl get rs -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].kind`
- `kubectl delete rs <name>`
- `kubectl delete deployment <name> --cascade=orphan`
