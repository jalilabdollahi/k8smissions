1. `kubectl -n k8smissions describe rs -l app=reports` shows `FailedCreate ... serviceaccount "reports-sa" not found`.
2. `kubectl -n k8smissions create serviceaccount reports-sa` creates the account the pod template names.
3. The ReplicaSet controller retries by itself; `kubectl -n k8smissions rollout status deployment/reports` waits until all three pods are available.

Removing `serviceAccountName` from the Deployment would also work (pods would run as `default`), but then the change rolls out a new template instead of just unblocking the existing one.
