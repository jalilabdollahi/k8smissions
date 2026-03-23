#!/bin/bash
set -euo pipefail
POLICY=$(kubectl get pv db-data-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null || true)
if [ "$POLICY" = "Retain" ]; then
  echo "PASS: reclaimPolicy=Retain — data survives PVC deletion"
  exit 0
fi
echo "FAIL: reclaimPolicy=$POLICY"
exit 1
