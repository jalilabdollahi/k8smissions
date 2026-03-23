#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod gpu-pod -n k8smissions -o jsonpath='{.spec.nodeSelector}' 2>/dev/null | grep -qv accelerator-type || kubectl get pod gpu-pod -n k8smissions -o jsonpath='{.status.phase}' 2>/dev/null | grep -q Running; then
  echo "PASS: Label Not Found"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
