#!/bin/bash
NS=${NS:-k8smissions}
S=shop-staging
P=shop-prod

left=$(kubectl -n $S get deploy,hpa,pdb,svc -o name 2>/dev/null | grep '/prod-')
if [ -n "$left" ]; then
  echo "❌ $S still holds production objects: $(echo $left)"
  exit 1
fi
if ! kubectl get ns $S >/dev/null 2>&1; then
  echo "❌ namespace $S does not exist"
  exit 1
fi
echo "✅ no prod- objects left in $S"

ready=$(kubectl -n $S get deploy stg-checkout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ stg-checkout: ${ready:-0} of 2 pods Ready"
  exit 1
fi
echo "✅ stg-checkout has 2 Ready pods"

out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 http://stg-checkout.shop-staging; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^checkout staging$')
if [ "$good" -ne 20 ]; then
  echo "❌ stg-checkout: only $good of 20 requests returned the staging page"
  exit 1
fi
echo "✅ Service stg-checkout answers 20 of 20 requests"

pr=$(kubectl -n $P get deploy prod-checkout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${pr:-0}" -ne 4 ] || ! kubectl -n $P get hpa prod-checkout >/dev/null 2>&1 || ! kubectl -n $P get pdb prod-checkout >/dev/null 2>&1; then
  echo "❌ production in $P is damaged: ${pr:-0} of 4 pods Ready, HPA or PDB missing?"
  exit 1
fi
pout=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 10); do curl -s --max-time 2 http://prod-checkout.shop-prod; echo; done' 2>/dev/null | grep -c '^checkout production$')
if [ "$pout" -ne 10 ]; then
  echo "❌ production prod-checkout answered only $pout of 10 requests"
  exit 1
fi
echo "✅ production in $P is intact and serving"
exit 0
exit 1
