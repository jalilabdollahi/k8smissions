## What was broken

`ledger-api` has two replicas and a PodDisruptionBudget that demands `minAvailable: 2`. The budget therefore allows zero voluntary disruptions, and `kubectl drain`, which removes pods through the eviction API, was refused for every `ledger-api` pod on the node.

## The evidence

The drain printed `Cannot evict pod as it would violate the pod's disruption budget` over and over. `get pdb` showed `ALLOWED DISRUPTIONS 0`, and `describe pdb` listed the current and desired healthy counts as equal.

## Why Kubernetes behaves this way

A PDB limits *voluntary* disruptions: drains, upgrades, autoscaler scale-downs. It does not stop crashes or node failures. The eviction endpoint checks `disruptionsAllowed` before deleting a pod; at zero it answers 429 and `kubectl drain` waits and retries. That is the PDB doing its job, but the budget here was impossible to satisfy.

## The fix

Make the budget leave headroom: `minAvailable: 1` for two replicas (or a third replica with `minAvailable: 2`). Pods are then evicted one at a time and the next one is only evicted when its replacement is Ready, so the Service never loses capacity.

## In production

Choose the budget together with the replica count and the number of nodes. `--disable-eviction` and deleting the PDB make the drain succeed by dropping the protection, and the validator watches the Service to catch that. Module 11 looks at budgets that stall whole cluster upgrades.

## Commands worth remembering

- `kubectl get pdb`
- `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`
- `kubectl uncordon <node>`
