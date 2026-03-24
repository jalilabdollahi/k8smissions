#!/bin/bash
set -euo pipefail
NS="k8smissions"

COUNT=$(kubectl get pods -n "$NS" --no-headers 2>/dev/null | grep -c '^ci-test-pod-' || true)
if [ "$COUNT" = "0" ]; then
  echo "✅ PASS: All duplicate CI test pods have been removed"
  exit 0
fi
echo "❌ FAIL: $COUNT ci-test-pod-* pods still exist"
exit 1
