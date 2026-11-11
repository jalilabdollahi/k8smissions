#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

want_api=$(kubectl -n "$NS" get deploy api -o jsonpath='{.spec.replicas}' 2>/dev/null)
[ "${want_api:-0}" -ge 2 ] || { bad "Deployment api must keep 2 replicas"; exit 1; }
na=$(ready_count app=auth); np=$(ready_count app=api)
if [ "${na:-0}" -ge 1 ] && [ "${np:-0}" -ge 2 ]; then ok "auth ($na) and api ($np) pods Ready"; else bad "auth Ready: ${na:-0}, api Ready: ${np:-0} of 2"; exit 1; fi

use() { pcurl -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $1" http://api/orders; }

# 1. fresh tokens, enough requests to hit both api replicas
good=0
for i in 1 2 3 4 5 6; do
  t=$(pcurl "http://auth/login?user=probe$i")
  [ -n "$t" ] && [ "$(use "$t")" = "200" ] && good=$((good+1))
done
if [ "$good" = 6 ]; then ok "6 of 6 fresh tokens accepted by api"; else bad "api accepted $good of 6 fresh tokens"; fail=1; fi

# 2. a token used a little later, as a real client would
t=$(pcurl "http://auth/login?user=slowclient")
sleep 10
if [ -n "$t" ] && [ "$(use "$t")" = "200" ]; then ok "a token used 10s after login is still accepted"; else bad "a token used 10s after login was refused"; fail=1; fi

# 3. a token issued two hours ago must stay rejected as expired
old=$(pcurl "http://auth/login?user=stale&age=7200")
body=$(pcurl -H "Authorization: Bearer $old" http://api/orders)
if [ -n "$old" ] && echo "$body" | grep -q 'expired'; then ok "a token from two hours ago is rejected as expired"; else bad "a two-hour-old token was not rejected as expired (got: ${body:-nothing})"; fail=1; fi

# 4. a tampered signature must stay rejected
t=$(pcurl "http://auth/login?user=mallory")
bad_t="${t%?}0"; [ "$bad_t" = "$t" ] && bad_t="${t%?}1"
if [ -n "$t" ] && [ "$(use "$bad_t")" = "401" ]; then ok "a tampered token is rejected"; else bad "a tampered token was not rejected"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
