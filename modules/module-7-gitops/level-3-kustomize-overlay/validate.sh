#!/bin/bash
set -euo pipefail
NS="k8smissions"

REPLICAS=$(kubectl get deployment kustomize-app -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
if [ "$REPLICAS" = "2" ]; then
  echo "✅ PASS: Staging overlay proxy is applied"
  exit 0
fi
echo "❌ FAIL: Expected 2 replicas, got '$REPLICAS'"
exit 1
