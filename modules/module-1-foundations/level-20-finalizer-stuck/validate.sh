#!/bin/bash
set -euo pipefail
NS="k8smissions"
if ! kubectl get configmap stuck-config -n "$NS" >/dev/null 2>&1; then
  echo "PASS: ConfigMap has been fully deleted"
  exit 0
fi
FINALIZERS=$(kubectl get configmap stuck-config -n "$NS" -o jsonpath='{.metadata.finalizers}' 2>/dev/null || true)
if [ -z "$FINALIZERS" ] || [ "$FINALIZERS" = "[]" ]; then
  echo "PASS: Finalizers cleared"
  exit 0
fi
echo "FAIL: ConfigMap still has finalizers: $FINALIZERS"
exit 1
