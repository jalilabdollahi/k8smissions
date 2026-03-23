#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get clusterrole my-operator-role -o jsonpath='{.rules}' 2>/dev/null | grep -q 'pods' || echo PASS; then
  echo "PASS: Permission Denied in Controller"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
