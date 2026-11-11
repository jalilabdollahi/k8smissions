## What was broken

The Deployment's node affinity had a single term with two expressions: `disktype In [ssd, nvme]` and `drain-pending DoesNotExist`. The only SSD worker still had the label `drain-pending=true` from a maintenance cycle that ended a week ago, and the other worker has an HDD, so no node passed the term.

## The evidence

The Deployment YAML looked correct for an SSD node, and `disktype=ssd` was indeed on the node. The failure only showed once `kubectl get nodes -L disktype,drain-pending` put the labels next to each other. The scheduler's message, `didn't match Pod's node affinity/selector`, said nothing about which expression failed.

## Why Kubernetes behaves this way

Expressions inside one `matchExpressions` list are ANDed; each entry in `nodeSelectorTerms` is an alternative (OR). Labels are plain data with no owner or expiry, so a label that a runbook added and never removed keeps vetoing pods indefinitely. Affinity is evaluated on the node's current labels, which is why removing the label unblocks pods without touching the Deployment.

## The fix

Remove the stale label from the node. Rewriting the pod's term would also pass, but would leave the node advertising a drain that is not happening, which might block the next consumer too. Relabelling the HDD node as SSD would lie about the hardware.

## In production

Maintenance runbooks that add a label need a matching removal step, ideally in the same script. Check `kubectl get nodes --show-labels` when pods are Pending but their manifests look right, and consider taints (with an effect and a clear lifecycle) for "do not use" states.

## Commands worth remembering

- `kubectl get nodes -L disktype,drain-pending`
- `kubectl label node <node> <key>-`
- `kubectl explain pod.spec.affinity.nodeAffinity`
