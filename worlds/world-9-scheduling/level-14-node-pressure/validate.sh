#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod memory-hog -n k8smissions -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null | grep -qv '2Gi'; then
  echo "PASS: Pressure Evictions"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
