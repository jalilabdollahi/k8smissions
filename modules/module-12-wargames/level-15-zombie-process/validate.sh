#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }
pc() { kubectl exec -n "$NS" probe -- curl -s --max-time "${T:-2}" "$@" 2>/dev/null; }
code() { kubectl exec -n "$NS" probe -- curl -s --max-time 2 -o /dev/null -w '%{http_code}' "$@" 2>/dev/null; }

want=$(kubectl -n "$NS" get deploy thumb-worker -o jsonpath='{.spec.replicas}' 2>/dev/null)
n=$(ready_count app=thumb-worker)
cn=$(ready_count app=thumb-client)
if [ "${want:-0}" = 2 ] && [ "${n:-0}" = 2 ] && [ "${cn:-0}" -ge 1 ]; then ok "thumb-worker: 2 of 2 pods Ready, thumb-client running"; else bad "thumb-worker: ${n:-0} of ${want:-?} Ready (need 2) or thumb-client missing"; exit 1; fi

pods=$(live_pods app=thumb-worker)
ips=""
for p in $pods; do ips="$ips $(kubectl -n "$NS" get pod "$p" -o jsonpath='{.status.podIP}')"; done

# 12 seconds of traffic through the Service
good=0; total=0
end=$((SECONDS+12))
while [ $SECONDS -lt $end ]; do
  total=$((total+1))
  [ "$(code http://thumb-worker/thumb)" = 200 ] && good=$((good+1))
  sleep 0.3
done
if [ "$good" = "$total" ]; then ok "/thumb answered 200 for $good of $total requests"; else bad "/thumb answered 200 for only $good of $total requests"; fail=1; fi

z=0
for ip in $ips; do
  c=$(pc "http://$ip:8080/stats" | jq -r '.zombies // 99' 2>/dev/null)
  [ "${c:-99}" -gt "$z" ] && z=${c:-99}
done
if [ "$z" -le 3 ]; then ok "zombie processes stay low (at most $z per pod)"; else bad "a pod holds $z zombie processes and they keep piling up"; fail=1; fi
[ "$fail" = 0 ] || exit 1

# wedge one replica
victim=$(echo $pods | cut -d' ' -f1)
vip=$(kubectl -n "$NS" get pod "$victim" -o jsonpath='{.status.podIP}')
r0=$(kubectl -n "$NS" get pod "$victim" -o jsonpath='{.status.containerStatuses[0].restartCount}')
pc "http://$vip:8080/admin/wedge" >/dev/null
routed=0
end=$((SECONDS+35))
while [ $SECONDS -lt $end ]; do
  s=0
  for i in 1 2 3 4 5 6; do [ "$(code http://thumb-worker/thumb)" = 200 ] && s=$((s+1)); done
  if [ "$s" = 6 ]; then routed=1; break; fi
done
if [ "$routed" = 1 ]; then ok "the wedged replica was taken out of the Service"; else bad "the Service still sends requests to the wedged replica"; fail=1; fi

restarted=0
while [ $SECONDS -lt $end ]; do
  r1=$(kubectl -n "$NS" get pod "$victim" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
  if [ -z "$r1" ] || [ "${r1:-0}" -gt "${r0:-0}" ]; then restarted=1; break; fi
  sleep 2
done
if [ "$restarted" = 1 ]; then ok "the wedged container was restarted"; else bad "the wedged container is still stuck, nothing restarted it"; fail=1; fi

[ "$fail" = 0 ] || exit 1
for i in 1 2 3 4 5 6 7 8 9 10; do [ "$(ready_count app=thumb-worker)" = 2 ] && break; sleep 2; done
if [ "$(ready_count app=thumb-worker)" = 2 ] && [ "$(code http://thumb-worker/thumb)" = 200 ]; then ok "both replicas Ready again and serving"; exit 0; fi
bad "replicas did not come back Ready"
exit 1
