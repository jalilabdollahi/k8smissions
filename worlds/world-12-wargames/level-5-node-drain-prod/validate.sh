#!/bin/bash
set -euo pipefail
NS="k8smissions"

MIN=$(kubectl get pdb critical-pdb -n "$NS" -o jsonpath='{.spec.minAvailable}' 2>/dev/null || true)
REPLICAS=$(kubectl get deployment critical-app -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null || true)
if [ "$MIN" -lt "$REPLICAS" ] 2>/dev/null; then
  echo "✅ PASS: PDB allows drain (minAvailable=$MIN < replicas=$REPLICAS)"
  exit 0
fi
echo "❌ FAIL: minAvailable=$MIN must be less than replicas=$REPLICAS"
exit 1
