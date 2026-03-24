#!/bin/bash
set -euo pipefail
NS="k8smissions"
SCRAPE=$(kubectl get pod metrics-app -n "$NS" -o jsonpath='{.metadata.annotations.prometheus\.io/scrape}' 2>/dev/null || true)
PORT=$(kubectl get pod metrics-app -n "$NS" -o jsonpath='{.metadata.annotations.prometheus\.io/port}' 2>/dev/null || true)
if [ "$SCRAPE" = "true" ] && [ -n "$PORT" ]; then
  echo "PASS: Prometheus annotations present (scrape=true, port=$PORT)"
  exit 0
fi
echo "FAIL: scrape=$SCRAPE port=$PORT"
exit 1
