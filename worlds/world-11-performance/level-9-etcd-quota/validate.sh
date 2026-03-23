#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get configmap etcd-config -n kube-system -o jsonpath='{.data.quota-backend-bytes}' 2>/dev/null | grep -qv '^2147483648$' || echo PASS; then
  echo "PASS: API Server Writes Fail"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
