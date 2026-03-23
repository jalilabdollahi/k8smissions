#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod app-pod -n k8smissions -o jsonpath='{.spec.affinity.podAffinity}' 2>/dev/null | grep -q preferred; then
  echo "PASS: Chicken and Egg"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
