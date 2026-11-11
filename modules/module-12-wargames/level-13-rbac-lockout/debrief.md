**What was broken.** The rotation moved the ServiceAccount but not everything that referred to it. Four references were stale or missing: the Deployment named the deleted `ledger-sync-v1`, the new account had token mounting switched off, the `pod-reader` RoleBinding still listed v1 as its subject, and the new account had no binding at all in `platform-config`, where the settings are published.

**The evidence.** `describe rs` printed `serviceaccount "ledger-sync-v1" not found`. After the first fix the log said `no service account token mounted in this pod`; then `HTTP 403 Forbidden` for the pod list, and finally 403 only for the ConfigMap. `kubectl auth can-i ... --as=system:serviceaccount:k8smissions:ledger-sync-v2` turned each 403 into a yes or no without touching the app.

**Why Kubernetes behaved this way.** ServiceAccount admission rejects pods that name a missing account, so the ReplicaSet creates nothing and there are no pods to debug. RBAC is additive and bound by subject name: a binding to a deleted account is simply inert, and a Role grants rights only inside its own namespace, so every extra namespace needs a RoleBinding (or a ClusterRole bound there).

**The fix.** Point the Deployment at v2, mount the token, retarget the existing binding, and add a binding in the second namespace. A ServiceAccount token is mounted when a pod is created, so the pods started before the `automountServiceAccountToken` change must be restarted. Each change is minimal and the account keeps no more than get/list pods and one ConfigMap.

**In production.** Rotate accounts by creating the new one, switching consumers, and only then deleting the old one; grep RoleBindings for the old name first. Prefer `automountServiceAccountToken: false` on accounts that do not call the API, and true only where needed.

**Commands to remember.** `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa> -n <ns>`, `kubectl get rolebinding -A -o wide`, `kubectl set serviceaccount`.
