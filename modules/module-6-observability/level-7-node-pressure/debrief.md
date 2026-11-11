## What was broken

The spooler appends 8 MiB segments to an emptyDir volume limited to 50Mi and, with `SPOOL_KEEP=0`, never removes old ones. After about six segments the directory passes the limit and the kubelet evicts the pod. The Deployment creates a replacement, which fills the volume and is evicted again.

## The evidence

`kubectl describe pod` on an Evicted pod shows `Status: Failed`, `Reason: Evicted` and a message `Usage of EmptyDir volume "spool" exceeds the limit "50Mi"`. `kubectl describe node` showed MemoryPressure, DiskPressure and PIDPressure all `False`. The app's first log line announced that retention was disabled.

## Why Kubernetes behaves this way

Eviction is not only a node-pressure response. The kubelet also enforces per-pod local-storage limits: an emptyDir `sizeLimit` and `ephemeral-storage` limits. A pod over its own limit is evicted even on an idle node. Evicted pods stay behind as Failed objects (for inspection) until garbage collection, which is why they pile up.

## The fix

Fix the cause, unbounded growth: turn on the app's retention so the spool stays far below the limit. Raising or removing `sizeLimit` only moves the failure to the node's disk, which can then cause real DiskPressure.

## In production

Spool to a PersistentVolume or ship segments off the pod, size limits from measured usage, and alert on the `Evicted` reason. Clean old Failed pods with `kubectl delete pod --field-selector=status.phase=Failed`.

## Commands worth remembering

- `kubectl describe pod <pod>` (Status, Reason, Message)
- `kubectl get pods --field-selector=status.phase=Failed`
- `kubectl describe node | grep -A8 Conditions`
