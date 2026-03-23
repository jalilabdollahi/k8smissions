#!/bin/bash
set -euo pipefail
NS="k8smissions"
NON_ROOT=$(kubectl get pod insecure-pod -n "$NS" -o jsonpath='{.spec.securityContext.runAsNonRoot}' 2>/dev/null || true)
UID=$(kubectl get pod insecure-pod -n "$NS" -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null || true)
if [ "$NON_ROOT" = "true" ] && [ -n "$UID" ] && [ "$UID" != "0" ]; then
  echo "PASS: Pod runs as non-root UID $UID"
  exit 0
fi
echo "FAIL: runAsNonRoot=$NON_ROOT runAsUser=$UID"
exit 1
