## What was broken

The PodDisruptionBudget `consul-pdb` existed and had a sensible `minAvailable: 2`, but its selector said `concul`. It matched no pods, so it protected nothing, and a drain evicted two members at once. `kubectl get pdb` already showed the symptom: `ALLOWED DISRUPTIONS 0` with nothing healthy behind it.

## Evidence

`kubectl describe pdb` / `get pdb -o yaml` show `expectedPods: 0` and `currentHealthy: 0`; `get pods --show-labels` shows the real label. A selector that matches no pods is not an error, it simply selects the empty set.

## Why Kubernetes behaved this way

The eviction API checks the budgets that select the pod. A pod that no budget selects can be evicted freely. Once the selector matches, the disruption controller computes `disruptionsAllowed = currentHealthy - desiredHealthy`: 3 - 2 = 1 here. A drain evicts one member, waits until it is back Ready and the budget allows the next.

## The fix

Correct the selector label. Keep `minAvailable: 2` (or use `maxUnavailable: 1`): both give exactly one allowed disruption for 3 pods. `minAvailable: 3` after the fix would block all voluntary evictions and stall node maintenance.

## In production

PDBs only guard voluntary disruptions (drain, eviction, autoscaler): a node crash ignores them. Always check `expectedPods` after creating one, and prefer selecting by the same labels as the controller's selector. For stateful quorum systems also use an ordered rollout and anti-affinity so that two members never share a node.

## Commands worth remembering

- `kubectl get pdb` and `kubectl describe pdb <name>`
- `kubectl get pods --show-labels`
- `kubectl drain <node> --ignore-daemonsets --dry-run=server`
