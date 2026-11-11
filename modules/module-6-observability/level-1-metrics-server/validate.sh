#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy capacity-report -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
restarts=$(k get pods -l app=capacity-report -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' 2>/dev/null | sort -n | tail -1)
if [ "${ready:-0}" -ne 1 ] || [ "${restarts:-0}" -ne 0 ]; then
  echo "❌ capacity-report: ready=${ready:-0}, restarts=${restarts:-?}; it must be Running and stable"
  exit 1
fi
echo "✅ capacity-report is Running with no restarts"

sa="system:serviceaccount:$NS:capacity-report"
if [ "$(k auth can-i get pods.metrics.k8s.io --as="$sa" 2>/dev/null)" != "yes" ] || \
   [ "$(k auth can-i get secrets --as="$sa" 2>/dev/null)" != "no" ]; then
  echo "❌ capacity-report's service account must read pod metrics and nothing else sensitive"
  exit 1
fi
echo "✅ service account permissions are unchanged and minimal"

script=$(k get cm capacity-report -o jsonpath='{.data.report\.py}' 2>/dev/null)
if ! echo "$script" | grep -q '/apis/' || ! echo "$script" | grep -q 'serviceaccount/token\|serviceaccount/'; then
  echo "❌ the report script no longer calls the cluster API with its service account"
  exit 1
fi
echo "✅ the report still queries the API itself"

lines=$(k logs -l app=capacity-report --tail=40 2>/dev/null | grep -E '^usage pod=ledger-api-[a-z0-9-]+ container=api cpu=[0-9]+m mem=[0-9]+Ki$')
if [ -z "$lines" ]; then
  last=$(k logs -l app=capacity-report --tail=1 2>/dev/null)
  echo "❌ no usage lines for ledger-api in the report log yet (last line: ${last:-empty})"
  exit 1
fi
bad=0
while read -r _ pod _ _ mem; do
  name=${pod#pod=}
  kib=${mem#mem=}; kib=${kib%Ki}
  if ! k get pod "$name" >/dev/null 2>&1 || [ "$kib" -lt 500 ]; then bad=1; fi
done <<< "$lines"
if [ "$bad" -ne 0 ]; then
  echo "❌ the log lines do not describe live ledger-api pods"
  exit 1
fi
echo "✅ the log reports live usage for the ledger-api pods"
exit 0
exit 1
