#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy catalog >/dev/null 2>&1; then
  echo "❌ Deployment catalog does not exist"
  exit 1
fi
if ! k rollout status deploy/catalog --timeout=60s >/dev/null 2>&1; then
  echo "❌ catalog has pods that are not Ready yet"
  exit 1
fi
n=$(k get deploy catalog -o jsonpath='{.status.readyReplicas}')
if [ "${n:-0}" -ne 3 ]; then
  echo "❌ catalog: ${n:-0} of 3 pods Ready"
  exit 1
fi
echo "✅ catalog has 3 Ready pods"

victim=$(k get pods -l app=catalog -o jsonpath='{.items[0].metadata.name}')
echo "deleting $victim and watching the Service for 25 seconds..."
k delete pod "$victim" --wait=false >/dev/null 2>&1
out=$(k exec probe -- sh -c 'for i in $(seq 50); do curl -s --max-time 2 -o /dev/null -w "%{http_code}\n" http://catalog; sleep 0.5; done' 2>/dev/null)
total=$(echo "$out" | grep -c .)
bad=$(echo "$out" | grep -vc '^200$')
if [ "$total" -lt 45 ]; then
  echo "❌ the probe pod could not run the request loop"
  exit 1
fi
if [ "$bad" -ne 0 ]; then
  echo "❌ catalog: $bad of $total requests failed while a pod was starting"
  exit 1
fi
echo "✅ catalog: $total of $total requests returned 200 while a pod was replaced"

if ! k rollout status deploy/catalog --timeout=40s >/dev/null 2>&1; then
  echo "❌ the replacement pod never became Ready"
  exit 1
fi
n=$(k get deploy catalog -o jsonpath='{.status.readyReplicas}')
if [ "${n:-0}" -ne 3 ]; then
  echo "❌ catalog: ${n:-0} of 3 pods Ready at the end"
  exit 1
fi
echo "✅ all 3 replicas are Ready again"
exit 0
exit 1
