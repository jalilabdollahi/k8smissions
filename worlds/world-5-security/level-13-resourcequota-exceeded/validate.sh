#!/bin/bash
set -euo pipefail
NS="k8smissions"
STATUS=$(kubectl get pod quota-buster -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null || true)
if [ "$STATUS" = "Running" ] || [ "$STATUS" = "Pending" ]; then
  CPU=$(kubectl get pod quota-buster -n "$NS" -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null || true)
  MEM=$(kubectl get pod quota-buster -n "$NS" -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null || true)
  echo "PASS: Pod is running with requests cpu=$CPU memory=$MEM"
  exit 0
fi
echo "FAIL: pod phase=$STATUS"
exit 1
