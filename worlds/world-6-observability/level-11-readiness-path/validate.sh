#!/bin/bash
set -euo pipefail
NS="k8smissions"
READY=$(kubectl get deployment web-app -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
PATH_VAL=$(kubectl get deployment web-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)
if [ "${READY:-0}" -ge 1 ] || [ "$PATH_VAL" = "/" ]; then
  echo "PASS: Readiness probe path=$PATH_VAL ready=$READY"
  exit 0
fi
echo "FAIL: readinessProbe.path=$PATH_VAL readyReplicas=$READY"
exit 1
