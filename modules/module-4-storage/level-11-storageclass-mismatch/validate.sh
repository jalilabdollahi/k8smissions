#!/bin/bash
set -euo pipefail
NS="k8smissions"
SC=$(kubectl get pvc data-pvc -n "$NS" -o jsonpath='{.spec.storageClassName}' 2>/dev/null || true)
AVAIL=$(kubectl get storageclass "$SC" 2>/dev/null && echo ok || echo missing)
if [ "$AVAIL" = "ok" ]; then
  echo "PASS: PVC uses existing StorageClass $SC"
  exit 0
fi
STATUS=$(kubectl get pvc data-pvc -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
echo "FAIL: storageClass=$SC availability=$AVAIL pvcStatus=$STATUS"
exit 1
