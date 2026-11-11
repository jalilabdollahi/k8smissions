**What was broken.** Four faults stacked in the delivery chain, each hidden by the one before. The Application tracked `release-2.3`, a branch deleted after the release was cut, so Argo could not even resolve the source (`ComparisonError`). Then `valueFiles` named `values-prod.yml` while the file is `values-production.yaml`. Then the Deployment never came up because the tenant's ResourceQuota requires CPU and memory requests and the chart sets none: the ReplicaSet could not create pods. Finally, with pods running, the production values pointed the Service's `targetPort` at 8080 while the container listens on 5678.

**The evidence.** Each step had its own message: `status.conditions` of the Application, the Helm error naming the file, `FailedCreate` events on the ReplicaSet, and last, nothing at all except a `curl` from a probe pod failing while Endpoints looked fine.

**Why it behaved that way.** Argo CD's health is derived from the Deployment and Service objects' status. A Service whose targetPort is wrong still has ready endpoints, because readiness is checked on the container's real port. Green in Argo says "what Git describes was applied and the pods are Ready", not "users get answers".

**The fix.** Right revision, right file name, requests that fit the quota, correct targetPort. Prefer committing to Git over Application parameters; parameters in the Application hide configuration from the repository.

**In production.** Add a synthetic check from the user's side to every release, and keep `ignoreMissingValueFiles` for genuinely optional files only. Protect release branches or use tags so a source cannot vanish.

**Commands worth remembering.**
- `kubectl -n argocd get app NAME -o jsonpath='{.status.conditions[*].message}'`
- `helm template NAME PATH -f FILE | less`
- `kubectl get events --sort-by=.lastTimestamp`
