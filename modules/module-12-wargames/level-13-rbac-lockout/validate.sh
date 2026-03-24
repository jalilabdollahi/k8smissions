#!/bin/bash
set -euo pipefail
NS="k8smissions"

if kubectl get rolebinding app-rb -n "$NS" >/dev/null 2>&1; then
  SA=$(kubectl get rolebinding app-rb -n "$NS" -o jsonpath='{.subjects[0].name}' 2>/dev/null || true)
  if [ "$SA" = "app-sa" ]; then
    echo "✅ PASS: RoleBinding restored — app-sa has the app-role permissions"
    exit 0
  fi
fi
echo "❌ FAIL: RoleBinding app-rb missing or not bound to app-sa"
exit 1
