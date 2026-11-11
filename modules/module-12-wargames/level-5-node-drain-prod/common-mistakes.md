**Deleting the PodDisruptionBudget.** The drain goes through immediately, but `checkout` has lost its protection for the next window and the validator reports it. Make the budget satisfiable (`minAvailable: 1` for 2 replicas) instead.

**Reaching for `--disable-eviction` or deleting pods by hand.** That bypasses the PDB check without fixing the budget and takes both `checkout` pods down at once if they happen to be on the node. Fix the object that is wrong and let eviction do its job.

**Stopping when the drain exits 0.** The node is empty, but `checkout` and `search` are Pending because the other worker has an untolerated taint. A drain only moves the problem; check `kubectl get pods -o wide` and the node taints, and verify that the Services answer.
