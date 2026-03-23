#!/bin/bash
set -euo pipefail
NS="k8smissions"
POLICY=$(kubectl get networkpolicy deny-all-egress -n "$NS" -o json 2>/dev/null || true)
if echo "$POLICY" | python3 -c "
import json,sys
p=json.load(sys.stdin)
rules=p.get('spec',{}).get('egress',[])
for r in rules:
    for port in r.get('ports',[]):
        if str(port.get('port',''))=='53':
            sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
  echo "PASS: Egress rule allows DNS on port 53"
  exit 0
fi
echo "FAIL: No egress rule found for port 53"
exit 1
