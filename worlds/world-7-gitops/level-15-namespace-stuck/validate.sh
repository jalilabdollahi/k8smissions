#!/bin/bash
set -euo pipefail
NS_EXISTS=$(kubectl get namespace zombie-ns 2>&1 || true)
if echo "$NS_EXISTS" | grep -q "not found"; then
  echo "PASS: zombie-ns namespace has been fully deleted"
  exit 0
fi
FINALIZERS=$(kubectl get namespace zombie-ns -o jsonpath='{.metadata.finalizers}' 2>/dev/null || true)
if [ -z "$FINALIZERS" ] || [ "$FINALIZERS" = "[]" ]; then
  echo "PASS: Namespace finalizers have been cleared"
  exit 0
fi
echo "FAIL: Namespace still has finalizers: $FINALIZERS"
exit 1
