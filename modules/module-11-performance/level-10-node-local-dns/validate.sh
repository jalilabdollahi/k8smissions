#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get configmap node-local-dns -n kube-system -o jsonpath='{.data.enabled}' 2>/dev/null | grep -q 'true'; then
  echo "PASS: DNS Latency Spike"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
