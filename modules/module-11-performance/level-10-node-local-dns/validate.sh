#!/bin/bash
# Level 10: the lookups must really be answered by the node-local cache, and upstream must see few of them.
. ../_fixtures/lib.sh

for obj in deployment/dns-upstream deployment/session-gw daemonset/dns-cache; do
  if ! kubectl get "$obj" -n "$NS" >/dev/null 2>&1; then
    bad "$obj does not exist"
    exit 1
  fi
done

want=$(kubectl get ds dns-cache -n "$NS" -o jsonpath='{.status.desiredNumberScheduled}')
have=$(kubectl get ds dns-cache -n "$NS" -o jsonpath='{.status.numberReady}')
workers=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "${want:-0}" -lt "$workers" ] || [ "${have:-0}" -lt "${want:-0}" ]; then
  bad "dns-cache is Ready on ${have:-0} of $workers worker nodes"
  exit 1
fi
ok "dns-cache is Ready on all $workers workers"
if ! wait_ready app=dns-upstream 1 40 || ! wait_ready app=session-gw 2 60; then
  bad "dns-upstream or session-gw has pods that are not Ready"
  exit 1
fi

GW=$(live_pods app=session-gw)
CACHES=$(live_pods app=dns-cache)
UP=$(live_pods app=dns-upstream | head -1)
FIRST=$(echo "$GW" | head -1)

# dns-upstream must still be the slow resolver: ask it directly from a gateway pod
DQ="import socket,struct,time
p=struct.pack('>HHHHHH',7,0x0100,1,0,0,0)+b'\x05probe\x07session\x08internal\x00'+struct.pack('>HH',1,1)
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(3)
UPIP
t=time.time()
try:
    s.sendto(p,(ip,53));s.recv(512);print(int((time.time()-t)*1000))
except Exception:
    print(-1)"
UPIP=$(kubectl get svc dns-upstream -n "$NS" -o jsonpath='{.spec.clusterIP}')
DQ=${DQ/UPIP/ip=\'$UPIP\'}
d=$(kubectl exec -n "$NS" "$FIRST" -- python -c "$DQ" 2>/dev/null)
if [ -z "$d" ] || [ "$d" -lt 50 ]; then
  bad "dns-upstream no longer behaves like the slow resolver (direct lookup took ${d:-?}ms)"
  exit 1
fi
ok "dns-upstream is still slow when asked directly (${d}ms)"

total_of() {
  local s=0 p n
  for p in $GW; do
    n=$(kubectl logs -n "$NS" "$p" --tail=1 2>/dev/null | jq -r '.total // 0' 2>/dev/null)
    s=$((s + ${n:-0}))
  done
  echo $s
}
T0=$(total_of)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ); E0=$(date +%s)
sleep 20
T1=$(total_of)
LOOKUPS=$((T1 - T0))
UPQ=$(kubectl logs -n "$NS" "$UP" --since-time="$TS" 2>/dev/null | grep -c '"A IN')
CQ=0
for c in $CACHES; do
  n=$(kubectl logs -n "$NS" "$c" --since-time="$TS" 2>/dev/null | grep -c '"A IN')
  CQ=$((CQ + n))
done
if [ "$LOOKUPS" -lt 2000 ]; then
  bad "session-gw only performed $LOOKUPS lookups in 20s (expected about 4000)"
  exit 1
fi
if [ $((CQ * 100)) -lt $((LOOKUPS * 80)) ]; then
  bad "the dns-cache pods saw $CQ of the $LOOKUPS lookups: session-gw is not using them"
  exit 1
fi
ok "dns-cache answered $CQ of $LOOKUPS lookups"
if [ $((UPQ * 100)) -ge $((LOOKUPS * 10)) ]; then
  bad "dns-upstream still received $UPQ queries for $LOOKUPS lookups (limit 10%)"
  exit 1
fi
ok "dns-upstream received only $UPQ queries for $LOOKUPS lookups"

P95=0
for p in $GW; do
  v=$(kubectl logs -n "$NS" "$p" --since-time="$TS" 2>/dev/null | jq -s '[.[] | select(.t >= '"$((E0 + 5))"') | .p95] | sort | .[(length/2|floor)] // 9999' 2>/dev/null)
  [ "${v:-9999}" -gt "$P95" ] && P95=${v:-9999}
done
if [ "$P95" -ge 40 ]; then
  bad "session-gw lookup p95 is ${P95}ms (limit 40ms)"
  exit 1
fi
ok "session-gw lookup p95 is ${P95}ms"
exit 0
exit 1
