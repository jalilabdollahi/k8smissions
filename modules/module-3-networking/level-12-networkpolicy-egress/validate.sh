#!/bin/bash
NS=payments
k() { kubectl -n "$NS" "$@"; }

for d in invoice ledger-db audit-log; do
  r=$(k get deploy "$d" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "${r:-0}" -lt 1 ]; then
    echo "❌ Deployment $d in payments has no Ready pods"
    exit 1
  fi
done
echo "✅ invoice, ledger-db and audit-log are running"

st=$(k exec deploy/invoice -- wget -q -T 8 -O- http://127.0.0.1:8080/status 2>/dev/null)
if [ "$st" != "dns=ok db=ok" ]; then
  echo "❌ invoice /status says '${st:-no answer}', expected 'dns=ok db=ok'"
  exit 1
fi
echo "✅ invoice reports dns=ok db=ok"

if k exec deploy/invoice -- wget -q -T 4 -O- http://audit-log:8080/ >/dev/null 2>&1; then
  echo "❌ invoice can reach audit-log, but egress must stay restricted"
  exit 1
fi
echo "✅ invoice still cannot reach audit-log"

types=$(k get networkpolicy -o jsonpath='{range .items[*]}{.spec.policyTypes}{"\n"}{end}' 2>/dev/null)
if ! echo "$types" | grep -q Egress; then
  echo "❌ no NetworkPolicy restricts egress in payments any more"
  exit 1
fi
echo "✅ egress is still governed by NetworkPolicy"
exit 0
exit 1
