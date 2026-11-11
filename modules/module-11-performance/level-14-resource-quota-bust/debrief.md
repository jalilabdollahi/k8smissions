**What was broken.** `payments-web` was stuck at its old pods on every release. Its Deployment demanded a surge pod (`maxSurge: 1`, `maxUnavailable: 0`) of 280m CPU, while the namespace quota of 1500m already had 1370m reserved by the four steady pods and a forgotten `batch-reprocess`.

**The evidence.** `kubectl describe rs` on the new ReplicaSet shows `FailedCreate ... exceeded quota: compute, requested: requests.cpu=280m, used: 1370m, limited: 1500m`. `kubectl describe quota compute` shows how little is left, and `kubectl top pod` shows `payments-web` using a few millicores of the 280m it reserves. Nodes had plenty of free CPU: the quota is an admission limit, not a node limit.

**Why Kubernetes behaved this way.** ResourceQuota is checked when a pod is created and counts requests, not usage. Steady state fits; the rolling update needs headroom that only exists during the release, so the failure only appears on deploy day. The rollout controller cannot remove an old pod first because `maxUnavailable` is 0.

**The fix.** Make the release fit under the same quota: right-size the request, or set `maxSurge: 0` so each pod is replaced in place, or free capacity from an idle workload with its owner's agreement. All three are valid; raising the quota is the one thing ruled out here.

**In production.** Review requests against observed usage regularly (VPA in recommendation mode helps), leave roughly one surge's worth of headroom in any quota used for rolling updates, and alert on `kube_resourcequota` usage ratio above 80%.

**Worth remembering.**
- `kubectl describe quota <name>`
- `kubectl describe rs <name>` (events at the bottom)
- `kubectl top pod --containers`
