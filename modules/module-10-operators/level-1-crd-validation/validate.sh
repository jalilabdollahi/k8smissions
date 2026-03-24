#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get crd apptemplates.example.com -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.replicas.minimum}' 2>/dev/null | grep -qv '^5$' || echo PASS; then
  echo "PASS: Rejected by the API"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
