#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod large-pod -n k8smissions -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null | grep -qv 100Gi; then
  echo "PASS: No Room"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
