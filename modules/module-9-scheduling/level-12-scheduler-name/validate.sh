#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod ml-pod -n k8smissions -o jsonpath='{.spec.schedulerName}' 2>/dev/null | grep -q ml-scheduler; then
  echo "PASS: Wrong Scheduler"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
