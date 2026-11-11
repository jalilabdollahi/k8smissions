#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }
kubectl wait pod/eu-probe -n eu --for=condition=Ready --timeout=40s >/dev/null 2>&1 || { bad "pod eu-probe in namespace eu must be Running"; exit 1; }
eu() { kubectl exec -n eu eu-probe -- curl -s --max-time 4 "$@" 2>/dev/null; }

nrep=$(kubectl -n eu get pods -l app=replicator -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')
nus=$(kubectl -n us get pods -l app=store -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')
neu=$(kubectl -n eu get pods -l app=store -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')
if [ "${nrep:-0}" -ge 2 ] && [ "${nus:-0}" -ge 1 ] && [ "${neu:-0}" -ge 1 ]; then ok "replicator (2), eu store and us store are Ready"; else bad "replicator Ready: ${nrep:-0} of 2, eu store: ${neu:-0}, us store: ${nus:-0}"; exit 1; fi

# the lease must be held by a live replicator and kept fresh
live=$(kubectl -n eu get pods -l app=replicator -o json | jq -r '.items[] | select(.metadata.deletionTimestamp==null) | .metadata.name')
holder=$(kubectl -n eu get lease eu-leader -o jsonpath='{.spec.holderIdentity}' 2>/dev/null)
age=$(kubectl -n eu get lease eu-leader -o json 2>/dev/null | jq -r '(now - (.spec.renewTime | sub("\\.[0-9]+Z$";"Z") | fromdateiso8601)) | floor' 2>/dev/null)
if echo "$live" | grep -qx "${holder:-none}" && [ "${age:-9999}" -le 20 ]; then ok "Lease eu-leader is held by live pod $holder (renewed ${age}s ago)"; else bad "Lease eu-leader: holder '${holder:-none}', last renewed ${age:-?}s ago"; fail=1; fi

# end to end: write in eu, read in us
key="order-$RANDOM"; val="v$RANDOM$RANDOM"
eu "http://store.eu.svc.cluster.local/put?k=$key&v=$val" >/dev/null
got=""
for i in $(seq 1 10); do
  got=$(eu "http://store.us.svc.cluster.local/get?k=$key")
  [ "$got" = "$val" ] && break
  sleep 2
done
if [ "$got" = "$val" ]; then ok "key written in eu appeared in us"; else bad "key written in eu did not appear in us within 20s"; fail=1; fi

# the replica must stay read-only without the token
code=$(kubectl exec -n eu eu-probe -- curl -s --max-time 4 -o /dev/null -w '%{http_code}' -X POST -d '{"intruder":"yes"}' http://store.us.svc.cluster.local/replicate 2>/dev/null)
back=$(eu "http://store.us.svc.cluster.local/get?k=intruder")
if [ "$code" = 401 ] || [ "$code" = 403 ]; then
  if [ "$back" = "yes" ]; then bad "a write without the token was stored"; fail=1; else ok "a write to us without the replication token is refused ($code)"; fi
else
  bad "a write to us without the token got HTTP ${code:-no answer}, expected 401 or 403"; fail=1
fi

# outsiders must still be shut out of the us namespace
out=$(kubectl exec -n "$NS" probe -- curl -s --max-time 4 -o /dev/null -w '%{http_code}' http://store.us.svc.cluster.local/stats 2>/dev/null)
if [ "${out:-000}" = 000 ]; then ok "a pod outside eu cannot reach the us store"; else bad "a pod in $NS reached the us store (HTTP $out); the namespace must stay closed to outsiders"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
