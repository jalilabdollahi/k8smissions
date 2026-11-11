#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0

ensure_probe || { bad "could not start the probe pod"; exit 1; }

ready=$(kubectl -n "$NS" get sts ledger-db -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
pvc=$(kubectl -n "$NS" get pvc data-ledger-db-0 -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "${ready:-0}" = "1" ] && [ "$pvc" = "Bound" ]; then
  ok "ledger-db is running with its data volume bound"
else
  bad "ledger-db is not running (ready: ${ready:-0}, volume: ${pvc:-missing})"; fail=1
fi

app=$(kubectl -n "$NS" get deploy ledger-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${app:-0}" -ge 2 ]; then ok "ledger-app has ${app} ready pods"; else bad "ledger-app has fewer than 2 ready pods"; fail=1; fi

key="drill-$RANDOM$RANDOM"
code=$(pcurl -o /dev/null -w '%{http_code}' -X POST -d "{\"account\":\"CHECK\",\"amount\":7}" "http://ledger-app/entries/$key")
back=$(pcurl "http://ledger-app/entries/$key")
if [ "$code" = "201" ] && echo "$back" | grep -q CHECK; then
  ok "a new entry is written and read back through ledger-app"
else
  bad "writing through ledger-app failed (HTTP ${code:-none})"; fail=1
fi

seed=$(pcurl "http://ledger-app/entries/entry-0001")
if echo "$seed" | grep -q "ACME-4417"; then
  ok "entry-0001 from before the drill is still there"
else
  bad "entry-0001 booked before the drill is missing"; fail=1
fi

dbip=$(kubectl -n "$NS" get pod ledger-db-0 -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -n "$dbip" ]; then
  out=$(pcurl --max-time 3 -o /dev/null -w '%{http_code}' "http://$dbip:5000/healthz")
  if [ "$out" = "200" ]; then
    bad "a pod outside the app tier can reach the database directly"; fail=1
  else
    ok "the database is still closed to pods outside the app tier"
  fi
else
  bad "ledger-db-0 has no IP yet"; fail=1
fi

[ "$fail" = 0 ] && exit 0
exit 1
