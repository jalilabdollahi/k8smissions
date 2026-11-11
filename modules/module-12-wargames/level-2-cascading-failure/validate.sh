#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

for d in gateway auth; do
  if rollout_done "$d" 2; then ok "$d: 2 of 2 replicas Ready"; else bad "$d: replicas are not all Ready"; fail=1; fi
done
c=$(kubectl -n "$NS" get deploy users-cache -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${c:-0}" -ge 1 ]; then ok "users-cache is Ready"; else bad "users-cache has no Ready pod"; fail=1; fi

before=$(( $(restart_sum app=gateway) + $(restart_sum app=auth) ))

tok=$(pcurl -X POST http://gateway/login/dana)
if [ -z "$tok" ] || [ "${#tok}" -gt 100 ]; then
  bad "login through gateway did not return a token"; fail=1
else
  ok "login through gateway returns a token"
  n=0
  for i in 1 2 3 4 5; do
    body=$(pcurl -H "Authorization: Bearer $tok" -w ' [%{http_code}]' http://gateway/api/users/42)
    case "$body" in *Whitfield*"[200]") n=$((n + 1)) ;; esac
  done
  if [ "$n" = 5 ]; then ok "authenticated requests through gateway return the user (5 of 5)"; else bad "authenticated request failed ($n of 5 returned 200): ${body:0:90}"; fail=1; fi
fi
code=$(pcurl -o /dev/null -w '%{http_code}' http://gateway/api/users/42)
if [ "$code" = "401" ]; then ok "a request without a token is refused"; else bad "a request without a token got HTTP ${code:-none}, expected 401"; fail=1; fi

sleep 6
after=$(( $(restart_sum app=gateway) + $(restart_sum app=auth) ))
if [ "$after" = "$before" ]; then ok "no container restarted during the checks"; else bad "containers are still restarting"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
