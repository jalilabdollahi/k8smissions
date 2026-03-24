#!/bin/bash
set -euo pipefail
NS="k8smissions"
REPLICAS=$(kubectl get deployment resilient-app -n k8smissions -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
if [ -n "$REPLICAS" ] && [ "$REPLICAS" != "2" ]; then
  echo "PASS: Chaos Unready"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
