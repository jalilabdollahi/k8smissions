#!/bin/bash
set -euo pipefail
NS="k8smissions"
MODE=$(kubectl get pvc shared-pvc -n "$NS" -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null || true)
if [ "$MODE" = "ReadWriteMany" ]; then
  echo "PASS: PVC accessMode=ReadWriteMany"
  exit 0
fi
echo "FAIL: accessMode=$MODE (expected ReadWriteMany)"
exit 1
