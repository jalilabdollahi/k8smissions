#!/bin/bash
set -euo pipefail
NS="k8smissions"
HTTP_NAME=$(kubectl get service dual-svc -n "$NS" -o jsonpath='{.spec.ports[?(@.port==80)].name}' 2>/dev/null || true)
HTTPS_NAME=$(kubectl get service dual-svc -n "$NS" -o jsonpath='{.spec.ports[?(@.port==443)].name}' 2>/dev/null || true)
if [ -n "$HTTP_NAME" ] && [ -n "$HTTPS_NAME" ]; then
  echo "PASS: Ports are named — http=$HTTP_NAME https=$HTTPS_NAME"
  exit 0
fi
echo "FAIL: Missing port names (http=$HTTP_NAME, https=$HTTPS_NAME)"
exit 1
