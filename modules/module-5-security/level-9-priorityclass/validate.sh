#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

# the guard rails the team set: batch stays as configured and as low as before
orig=$(k get deploy batch-reindex -o jsonpath='{.metadata.annotations.k8smissions/original-replicas}' 2>/dev/null)
now=$(k get deploy batch-reindex -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ -z "$now" ] || [ "$now" != "${orig:-2}" ]; then
  echo "❌ batch-reindex must keep its ${orig:-2} replicas (found: ${now:-deleted})"
  exit 1
fi
bl=$(kubectl get priorityclass batch-low -o jsonpath='{.value}' 2>/dev/null)
if [ "$bl" != "1000" ] || [ "$(k get deploy batch-reindex -o jsonpath='{.spec.template.spec.priorityClassName}')" != "batch-low" ]; then
  echo "❌ batch-low and batch-reindex's use of it must stay as they were"
  exit 1
fi
echo "✅ batch-reindex still configured with ${now} replicas under batch-low (1000)"

if [ -n "$(kubectl get priorityclass -o jsonpath='{range .items[?(@.globalDefault==true)]}{.metadata.name}{"\n"}{end}')" ]; then
  echo "❌ a PriorityClass is globalDefault: every pod without a class would now outrank batch work"
  exit 1
fi

# the class checkout really runs under
if ! k get deploy checkout >/dev/null 2>&1; then
  echo "❌ Deployment checkout does not exist"
  exit 1
fi
cls=$(k get deploy checkout -o jsonpath='{.spec.template.spec.priorityClassName}')
val=$(kubectl get priorityclass "$cls" -o jsonpath='{.value}' 2>/dev/null)
pol=$(kubectl get priorityclass "$cls" -o jsonpath='{.preemptionPolicy}' 2>/dev/null)
if [ -z "$cls" ] || [ -z "$val" ]; then
  echo "❌ checkout uses PriorityClass '${cls:-none}', which does not exist"
  exit 1
fi
if [ "$val" -le 1000 ]; then
  echo "❌ checkout's class $cls (value $val) does not outrank batch-low"
  exit 1
fi
if [ "${pol:-PreemptLowerPriority}" = "Never" ]; then
  echo "❌ checkout's class $cls has preemptionPolicy Never: it will wait for room instead of making it"
  exit 1
fi
echo "✅ checkout runs under $cls (value $val, preemptionPolicy ${pol:-PreemptLowerPriority})"

if ! k rollout status deploy/checkout --timeout=45s >/dev/null 2>&1; then
  ready=$(k get deploy checkout -o jsonpath='{.status.readyReplicas}')
  echo "❌ checkout has ${ready:-0} of 3 pods Ready"
  exit 1
fi
bad=$(k get pods -l app=checkout -o json | jq -r '[.items[] | select(.spec.priorityClassName!="'"$cls"'" or .status.phase!="Running")] | length')
total=$(k get pods -l app=checkout --no-headers | wc -l)
if [ "$total" -ne 3 ] || [ "$bad" -ne 0 ]; then
  echo "❌ checkout: expected 3 Running pods under $cls, found $total pods ($bad not matching)"
  exit 1
fi
echo "✅ 3 of 3 checkout pods Running"
exit 0
exit 1
