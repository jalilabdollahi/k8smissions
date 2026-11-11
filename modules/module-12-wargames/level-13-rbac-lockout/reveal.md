Four faults, found in this order:

1. The Deployment still uses `serviceAccountName: ledger-sync-v1`, which was deleted, so the ReplicaSet cannot create pods (`FailedCreate: serviceaccount not found`). `kubectl set serviceaccount deploy/ledger-sync ledger-sync-v2`.
2. `ledger-sync-v2` was created with `automountServiceAccountToken: false`, so pods run without a token. `kubectl patch sa ledger-sync-v2 -p '{"automountServiceAccountToken":true}'` (setting it in the pod spec also works). Pods that were created before the change keep running without a token, so finish with `kubectl rollout restart deploy/ledger-sync`.
3. RoleBinding `ledger-sync-pods` still names `ledger-sync-v1` as subject. Patch the subject name to `ledger-sync-v2` (the roleRef cannot be edited, the subject can).
4. The settings ConfigMap lives in `platform-config`, where Role `settings-reader` exists with no binding. Create one: `kubectl -n platform-config create rolebinding ledger-sync-settings --role=settings-reader --serviceaccount=k8smissions:ledger-sync-v2`.

Binding `cluster-admin` would make every error disappear and fails the least-privilege check.
