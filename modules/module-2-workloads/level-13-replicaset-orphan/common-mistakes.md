## Deleting the v1 pods

The ownerless ReplicaSet still wants three replicas and creates new `v1` pods at once. You are removing the symptom, not the controller.

## Scaling the old ReplicaSet to zero

The traffic stops, but the ReplicaSet stays behind with no owner, ready to be scaled up again by mistake. The check requires the clutter to be gone.

## Deleting the new Deployment's ReplicaSet

Deployment `checkout` simply recreates it. Check the `OWNER` column first: the one without an owner is the ghost.
