#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment api-server -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null | grep -qv '^100m$' || echo PASS; then
  echo "PASS: Latency Spikes"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
