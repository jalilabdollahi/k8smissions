#!/bin/bash
set -euo pipefail
NS="k8smissions"
SUCCEEDED=$(kubectl get job db-init -n "$NS" -o jsonpath='{.status.succeeded}' 2>/dev/null || true)
if [ "$SUCCEEDED" = "1" ]; then
  echo "PASS: Job completed successfully"
  exit 0
fi
echo "FAIL: Job succeeded=$SUCCEEDED"
exit 1
