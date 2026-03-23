#!/bin/bash
set -euo pipefail
NS="k8smissions"

IMAGE=$(kubectl get job db-migration -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)
ENV=$(kubectl get job db-migration -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].env[0].name}' 2>/dev/null || true)
if [ "$IMAGE" = "busybox:1.36" ] && [ "$ENV" = "DATABASE_URL" ]; then
  echo "✅ PASS: Migration job is correctly configured"
  exit 0
fi
echo "❌ FAIL: image='$IMAGE' env='$ENV'"
exit 1
