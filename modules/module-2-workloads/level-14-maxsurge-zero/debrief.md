# The Unmovable Update

## What Was Broken
The Deployment's RollingUpdate strategy had `maxSurge: 0` AND `maxUnavailable: 0`. Kubernetes validates this combination: the rollout controller cannot create new pods (maxSurge=0) and cannot kill old pods (maxUnavailable=0), so no progress is possible.

## The Fix
Set at least one of `maxSurge` or `maxUnavailable` to a value greater than zero. Classic safe-rollout config: `maxSurge: 1, maxUnavailable: 0` — spin up one extra, then drain one old pod.

## Why It Matters
maxSurge and maxUnavailable can be integers or percentages. `maxSurge: 25%` on a 4-replica deployment means at most 1 extra pod. Default values are `maxSurge: 25%` and `maxUnavailable: 25%` — both zero is only reachable by explicitly setting them.

## Pro Tip
Recreate strategy (`strategy.type: Recreate`) kills all pods before creating new ones. Use for stateful apps that can't run two versions simultaneously. Zero downtime isn't possible with Recreate.

## Concepts
Deployment, RollingUpdate, maxSurge, maxUnavailable, rollout strategy
