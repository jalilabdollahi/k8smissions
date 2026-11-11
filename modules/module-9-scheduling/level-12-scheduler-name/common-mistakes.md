## Debugging the second scheduler's logs first

The scheduler is healthy and never sees the pods as its own, so its logs have nothing to say. When a pod has no events at all, ask who is supposed to be handling it before reading any scheduler log.

## Switching the pods to `default-scheduler`

They become Running, but the default scheduler spreads them and ignores the team's packing profile. The validator checks that `ml-scheduler` issued the placements.

## Editing the pods directly

`spec.schedulerName` cannot be changed on an existing pod, and the ReplicaSet would recreate any pod you delete from the same wrong template. Fix the Deployment.
