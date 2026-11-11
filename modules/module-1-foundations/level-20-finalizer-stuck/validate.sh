#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get configmap export-lock >/dev/null 2>&1; then
  echo "❌ ConfigMap export-lock does not exist"
  exit 1
fi
dt=$(k get configmap export-lock -o jsonpath='{.metadata.deletionTimestamp}')
if [ -n "$dt" ]; then
  echo "❌ ConfigMap export-lock is still being deleted (since $dt)"
  exit 1
fi
owner=$(k get configmap export-lock -o jsonpath='{.data.owner}')
if [ "$owner" != "billing" ]; then
  echo "❌ ConfigMap export-lock has owner=${owner:-<none>}, not billing"
  exit 1
fi
echo "✅ ConfigMap export-lock exists with owner=billing"

held=$(k get configmaps -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.finalizers}{"\n"}{end}' | grep -c 'backup.acme.io/release')
if [ "$held" != "0" ]; then
  echo "❌ $held object(s) are still held by the backup.acme.io finalizer"
  exit 1
fi
echo "✅ nothing in the namespace is held by the removed operator"
exit 0
exit 1
