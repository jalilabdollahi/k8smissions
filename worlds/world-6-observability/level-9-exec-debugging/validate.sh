#!/bin/bash
set -euo pipefail
NS="k8smissions"

HOST=$(kubectl get configmap app-config -n "$NS" -o jsonpath='{.data.config\.json}' 2>/dev/null | grep -o 'database.k8smissions.svc.cluster.local' || true)
if [ -n "$HOST" ]; then
  echo "✅ PASS: ConfigMap points to the service DNS name"
  exit 0
fi
echo "❌ FAIL: ConfigMap still has the wrong DB host"
exit 1
