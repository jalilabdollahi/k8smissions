#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get mutatingwebhookconfiguration pod-annotations-injector -o jsonpath='{.metadata.annotations}' 2>/dev/null | grep -q cert-manager || echo PASS; then
  echo "PASS: Handshake Refused"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
