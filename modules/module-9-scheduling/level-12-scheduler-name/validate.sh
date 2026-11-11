#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

# the custom scheduler must be left alone and running
if [ "$(k get deploy ml-scheduler -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" != "1" ]; then
  echo "❌ Deployment ml-scheduler must stay up (it is the team's scheduler)"
  exit 1
fi
if ! k get configmap ml-scheduler-config -o jsonpath='{.data.config\.yaml}' | grep -q 'schedulerName: ml-scheduler$' ||
   ! k get configmap ml-scheduler-config -o jsonpath='{.data.config\.yaml}' | grep -q MostAllocated; then
  echo "❌ the ml-scheduler profile (name and MostAllocated strategy) must not be changed"
  exit 1
fi
echo "✅ ml-scheduler is running with its profile intact"

rep=$(k get deploy trainer -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${rep:-0}" -ne 4 ]; then
  echo "❌ trainer must keep 4 replicas (found ${rep:-none})"
  exit 1
fi
pods=$(k get pods -l app=trainer -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
running=$(echo "$pods" | jq '[.[] | select(.status.phase=="Running")] | length')
total=$(echo "$pods" | jq length)
if [ "$running" -ne 4 ] || [ "$total" -ne 4 ]; then
  echo "❌ trainer: $running of 4 pods Running ($total pods exist)"
  exit 1
fi
echo "✅ trainer: 4 pods Running"

nodes=$(echo "$pods" | jq -r '[.[].spec.nodeName] | unique | join(",")')
if [ "$(echo "$pods" | jq '[.[].spec.nodeName] | unique | length')" -ne 1 ]; then
  echo "❌ trainer pods are spread over several nodes ($nodes); they should be packed onto one"
  exit 1
fi
if ! workers | grep -qx "$nodes"; then
  echo "❌ trainer pods run on $nodes, which is not a worker"
  exit 1
fi
echo "✅ all trainer pods share worker $nodes"

by=$(echo "$pods" | jq -r '.[].metadata.name' | while read -r p; do
  kubectl -n "$NS" get events --field-selector "involvedObject.name=$p,reason=Scheduled" -o json |
    jq -r '.items[0] | (.reportingComponent // .source.component // "none")'
done | sort -u | tr '\n' ' ')
if [ "$by" != "ml-scheduler " ]; then
  echo "❌ trainer pods were scheduled by: ${by:-nobody recorded}; expected only ml-scheduler"
  exit 1
fi
echo "✅ every Scheduled event comes from ml-scheduler"
exit 0
exit 1
