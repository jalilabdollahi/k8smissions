#!/bin/bash
set -euo pipefail
NS="k8smissions"

IMAGE=$(kubectl get deployment grand-finale-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
READY=$(kubectl get deployment grand-finale-app -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null || true)
PDB=$(kubectl get pdb grand-finale-pdb -n "$NS" -o jsonpath='{.spec.minAvailable}' 2>/dev/null || true)
if [ "$IMAGE" = "nginx:1.27.4" ] && [ "$READY" = "/" ] && [ "$PDB" = "1" ]; then
  echo "✅ PASS: Production proxy stack is repaired"
  exit 0
fi
echo "❌ FAIL: image='$IMAGE' readiness='$READY' pdb='$PDB'"
exit 1
