#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get networkpolicy restrictive-policy -n k8smissions -o jsonpath='{.metadata.annotations}' 2>/dev/null | grep -q cilium; then
  echo "PASS: Firewall Tax"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
