#!/bin/bash
set -euo pipefail
if kubectl get namespace webapp-prod >/dev/null 2>&1 && kubectl get deployment webapp-app -n webapp-prod >/dev/null 2>&1; then
  echo "✅ PASS: target namespace exists and app is deployed"
  exit 0
fi
echo "❌ FAIL: ArgoCD proxy target namespace or app is missing"
exit 1
