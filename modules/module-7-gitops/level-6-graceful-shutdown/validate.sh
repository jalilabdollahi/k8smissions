#!/bin/bash
set -euo pipefail
NS="k8smissions"

PRESTOP=$(kubectl get deployment graceful-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]}' 2>/dev/null || true)
GRACE=$(kubectl get deployment graceful-app -n "$NS" -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}' 2>/dev/null || true)
if [ "$PRESTOP" = "sleep 15" ] && [ "$GRACE" = "60" ]; then
  echo "✅ PASS: Graceful shutdown hooks are in place"
  exit 0
fi
echo "❌ FAIL: preStop='$PRESTOP' grace='$GRACE'"
exit 1
