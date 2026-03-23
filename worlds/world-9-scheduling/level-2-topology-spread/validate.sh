#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment ha-app -n k8smissions -o jsonpath='{.spec.template.spec.topologySpreadConstraints}' 2>/dev/null | grep -q maxSkew; then
  echo "PASS: Uneven Spread"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
