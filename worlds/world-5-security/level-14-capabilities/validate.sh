#!/bin/bash
set -euo pipefail
NS="k8smissions"
CAPS=$(kubectl get pod port-binder -n "$NS" -o jsonpath='{.spec.containers[0].securityContext.capabilities.add}' 2>/dev/null || true)
if echo "$CAPS" | grep -q "NET_BIND_SERVICE"; then
  echo "PASS: NET_BIND_SERVICE capability is added"
  exit 0
fi
echo "FAIL: capabilities.add does not include NET_BIND_SERVICE"
echo "Current: $CAPS"
exit 1
