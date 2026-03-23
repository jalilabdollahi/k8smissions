#!/bin/bash
set -euo pipefail
NS="k8smissions"
CPU_LIMIT=$(kubectl get deployment api-server -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null || true)
if [ -n "$CPU_LIMIT" ] && [ "$CPU_LIMIT" != "100m" ]; then
  echo "PASS: Latency Spikes"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
