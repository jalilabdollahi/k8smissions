#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

for d in ledger-api storefront; do
  r=$(k get deploy "$d" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "${r:-0}" -ne 2 ]; then
    echo "❌ Deployment $d: ${r:-0} of 2 pods Ready"
    exit 1
  fi
done
echo "✅ ledger-api and storefront have 2 Ready pods each"

pods=$(k get pods -l app=storefront -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.deletionTimestamp}{"\n"}{end}' | awk 'NF==1{print $1}')
for p in $pods; do
  body=$(k exec "$p" -- curl -s --max-time 4 http://ledger-api:8080/ 2>/dev/null)
  if [ "$body" != "ledger: 42 open invoices" ]; then
    echo "❌ $p cannot reach ledger-api:8080 (got: '${body:-timeout}')"
    exit 1
  fi
  echo "✅ $p reaches ledger-api:8080"
done

if k exec report-batch -- curl -s --max-time 4 http://ledger-api:8080/ >/dev/null 2>&1; then
  echo "❌ report-batch can reach ledger-api, but it must stay blocked"
  exit 1
fi
echo "✅ report-batch is still blocked"

sel=$(k get networkpolicy -o jsonpath='{range .items[*]}{.spec.podSelector.matchLabels.app}{"\n"}{end}' | grep -c '^ledger-api$')
if [ "$sel" -lt 1 ]; then
  echo "❌ no NetworkPolicy protects ledger-api any more"
  exit 1
fi
echo "✅ ledger-api is still protected by a NetworkPolicy"
exit 0
exit 1
