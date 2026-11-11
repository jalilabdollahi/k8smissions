#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

orig_rep=$(k get configmap reserve-plan -o jsonpath='{.data.replicas}' 2>/dev/null)
orig_cpu=$(k get configmap reserve-plan -o jsonpath='{.data.cpu-per-pod-m}' 2>/dev/null)
if [ -z "$orig_rep" ] || ! k get deploy capacity-reserve >/dev/null 2>&1; then
  echo "❌ Deployment capacity-reserve must stay (it is the headroom policy)"
  exit 1
fi
rep=$(k get deploy capacity-reserve -o jsonpath='{.spec.replicas}')
if [ "$((rep * 2))" -lt "$orig_rep" ]; then
  echo "❌ capacity-reserve was cut to $rep of $orig_rep replicas; it must keep at least half"
  exit 1
fi

rdy=$(k get deploy checkout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${rdy:-0}" -ne 4 ] || [ "$(k get deploy checkout -o jsonpath='{.spec.replicas}')" -ne 4 ]; then
  echo "❌ checkout: ${rdy:-0} of 4 replicas Ready"
  exit 1
fi
echo "✅ checkout: 4 replicas Ready"

cpu=$(k get deploy capacity-reserve -o json | jq -r '.spec.template.spec.containers[0].resources.requests.cpu // "0"')
cpu_m=$(cpu_to_m "$cpu")
rp=$(k get pods -l app=capacity-reserve -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null) | .spec.priority // 0] | max // 0')
cp=$(k get pods -l app=checkout -o json | jq '[.items[] | .spec.priority // 0] | min // 0')
if [ "$rp" -lt "$cp" ]; then
  echo "✅ the placeholder pods have lower priority ($rp) than checkout ($cp)"
elif [ "$((rep * cpu_m))" -lt "$((orig_rep * orig_cpu))" ]; then
  echo "✅ the placeholder reservation was reduced to $((rep * cpu_m))m"
else
  echo "❌ capacity-reserve neither yields to checkout nor reserves less than before"
  exit 1
fi
echo "✅ capacity-reserve still exists with $rep placeholder replicas"
exit 0
exit 1
