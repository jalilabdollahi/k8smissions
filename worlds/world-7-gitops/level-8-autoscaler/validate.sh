#!/bin/bash
set -euo pipefail
NS="k8smissions"

ARG=$(kubectl get deployment cluster-autoscaler -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].args[0]}' 2>/dev/null || true)
if echo "$ARG" | grep -q 'kind-worker'; then
  echo "✅ PASS: Cluster Autoscaler proxy points to the correct node group"
  exit 0
fi
echo "❌ FAIL: autoscaler arg is '$ARG'"
exit 1
