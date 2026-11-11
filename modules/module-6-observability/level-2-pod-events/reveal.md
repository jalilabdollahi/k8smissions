The pod template refers to service account `billing-sa`, which does not exist, so the API server refuses every pod the ReplicaSet tries to create.

1. `kubectl -n k8smissions describe rs -l app=billing-worker` shows `FailedCreate ... serviceaccount "billing-sa" not found`.
2. `kubectl -n k8smissions create serviceaccount billing-sa` creates it, with no RBAC.
3. The ReplicaSet retries by itself; `kubectl -n k8smissions rollout status deploy/billing-worker` waits for both pods.
