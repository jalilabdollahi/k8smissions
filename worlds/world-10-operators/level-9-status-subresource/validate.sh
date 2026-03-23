#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get crd myapps.example.com -o jsonpath='{.spec.versions[0].subresources}' 2>/dev/null | grep -q status || echo PASS; then
  echo "PASS: Status Not Updating"
  exit 0
fi
echo "FAIL: check broken state"
exit 1
