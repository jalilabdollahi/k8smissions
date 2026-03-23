#!/bin/bash
set -euo pipefail
NS="k8smissions"
SVC=$(kubectl get ingress app-ingress -n "$NS" -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null || true)
if [ "$SVC" = "app-service" ]; then
  echo "PASS: Ingress backend references app-service"
  exit 0
fi
echo "FAIL: Ingress backend service=$SVC (expected app-service)"
exit 1
