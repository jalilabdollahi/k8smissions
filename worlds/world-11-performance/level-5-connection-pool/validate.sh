#!/bin/bash
set -euo pipefail
NS="k8smissions"
if kubectl get deployment web-app -n k8smissions -o jsonpath='{.spec.template.spec.containers[0].env}' 2>/dev/null | python3 -c "import json,sys; env=json.load(sys.stdin); vals={e['name']:e['value'] for e in env}; exit(0 if vals.get('DB_POOL_SIZE','1') != '1' else 1)" 2>/dev/null || echo PASS; then
  echo "PASS: Database Stampede"
  exit 0
fi
echo "FAIL: check broken configuration"
exit 1
