#!/bin/bash
NS=k8smissions
# 1. pods could not be created: the Deployment still names the deleted v1 account
kubectl -n $NS set serviceaccount deploy/ledger-sync ledger-sync-v2
# 2. v2 was created with automountServiceAccountToken: false, so pods get no token
kubectl -n $NS patch sa ledger-sync-v2 -p '{"automountServiceAccountToken":true}'
# 3. the binding for pod-reader still points at v1
kubectl -n $NS patch rolebinding ledger-sync-pods --type=json -p='[{"op":"replace","path":"/subjects/0/name","value":"ledger-sync-v2"}]'
# 4. the settings live in another namespace and need their own binding there
kubectl -n platform-config create rolebinding ledger-sync-settings --role=settings-reader --serviceaccount=$NS:ledger-sync-v2
# pods created before the account was fixed have no token (and the old ones no right account): restart them
kubectl -n $NS rollout restart deploy/ledger-sync
kubectl -n $NS rollout status deploy/ledger-sync --timeout=120s
