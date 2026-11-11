#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

want() { # name replicas
  local rdy
  rdy=$(k get deploy "$1" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "$(k get deploy "$1" -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "$2" ] || [ "${rdy:-0}" -ne "$2" ]; then
    echo "❌ $1: ${rdy:-0} of $2 replicas Ready"
    return 1
  fi
  return 0
}
live() { k get pods -l "$1" -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]'; }
bad=0
want shop-frontend 4 || bad=1
want shop-cart 2 || bad=1
want shop-agent 2 || bad=1
[ $bad -eq 0 ] || exit 1
echo "✅ shop-frontend 4, shop-cart 2 and shop-agent 2 replicas are Ready"

fe=$(live app=shop,tier=frontend); ca=$(live app=shop,tier=cart); ag=$(live app=shop-agent)
all=$(echo "$fe $ca $ag" | jq -s 'add')
off=$(echo "$all" | jq -r '.[].spec.nodeName' | sort -u | while read -r n; do workers | grep -qx "$n" || echo "$n"; done)
if [ -n "$off" ]; then
  echo "❌ pods are running outside the workers: $off"
  exit 1
fi
if [ "$(echo "$fe" | jq length)" -ne 4 ] || [ "$(echo "$ca" | jq length)" -ne 2 ] || [ "$(echo "$ag" | jq length)" -ne 2 ]; then
  echo "❌ extra pods still exist (rollout in progress?)"
  exit 1
fi

a=$(worker_n 1); b=$(worker_n 2)
fa=$(echo "$fe" | jq --arg n "$a" '[.[] | select(.spec.nodeName==$n)] | length')
fb=$(echo "$fe" | jq --arg n "$b" '[.[] | select(.spec.nodeName==$n)] | length')
d=$((fa - fb)); [ $d -lt 0 ] && d=$((-d))
if [ "$d" -gt 1 ]; then
  echo "❌ shop-frontend is split $fa / $fb over the workers"
  exit 1
fi
echo "✅ shop-frontend is split $fa / $fb over the workers"

if [ "$(echo "$ca" | jq '[.[].spec.nodeName] | unique | length')" -ne 2 ]; then
  echo "❌ the shop-cart pods share a node"
  exit 1
fi
echo "✅ the shop-cart pods run on different nodes"

if [ "$(echo "$ag" | jq '[.[].spec.nodeName] | unique | length')" -ne 2 ]; then
  echo "❌ the shop-agent pods share a node"
  exit 1
fi
echo "✅ one shop-agent per node"

# user-facing: requests through the Services, from inside a frontend pod
src=$(echo "$fe" | jq -r '.[0].metadata.name')
for svc in shop-frontend shop-cart; do
  out=$(for i in $(seq 1 14); do
    timeout 6 kubectl -n "$NS" exec "$src" -- wget -q -T 2 -O- "http://$svc/" 2>/dev/null
  done)
  ok=$(echo "$out" | grep -c .)
  uniq=$(echo "$out" | sort -u | grep -c .)
  need=4; [ "$svc" = shop-cart ] && need=2
  if [ "$ok" -lt 12 ]; then
    echo "❌ Service $svc answered only $ok of 14 requests"
    exit 1
  fi
  if [ "$uniq" -lt "$need" ]; then
    echo "❌ Service $svc is answered by only $uniq of $need pods"
    exit 1
  fi
  echo "✅ Service $svc answered $ok of 14 requests, served by $uniq pods"
done
exit 0
exit 1
