#!/bin/bash
set -euo pipefail
NS="k8smissions"
MIN=$(kubectl get hpa api-hpa -n "$NS" -o jsonpath='{.spec.minReplicas}' 2>/dev/null || true)
MAX=$(kubectl get hpa api-hpa -n "$NS" -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || true)
if [ -n "$MIN" ] && [ -n "$MAX" ] && [ "$MIN" -le "$MAX" ]; then
  echo "PASS: HPA minReplicas=$MIN <= maxReplicas=$MAX"
  exit 0
fi
echo "FAIL: minReplicas=$MIN maxReplicas=$MAX (min must be <= max)"
exit 1
