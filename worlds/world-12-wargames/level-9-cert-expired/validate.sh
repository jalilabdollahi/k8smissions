#!/bin/bash
set -euo pipefail
NS="k8smissions"

STATUS=$(kubectl get secret cluster-cert-status -n "$NS" -o jsonpath='{.metadata.annotations.cert-status}' 2>/dev/null || true)
if [ "$STATUS" = "valid" ]; then
  echo "✅ PASS: Certificate status is marked as valid"
  exit 0
fi
echo "❌ FAIL: cert-status='$STATUS'"
exit 1
