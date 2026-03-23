#!/bin/bash
set -euo pipefail
NS="k8smissions"
NON_ROOT=$(kubectl get pod insecure-pod -n "$NS" -o jsonpath='{.spec.securityContext.runAsNonRoot}' 2>/dev/null || true)
RUN_UID=$(kubectl get pod insecure-pod -n "$NS" -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null || true)
if [ "$NON_ROOT" = "true" ] && [ -n "$RUN_UID" ] && [ "$RUN_UID" != "0" ]; then
  echo "PASS: Pod runs as non-root UID $RUN_UID"
  exit 0
fi
echo "FAIL: runAsNonRoot=$NON_ROOT runAsUser=$RUN_UID"
exit 1
