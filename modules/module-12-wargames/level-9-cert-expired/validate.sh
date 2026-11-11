#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

for d in ledger gateway; do
  if rollout_done "$d" 2; then ok "$d: 2 of 2 replicas Ready"; else bad "$d: replicas are not all Ready"; fail=1; fi
done

n=0; last=""
for i in 1 2 3 4 5 6; do
  last=$(pcurl -w ' [%{http_code}]' http://gateway/balance | tr -d '\n')
  case "$last" in "ledger balance: 1042.17 EUR"*"[200]") n=$((n + 1)) ;; esac
done
if [ "$n" = 6 ]; then ok "GET /balance through gateway returns the ledger's answer (6 of 6)"; else bad "only $n of 6 requests through gateway succeeded: ${last:0:110}"; fail=1; fi

code=$(kubectl exec -n "$NS" probe -- curl -sk --max-time 5 -o /dev/null -w '%{http_code}' https://ledger:8443/balance 2>/dev/null)
if [ "$code" != "200" ]; then ok "ledger refuses a client without a certificate"; else bad "ledger answered a client that presented no certificate"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
