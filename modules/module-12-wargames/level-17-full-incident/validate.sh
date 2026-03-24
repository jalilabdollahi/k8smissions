#!/bin/bash
set -euo pipefail
NS="k8smissions"

FAIL=0

# Check 1: Secret p0-secret exists
SECRET=$(kubectl get secret p0-secret -n "$NS" 2>/dev/null && echo "ok" || echo "missing")
[ "$SECRET" != "ok" ] && echo "❌ Secret p0-secret missing" && FAIL=1

# Check 2: Deployment is scaled up with 2 ready replicas
READY=$(kubectl get deployment p0-app -n "$NS" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
[ "$READY" != "2" ] && echo "❌ Deployment not ready (readyReplicas=$READY, want 2)" && FAIL=1

# Check 3: DNS-allow NetworkPolicy exists
DNS=$(kubectl get networkpolicy allow-dns -n "$NS" 2>/dev/null && echo "ok" || echo "missing")
[ "$DNS" != "ok" ] && echo "❌ DNS-allow NetworkPolicy (allow-dns) is missing" && FAIL=1

# Check 4: PVC storage request is no longer 999Ti
PVC=$(kubectl get pvc p0-pvc -n "$NS" -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null || true)
[ "$PVC" = "999Ti" ] && echo "❌ PVC still has impossibly large storage request (999Ti)" && FAIL=1

# Check 5: Deployment nodeSelector no longer points to non-existent node label
NODE_SEL=$(kubectl get deployment p0-app -n "$NS" -o jsonpath='{.spec.template.spec.nodeSelector.environment}' 2>/dev/null || true)
[ "$NODE_SEL" = "prod-zone-nonexistent" ] && echo "❌ Deployment still has invalid nodeSelector (environment=prod-zone-nonexistent)" && FAIL=1

if [ "$FAIL" = "0" ]; then
  echo "✅ PASS: All 5 issues resolved — P0 incident cleared"
  exit 0
fi
exit 1
