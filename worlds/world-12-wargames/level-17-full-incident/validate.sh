#!/bin/bash
set -euo pipefail
NS="k8smissions"

SECRET=$(kubectl get secret p0-secret -n "$NS" 2>/dev/null && echo "ok" || echo "missing")
READY=$(kubectl get deployment p0-app -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
DNS=$(kubectl get networkpolicy allow-dns -n "$NS" 2>/dev/null && echo "ok" || echo "missing")
PVC=$(kubectl get pvc p0-pvc -n "$NS" -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null || true)

FAIL=0
[ "$SECRET" != "ok" ] && echo "❌ Secret missing" && FAIL=1
[ "$READY" != "2" ] && echo "❌ Deployment not ready (readyReplicas=$READY)" && FAIL=1
[ "$DNS" != "ok" ] && echo "❌ DNS allow NetworkPolicy missing" && FAIL=1
[ "$PVC" = "999Ti" ] && echo "❌ PVC still has impossibly large storage request" && FAIL=1
if [ "$FAIL" = "0" ]; then
  echo "✅ PASS: All 5 issues resolved — P0 incident cleared"
  exit 0
fi
exit 1
