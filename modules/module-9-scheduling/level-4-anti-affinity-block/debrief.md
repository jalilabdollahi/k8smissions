## What was broken

`ledger-api` asked for 3 replicas and also demanded, with a required pod anti-affinity on `kubernetes.io/hostname`, that no two of its pods share a node. The cluster has two schedulable workers, so the third replica could never be placed.

## The evidence

`kubectl get pods -o wide` showed two Running pods on different nodes and one Pending. The FailedScheduling event counted the nodes: both workers failed on pod anti-affinity, the control plane on its taint. Plenty of CPU and memory was free, so resources were never the problem.

## Why Kubernetes behaves this way

`requiredDuringSchedulingIgnoredDuringExecution` is a filter. A node that violates it is not a candidate at all, no matter how empty it is. A `preferred` rule is only a score, so it spreads replicas when it can and gives way when it cannot.

## The fix

Relax the rule to `preferred` (or replace it with a `topologySpreadConstraints` entry with `maxSkew: 1`, which states the real goal, "even spread", better). Tolerating the control-plane taint would schedule the pod and break the workers-only rule; scaling to 2 would break the commitment.

## In production

Hard anti-affinity is right when the replica count is guaranteed to be below the node count, for example a quorum of 3 on a 5-node pool. Pair it with a topology spread that tolerates imbalance whenever replicas may outnumber nodes, and watch for it during node drains: a required rule turns every drain into a Pending pod. Existing pods' required rules also apply to new pods of the same Deployment, so a rolling update of a Deployment like this stalls or lands lopsided; this one uses `Recreate`, which is why the fix takes effect cleanly.

## Commands worth remembering

- `kubectl describe pod <pod> | grep -A5 Events`
- `kubectl get pods -o wide -l app=<name>`
- `kubectl explain pod.spec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution`
