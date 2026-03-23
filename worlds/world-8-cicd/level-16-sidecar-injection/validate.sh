#!/bin/bash
set -euo pipefail
NS="k8smissions"

INJECT_LABEL=$(kubectl get task injected-task -n "$NS" \
  -o jsonpath='{.spec.podTemplate.labels.sidecar\.istio\.io/inject}' 2>/dev/null || true)

if [ "$INJECT_LABEL" = "false" ]; then
  echo "PASS: Task podTemplate has sidecar.istio.io/inject=false — Istio sidecar injection is disabled for pipeline pods"
  exit 0
fi

echo "FAIL: Task 'injected-task' podTemplate label sidecar.istio.io/inject='$INJECT_LABEL' (expected 'false')"
exit 1
