#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
CK=checkout
k() { kubectl -n "$CK" "$@"; }
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

# security policy must stay in force
enf=$(kubectl get ns "$CK" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$enf" = restricted ]; then ok "namespace checkout still enforces the restricted Pod Security level"; else bad "namespace checkout enforces '${enf:-nothing}'; it must stay restricted"; exit 1; fi

names=$(k get deploy checkout -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null)
case " $names " in
  *" app "*) case " $names " in *" log-shipper "*) ok "both containers (app, log-shipper) are in the pod template";; *) bad "pod template must keep container log-shipper (found: ${names:-none})"; exit 1;; esac;;
  *) bad "pod template must keep container app (found: ${names:-none})"; exit 1;;
esac

min=$(k get hpa checkout -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
min=${min:-1}; [ "$min" -ge 2 ] || min=2
pods=$(k get pods -l app=checkout -o json 2>/dev/null)
ready=$(echo "$pods" | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(any(.status.conditions[]?; .type=="Ready" and .status=="True"))] | length')
rst=$(echo "$pods" | jq '[.items[].status.containerStatuses[]?.restartCount] | add // 0')
if [ "${ready:-0}" -ge "$min" ] && [ "${rst:-1}" = 0 ]; then ok "checkout: $ready pods Ready, no restarts"; else bad "checkout: ${ready:-0} pods Ready (need $min), $rst restarts"; exit 1; fi

good=0; uid=""
for i in 1 2 3 4 5 6 7 8; do
  body=$(pcurl "http://checkout.$CK.svc/")
  case "$body" in "checkout ok uid="*) good=$((good+1)); uid=${body#*uid=};; esac
done
if [ "$good" = 8 ] && [ -n "$uid" ] && [ "$uid" != 0 ]; then ok "Service checkout answers (running as uid $uid, not root)"; else bad "Service checkout answered $good of 8 requests (uid '${uid:-?}', must not be 0)"; exit 1; fi

# the HPA must read CPU
util=""
for i in $(seq 1 8); do
  util=$(k get hpa checkout -o json | jq -r '[.status.currentMetrics[]? | select(.type=="Resource" and .resource.name=="cpu") | .resource.current.averageUtilization // empty] | first // empty')
  [ -n "$util" ] && break
  sleep 3
done
if [ -n "$util" ]; then ok "the HPA reads CPU utilisation (${util}%)"; else bad "the HPA has no CPU utilisation to act on"; exit 1; fi

# load: 4 clients, up to 45s
kubectl exec -n "$NS" probe -- sh -c 'rm -f /tmp/stop /tmp/lat; for j in 1 2 3 4; do ( end=$(( $(date +%s) + 45 )); while [ ! -f /tmp/stop ] && [ $(date +%s) -lt $end ]; do curl -s -m 3 -o /dev/null -w "%{time_total} %{http_code}\n" http://checkout.checkout.svc/ >> /tmp/lat; done ) & done; wait' >/dev/null 2>&1 &
lp=$!
reps=$min
end=$((SECONDS+45))
while [ $SECONDS -lt $end ]; do
  d=$(k get hpa checkout -o jsonpath='{.status.desiredReplicas}' 2>/dev/null)
  c=$(k get deploy checkout -o jsonpath='{.spec.replicas}' 2>/dev/null)
  reps=${c:-$min}; [ "${d:-0}" -gt "$reps" ] && reps=$d
  [ "$reps" -gt "$min" ] && break
  sleep 3
done
sleep 5
kubectl exec -n "$NS" probe -- touch /tmp/stop >/dev/null 2>&1
wait $lp 2>/dev/null
if [ "$reps" -gt "$min" ]; then ok "under load the HPA raised the replicas to $reps"; else bad "under load the replica count stayed at $min"; fail=1; fi

stats=$(kubectl exec -n "$NS" probe -- cat /tmp/lat 2>/dev/null | awk '{n++; if ($2==200) g++; t[n]=$1} END {if (n==0) {print "0 0 0"; exit} for(i=1;i<=n;i++) for(j=i+1;j<=n;j++) if (t[j]<t[i]) {x=t[i];t[i]=t[j];t[j]=x} p=int(n*0.95); if (p<1) p=1; printf "%d %d %d\n", n, g, t[p]*1000}')
set -- $stats
n=${1:-0}; g=${2:-0}; p95=${3:-99999}
if [ "$n" -gt 20 ] && [ $((g*100)) -ge $((n*95)) ] && [ "$p95" -lt 1000 ]; then ok "load test: $g of $n requests succeeded, p95 ${p95} ms"; else bad "load test: $g of $n requests succeeded, p95 ${p95} ms (need 95% and under 1000 ms)"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
