**Restarting or scaling the Deployment.** `kubectl rollout restart` and extra replicas re-run the scheduler against a rule that excludes nothing, so pods may land together again. Fix the rule first, then check placement.

**Adding a PodDisruptionBudget.** A PDB limits voluntary evictions such as drains; it does not influence where pods are placed and does not stop a node from failing.

**Pinning pods with nodeName or nodeSelector.** It would force them apart today, but it removes the scheduler's ability to reschedule when a node is lost, which is the capability this drill is testing.
