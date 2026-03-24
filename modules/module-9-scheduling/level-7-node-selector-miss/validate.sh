#!/bin/bash
set -euo pipefail
NS="k8smissions"
NODE_SELECTOR=$(kubectl get pod gpu-pod -n "$NS" -o jsonpath='{.spec.nodeSelector}' 2>/dev/null || true)
if [ -z "$NODE_SELECTOR" ] || ! echo "$NODE_SELECTOR" | grep -q 'accelerator-type'; then
  echo "PASS: Label Not Found"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
