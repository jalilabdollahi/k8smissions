#!/bin/bash
set -euo pipefail
NS="k8smissions"

LIVENESS=$(kubectl get deployment probe-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}' 2>/dev/null || true)
READINESS=$(kubectl get deployment probe-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)
if [ "$LIVENESS" = "/healthz" ] && [ "$READINESS" = "/api/v1/ready" ]; then
  echo "✅ PASS: Probe roles are correct"
  exit 0
fi
echo "❌ FAIL: liveness='$LIVENESS' readiness='$READINESS'"
exit 1
