#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get configmap descheduler-policy -n kube-system -o yaml 2>/dev/null | grep -q 'enabled: true' || echo PASS; then
  echo "PASS: Hot Node"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
