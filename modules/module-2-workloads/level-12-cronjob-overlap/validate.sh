#!/bin/bash
set -euo pipefail
NS="k8smissions"
POLICY=$(kubectl get cronjob data-processor -n "$NS" -o jsonpath='{.spec.concurrencyPolicy}' 2>/dev/null || true)
if [ "$POLICY" = "Forbid" ] || [ "$POLICY" = "Replace" ]; then
  echo "PASS: concurrencyPolicy=$POLICY prevents flooding"
  exit 0
fi
echo "FAIL: concurrencyPolicy=$POLICY"
exit 1
