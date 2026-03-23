#!/bin/bash
set -euo pipefail
NS="k8smissions"
TARGET=$(kubectl get service web-svc -n "$NS" -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null || true)
if [ "$TARGET" = "80" ]; then
  echo "PASS: targetPort is 80, matching the container port"
  exit 0
fi
echo "FAIL: targetPort=$TARGET but container listens on 80"
exit 1
