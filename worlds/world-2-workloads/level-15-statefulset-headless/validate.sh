#!/bin/bash
set -euo pipefail
NS="k8smissions"
SVC_NAME=$(kubectl get statefulset db -n "$NS" -o jsonpath='{.spec.serviceName}' 2>/dev/null || true)
if [ -n "$SVC_NAME" ]; then
  CLUSTER_IP=$(kubectl get service "$SVC_NAME" -n "$NS" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)
  if [ "$CLUSTER_IP" = "None" ]; then
    echo "PASS: StatefulSet references a headless service (clusterIP: None)"
    exit 0
  fi
fi
echo "FAIL: serviceName=$SVC_NAME does not point to a headless service"
exit 1
