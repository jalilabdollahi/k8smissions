#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
O=orders.shop.acme.io

reps=$(k get deploy orders-operator -o jsonpath='{.spec.replicas}' 2>/dev/null)
ready=$(k get deploy orders-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${reps:-0}" -lt 2 ]; then
  echo "❌ orders-operator runs ${reps:-0} replica(s); it has to stay highly available with 2"
  exit 1
fi
if [ "${ready:-0}" -lt 2 ]; then
  echo "❌ only ${ready:-0} of $reps orders-operator pods are ready"
  exit 1
fi
echo "✅ orders-operator keeps $reps ready replicas"

leases() { k get lease -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.spec.holderIdentity}{"|"}{.spec.renewTime}{"\n"}{end}' 2>/dev/null | sort; }
s1=$(leases); sleep 5; s2=$(leases)
live=$(comm -13 <(echo "$s1") <(echo "$s2"))   # leases whose renewTime moved: someone is actively holding them
n=$(echo "$live" | grep -c .)
if [ "$n" != 1 ]; then
  who=$(echo "$live" | cut -d'|' -f2 | tr '\n' ' ')
  echo "❌ $n leases are being renewed right now (holders: ${who:-none}); there must be exactly one leader"
  exit 1
fi
leader=$(echo "$live" | cut -d'|' -f2)
if ! k get pod "$leader" >/dev/null 2>&1; then
  echo "❌ the lease holder '$leader' is not a pod of this namespace"
  exit 1
fi
echo "✅ one lease is live, held by $leader"

writers() { k get $O -o jsonpath='{range .items[*]}{.metadata.name}={.status.lastWriter}/{.status.claims} {end}' 2>/dev/null; }
for i in $(seq 1 5); do
  w=$(writers)
  [ "$(echo "$w" | tr ' ' '\n' | grep -c "=$leader/")" = 3 ] && break
  sleep 2
done
base=$(writers)
if [ "$(echo "$base" | tr ' ' '\n' | grep -c "=$leader/")" != 3 ]; then
  echo "❌ the Orders are not all owned by the leader $leader yet: $base"
  exit 1
fi
for i in 1 2 3 4 5; do
  sleep 3
  if [ "$(writers)" != "$base" ]; then
    echo "❌ the Orders are still changing hands (lastWriter or claims moved): was $base, now $(writers)"
    exit 1
  fi
done
echo "✅ lastWriter stays on the leader for 15 seconds"

# failover: remove the leader and make sure the survivor serves a new Order
k delete $O probe-order --ignore-not-found >/dev/null 2>&1
k delete pod "$leader" --grace-period=1 --wait=false >/dev/null 2>&1
k apply -f - >/dev/null 2>&1 <<'Y'
apiVersion: shop.acme.io/v1
kind: Order
metadata: {name: probe-order}
spec: {item: failover-check, quantity: 1}
Y
ok=0
for i in $(seq 1 30); do
  lw=$(k get $O probe-order -o jsonpath='{.status.lastWriter}' 2>/dev/null)
  if [ -n "$lw" ] && [ "$lw" != "$leader" ] && k get pod "$lw" >/dev/null 2>&1; then ok=1; break; fi
  sleep 1
done
k delete $O probe-order --ignore-not-found >/dev/null 2>&1
if [ "$ok" != 1 ]; then
  echo "❌ after deleting the leader $leader, no other pod reconciled a new Order within 30 seconds"
  exit 1
fi
echo "✅ after the leader was deleted, $lw took over and reconciled a new Order"
exit 0
exit 1
