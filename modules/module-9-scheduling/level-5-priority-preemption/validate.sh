#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod critical-workload -n k8smissions -o jsonpath='{.spec.priorityClassName}' 2>/dev/null | grep -q high-priority; then
  echo "PASS: Queue Jumped"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
