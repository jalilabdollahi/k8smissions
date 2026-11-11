#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

st=$(helm -n "$NS" status ledger-api -o json 2>/dev/null)
rev=$(echo "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' 2>/dev/null)
phase=$(echo "$st" | python3 -c 'import json,sys; print(json.load(sys.stdin)["info"]["status"])' 2>/dev/null)
if [ "$phase" != "deployed" ] || [ "${rev:-0}" -le 2 ]; then
  echo "❌ Helm release ledger-api: status '${phase:-missing}' at revision ${rev:-none}; no new revision after CI's upgrade yet"
  exit 1
fi
echo "✅ Helm release ledger-api is deployed at revision $rev"

ready=$(k get deploy ledger-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
want=$(k get deploy ledger-api -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ] || [ "${want:-0}" -ne 3 ]; then
  echo "❌ Deployment ledger-api: ${ready:-0} Ready of ${want:-0} desired, production runs 3"
  exit 1
fi
echo "✅ Deployment ledger-api has 3 Ready replicas"

imgs=$(k get pods -l app=ledger-api --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' | sort -u)
if [ "$imgs" != "hashicorp/http-echo:1.0" ]; then
  echo "❌ ledger-api pods run image(s): $(echo $imgs)"
  exit 1
fi
echo "✅ every ledger-api pod runs hashicorp/http-echo:1.0"

out=$(k exec probe -- sh -c 'for i in $(seq 30); do curl -s --max-time 2 http://ledger-api; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^ledger-api: production$')
if [ "$good" -ne 30 ]; then
  echo "❌ ledger-api: only $good of 30 requests returned the production message"
  exit 1
fi
echo "✅ ledger-api: 30 of 30 requests returned the production message"
exit 0
exit 1
