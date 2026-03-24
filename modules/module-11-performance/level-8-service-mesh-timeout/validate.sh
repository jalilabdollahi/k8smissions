#!/bin/bash
set -euo pipefail
NS="k8smissions"
TIMEOUT=$(kubectl get virtualservice backend-vs -n k8smissions -o jsonpath='{.spec.http[0].timeout}' 2>/dev/null || true)
if [ -n "$TIMEOUT" ] && [ "$TIMEOUT" != "15s" ]; then
  echo "PASS: Silent Timeout"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
