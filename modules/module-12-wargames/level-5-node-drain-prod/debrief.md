**What was broken.** Draining the `maintenance=pending` worker ran into four separate things: a PodDisruptionBudget asking for 3 available pods out of 2 replicas, an unmanaged pod (`report-scratch`), a Deployment using `emptyDir` (`search`), and a taint on the only other worker that no pod tolerates.

**The evidence.** `kubectl drain` prints one blocker at a time: `Cannot evict pod as it would violate the pod's disruption budget`, then `cannot delete Pods declare no controller`, then `cannot delete Pods with local storage`. The first three are drain refusing to act; the fourth is silent. After a drain that finishes, `get pods` shows `checkout` and `search` pods Pending with `node(s) had untolerated taint {dedicated: batch}`.

**Why Kubernetes behaved this way.** Drain cordons the node and then evicts pods through the Eviction API, which respects PodDisruptionBudgets: with `minAvailable` above the replica count the allowed disruption is permanently 0. Pods with no owner would be lost forever and `emptyDir` data dies with the pod, so drain makes you say so explicitly. The scheduler never ignores taints, so a "successful" drain can still leave the workload without a home.

**The fix.** Make the budget satisfiable (`minAvailable: 1`), clear the stale taint before draining so replacements schedule, and drain with `--ignore-daemonsets --delete-emptydir-data --force`.

**In production.** Check capacity on the remaining nodes and their taints before a window; set PDBs as `maxUnavailable: 1`; put bare pods behind a Job or Deployment; use `--dry-run=server` first. Cordon first and drain with a `--timeout`.

**Commands to remember.** `kubectl drain --dry-run=server`, `kubectl get pdb`, `kubectl describe node <node> | grep -A3 Taints`.
