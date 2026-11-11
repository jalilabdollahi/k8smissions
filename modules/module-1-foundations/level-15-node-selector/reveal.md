1. `kubectl describe pod cache-warm` says `didn't match Pod's node affinity/selector`; the selector is `disktype=ssd`.
2. `kubectl get nodes --show-labels` shows the SSD worker carries `disk=ssd` and the other `disk=hdd`; no node has `disktype`.
3. A pod's nodeSelector is immutable, so export the pod, change the key to `disk`, delete the pod and apply it again.
4. Labelling a node `disktype=ssd` also makes the pod schedulable, but labelling the HDD node would put the cache on the slow disk, which the check rejects.
