#!/bin/bash
# Recreate the state left by the uninstalled backup operator: an object that was deleted
# but is held by a finalizer nobody will ever clear.
kubectl -n "$NS" apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: export-lock
  namespace: k8smissions
  labels:
    k8smissions/managed: "true"
  finalizers:
  - backup.acme.io/release
data:
  owner: etl
YAML
kubectl -n "$NS" delete configmap export-lock --wait=false
for i in $(seq 1 10); do
  [ -n "$(kubectl -n "$NS" get configmap export-lock -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)" ] && exit 0
  sleep 1
done
echo "export-lock did not enter Terminating" >&2
exit 1
