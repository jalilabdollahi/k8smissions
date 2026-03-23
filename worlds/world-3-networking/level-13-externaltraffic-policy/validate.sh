#!/bin/bash
set -euo pipefail
NS="k8smissions"
POLICY=$(kubectl get service nodeport-svc -n "$NS" -o jsonpath='{.spec.externalTrafficPolicy}' 2>/dev/null || true)
if [ "$POLICY" = "Cluster" ]; then
  echo "PASS: externalTrafficPolicy=Cluster"
  exit 0
fi
echo "FAIL: externalTrafficPolicy=$POLICY"
exit 1
