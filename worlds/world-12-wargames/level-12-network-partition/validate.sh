#!/bin/bash
set -euo pipefail
NS="k8smissions"

COUNT=$(kubectl get networkpolicy -n "$NS" --no-headers 2>/dev/null | wc -l | tr -d ' ')
ALLOW=$(kubectl get networkpolicy allow-frontend-to-backend -n "$NS" 2>/dev/null && echo "yes" || echo "no")
if [ "$ALLOW" = "yes" ]; then
  echo "✅ PASS: Allow rule exists for frontend→backend traffic"
  exit 0
fi
echo "❌ FAIL: Missing allow-frontend-to-backend NetworkPolicy"
exit 1
