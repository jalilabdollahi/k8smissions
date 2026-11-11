**What was broken.** The Application `ledger-api` targets namespace `ledger-prod`, which nobody had created. Argo CD's sync tried to apply the Deployment and Service into it, got "namespace not found", and ended with `operationState.phase: Failed`. The Application has manual sync, so nothing retried, and the status stayed `OutOfSync` with nothing running.

**The evidence.** `kubectl -n argocd get app ledger-api -o yaml` has `status.operationState` with the phase, the message and the per-resource sync results. `kubectl get ns` confirmed the missing namespace.

**Why Argo behaved this way.** Argo CD only creates the destination namespace if the sync options include `CreateNamespace=true`; otherwise it treats a missing namespace as an error, so a typo in a destination does not silently create a new namespace. A sync is an `operation` on the Application object: with automated sync the controller creates it for you, with manual sync somebody must (`argocd app sync`, the UI, or a patch like the one here). A refresh alone only re-compares Git with the cluster.

**The fix.** Either add `CreateNamespace=true` to `spec.syncPolicy.syncOptions` (and request a sync), or create the namespace yourself and request a sync. The option is the better choice when the namespace should be part of the Application's definition.

**In production.** Prefer automated sync with `retry` for apps that should always converge, and keep namespaces (with quotas and labels) in Git or use `managedNamespaceMetadata` so the namespace Argo creates carries the right labels.

**Commands worth remembering.**
- `kubectl get app NAME -n argocd -o yaml` (status, conditions, operationState)
- `kubectl annotate app NAME -n argocd argocd.argoproj.io/refresh=hard --overwrite`
- `kubectl patch app NAME -n argocd --type merge -p '{"operation":{"sync":{}}}'`
