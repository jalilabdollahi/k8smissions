#!/bin/bash
set -euo pipefail
NS="k8smissions"
# Check if the deployment has the patched replica count
REPLICAS=$(kubectl get deployment api-server -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
if [ "$REPLICAS" = "5" ]; then
  echo "PASS: Deployment has 5 replicas (patch applied correctly)"
  exit 0
fi
echo "FAIL: api-server replicas=$REPLICAS (expected 5)"
exit 1
