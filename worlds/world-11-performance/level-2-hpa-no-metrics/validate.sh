#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment metrics-server -n kube-system 2>/dev/null | grep -q metrics-server && \
   kubectl get hpa my-hpa -n k8smissions 2>/dev/null | grep -q my-hpa; then
  echo "PASS: HPA Can't Scale"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
