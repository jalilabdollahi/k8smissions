#!/bin/bash
set -euo pipefail
NS="k8smissions"

COUNT=$(kubectl get configmap -n "$NS" --no-headers 2>/dev/null | grep -c '^ci-run-' || true)
if [ "$COUNT" = "0" ]; then
  echo "✅ PASS: All stale ci-run-* ConfigMaps have been deleted"
  exit 0
fi
echo "❌ FAIL: $COUNT stale ci-run-* ConfigMaps still exist"
exit 1
