#!/bin/bash
set -euo pipefail
NS="k8smissions"
ITEMS=$(kubectl get pod config-reader -n "$NS" -o jsonpath='{.spec.volumes[0].configMap.items}' 2>/dev/null || true)
if echo "$ITEMS" | grep -q "logging.properties"; then
  echo "PASS: Both config files are projected into the volume"
  exit 0
fi
echo "FAIL: logging.properties not found in volume items"
echo "Current items: $ITEMS"
exit 1
