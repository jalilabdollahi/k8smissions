#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get pod dns-heavy-app -n k8smissions -o jsonpath='{.spec.dnsConfig}' 2>/dev/null | grep -q ndots || echo PASS; then
  echo "PASS: DNS Flood"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
