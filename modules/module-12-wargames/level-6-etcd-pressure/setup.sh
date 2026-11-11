#!/bin/bash
# A deploy tool that keeps unlimited history (24 releases, ~330 KiB each) and a syncer that lists Secrets every 250 ms.
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh

kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: release-deployer
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: config-syncer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: release-deployer
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "create", "patch", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: config-syncer
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: release-deployer
subjects:
- {kind: ServiceAccount, name: release-deployer}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: release-deployer}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: config-syncer
subjects:
- {kind: ServiceAccount, name: config-syncer}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: config-syncer}
YAML

# 24 releases of the shop: 1..23 superseded, 24 deployed. Each carries a ~250 KiB rendered manifest.
for i in $(seq 1 24); do
  st=superseded; [ "$i" = 24 ] && st=deployed
  head -c 190000 /dev/urandom | base64 | tr -d '\n' > /tmp/k8sm-release-$$.txt
  kubectl -n "$NS" create secret generic "sh.release.v1.shop.v$i" --from-file=release=/tmp/k8sm-release-$$.txt >/dev/null || exit 1
  kubectl -n "$NS" label secret "sh.release.v1.shop.v$i" owner=release-deployer app=shop status=$st revision=$i >/dev/null
done
rm -f /tmp/k8sm-release-$$.txt
