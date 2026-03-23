#!/bin/bash
set -euo pipefail
NS="k8smissions"
QUOTA=$(kubectl get configmap etcd-config -n kube-system -o jsonpath='{.data.quota-backend-bytes}' 2>/dev/null || true)
if [ -n "$QUOTA" ] && [ "$QUOTA" != "2147483648" ]; then
  echo "PASS: API Server Writes Fail"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
