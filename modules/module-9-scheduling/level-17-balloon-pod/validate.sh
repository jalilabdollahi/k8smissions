#!/bin/bash
set -euo pipefail
NS="k8smissions"
if BALLOON=$(kubectl get pod balloon-pod -n k8smissions -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true); [ "$BALLOON" != '2000m' ]; then
  echo "PASS: Reserved Space"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
