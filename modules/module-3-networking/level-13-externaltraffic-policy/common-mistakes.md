## Switching the Service to `Cluster`

Both nodes answer, so it looks fixed, but the caller address becomes a node address. The audit log is exactly why `Local` was chosen; this fails the source-address check.

## Scaling the Deployment up

The extra pods obey the same affinity and land on the same worker. More replicas on one node do not help the other node.

## Using required `podAntiAffinity`

It separates the pods, but during the rolling update the old pods still match the label, so the second new pod can stay Pending and the rollout stalls. A topology spread constraint avoids this; otherwise you must delete the old pods yourself.

## Pinning pods to nodes by name

It would work today and break the next time a node is replaced. Express the intent (one per node) with spread constraints instead.
