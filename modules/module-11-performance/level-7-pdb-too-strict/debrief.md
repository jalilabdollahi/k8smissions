**What was broken.** Both workloads had a PodDisruptionBudget whose minimum equals the number of replicas: `minAvailable: 3` for 3 API pods, `minAvailable: 1` for the single cache pod. A budget like that says "never evict anything", and a node drain is a series of evictions.

**The evidence.** `kubectl get pdb` showed `ALLOWED DISRUPTIONS 0` for both budgets, and the drain printed `Cannot evict pod as it would violate the pod's disruption budget` on repeat. Allowed disruptions is simply (currently healthy pods) minus (pods the budget wants to keep), so any budget whose minimum equals the replica count is a drain-blocker.

**Why Kubernetes behaved this way.** `kubectl drain` does not delete pods, it asks the API server to evict them. The eviction API checks the budget and answers 429 if the eviction would break it, and drain keeps retrying. Budgets only apply to voluntary disruptions like drains and upgrades, which is exactly why this surfaces during maintenance rather than during normal operation.

**The fix.** The two workloads need different answers. The API has three pods: `maxUnavailable: 1` (or `minAvailable: 2`) still protects it, because two pods keep serving while one moves. The cache has one pod, so a budget alone cannot keep it up while the node is drained: either run two replicas with `minAvailable: 1`, or accept that the single pod is briefly unavailable with a budget that allows one disruption.

**In production.** Prefer `maxUnavailable` over `minAvailable` because it keeps working when the replica count changes (HPA). Never set a budget equal to the replica count; alert on `ALLOWED DISRUPTIONS = 0`. Anything with a single replica and a strict budget will block your next cluster upgrade.

**Worth remembering.**
- `kubectl get pdb`
- `kubectl describe pdb <name>`
- `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`
