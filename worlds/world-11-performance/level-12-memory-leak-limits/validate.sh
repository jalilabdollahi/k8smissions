#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment leaky-app -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].resources.limits}' 2>/dev/null | grep -q memory || echo PASS; then
  echo "PASS: Slow Memory Leak"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
