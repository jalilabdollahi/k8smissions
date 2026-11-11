#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

nodes=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
total=$(echo "$nodes" | grep -c .)
missing=0
for n in $nodes; do
  ok=$(k get pods -l app=host-audit --field-selector "spec.nodeName=$n" -o json 2>/dev/null | python3 -c '
import json,sys
for p in json.load(sys.stdin)["items"]:
    if p["metadata"].get("deletionTimestamp"): continue
    cs=p["status"].get("containerStatuses",[])
    if cs and cs[0]["ready"]:
        print("yes"); break')
  if [ "$ok" != "yes" ]; then
    echo "❌ node $n has no Ready host-audit pod"
    missing=$((missing+1))
  fi
done
if [ "$missing" -ne 0 ]; then
  exit 1
fi
echo "✅ host-audit is Ready on all $total nodes"

sleep 15
restarts=$(k get pods -l app=host-audit -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | grep -vc '^0$')
if [ "$restarts" != "0" ]; then
  echo "❌ host-audit pods are restarting"
  exit 1
fi
echo "✅ host-audit pods are stable"
exit 0
exit 1
