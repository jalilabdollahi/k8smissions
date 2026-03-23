# Common Mistakes — The Orphan

## Mistake 1: Deleting pods individually

**Wrong approach:** Deleting each pod one by one — the ReplicaSet immediately recreates them

**Correct approach:** Delete the ReplicaSet itself; it cascades and removes pods

## Mistake 2: Scaling RS to 0 instead of deleting

**Wrong approach:** kubectl scale rs legacy-app-7d8f9 --replicas=0 hides the problem but keeps the RS

**Correct approach:** Delete the RS entirely to truly remove it from the cluster
