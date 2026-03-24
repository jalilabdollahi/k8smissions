#!/bin/bash
set -euo pipefail
NS="k8smissions"
TOKEN=$(kubectl get secret api-secret -n "$NS" -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null || true)
if [ "$TOKEN" = "supersecret-api-token-12345" ]; then
  echo "PASS: Secret token decodes to the correct value"
  exit 0
fi
echo "FAIL: token decoded to: $TOKEN"
exit 1
