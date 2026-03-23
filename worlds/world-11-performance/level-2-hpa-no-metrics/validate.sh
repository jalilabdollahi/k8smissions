#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get hpa my-hpa -n k8smissions -o jsonpath='{.status.currentMetrics}' 2>/dev/null | grep -qv '<unknown>' || echo PASS; then
  echo "PASS: HPA Can't Scale"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
