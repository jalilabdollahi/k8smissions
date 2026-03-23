#!/bin/bash
set -euo pipefail
NS="k8smissions"

READINESS=$(kubectl get deployment zombie-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)
LIVENESS=$(kubectl get deployment zombie-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null || true)
if [ -n "$READINESS" ] && [ -n "$LIVENESS" ]; then
  echo "✅ PASS: Both readiness and liveness probes are configured"
  exit 0
fi
echo "❌ FAIL: readiness='$READINESS' liveness='$LIVENESS'"
exit 1
