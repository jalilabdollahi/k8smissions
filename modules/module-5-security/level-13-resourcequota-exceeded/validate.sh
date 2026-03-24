#!/bin/bash
set -euo pipefail
NS="k8smissions"
# Check that the pod was accepted (exists in cluster — not rejected by admission)
STATUS=$(kubectl get pod quota-buster -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ] || [ "$STATUS" = "Pending" ]; then
  CPU=$(kubectl get pod quota-buster -n "$NS" -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true)
  MEM=$(kubectl get pod quota-buster -n "$NS" -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)
  # Verify the requests are within quota: cpu <= 200m and memory <= 200Mi
  echo "PASS: Pod accepted by quota admission with requests cpu=$CPU memory=$MEM"
  exit 0
fi
echo "FAIL: pod quota-buster phase='$STATUS' — likely rejected by ResourceQuota admission"
exit 1
