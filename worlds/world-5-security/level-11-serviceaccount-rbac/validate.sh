#!/bin/bash
set -euo pipefail
NS="k8smissions"
RB=$(kubectl get rolebinding config-reader-binding -n "$NS" 2>/dev/null && echo ok || echo missing)
if [ "$RB" = "ok" ]; then
  RESULT=$(kubectl auth can-i list configmaps -n "$NS" --as=system:serviceaccount:${NS}:config-reader-sa 2>/dev/null || true)
  if [ "$RESULT" = "yes" ]; then
    echo "PASS: ServiceAccount can list configmaps"
    exit 0
  fi
fi
echo "FAIL: ServiceAccount lacks configmap list permission"
exit 1
