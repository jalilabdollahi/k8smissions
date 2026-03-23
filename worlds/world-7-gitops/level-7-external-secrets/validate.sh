#!/bin/bash
set -euo pipefail
NS="k8smissions"

MANAGED=$(kubectl get secret app-secret -n "$NS" -o jsonpath='{.metadata.annotations.managed-by}' 2>/dev/null || true)
if [ "$MANAGED" = "external-secrets" ]; then
  echo "✅ PASS: Secret is now managed by the External Secrets proxy"
  exit 0
fi
echo "❌ FAIL: Secret annotation managed-by='$MANAGED'"
exit 1
