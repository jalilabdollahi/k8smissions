## Removing the taint from the node

That makes the pods stable, but the maintenance window is a platform decision and the taint protects the rest of the node during it. Fix the workload's side of the contract.

## Dropping the nodeSelector so the pods land elsewhere

The cache files live on the NVMe node. Pods on another worker start with a cold cache, which is the outage you were trying to avoid.

## Adding a second toleration and expecting it to win

Several tolerations can match one taint. Check the Deployment's pod template after the edit (`kubectl get deploy -o yaml`) and make sure no matching toleration still carries a short timer, then watch that the new pods get past 20 seconds.
