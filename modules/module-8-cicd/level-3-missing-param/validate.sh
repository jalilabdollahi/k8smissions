#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline deploy-notify >/dev/null 2>&1; then
  echo "❌ Pipeline deploy-notify does not exist"
  exit 1
fi

runs=$(k get pipelinerun -l tekton.dev/pipeline=deploy-notify -o name 2>/dev/null | sed 's|.*/||' | grep -v '^notify-prod-9$')
if [ -z "$runs" ]; then
  echo "❌ no new PipelineRun of deploy-notify yet (notify-prod-9 is the old failed one)"
  exit 1
fi

good=""
for r in $runs; do
  st=$(k get pipelinerun "$r" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  if [ "$st" = "True" ]; then good=$r; break; fi
  why=$(k get pipelinerun "$r" -o jsonpath='{.status.conditions[0].reason}' 2>/dev/null)
  last="$r ended ${why:-without a result}"
done
if [ -z "$good" ]; then
  echo "❌ none of the new runs has Succeeded yet ($last)"
  exit 1
fi
echo "✅ PipelineRun $good Succeeded"

tr=$(k get taskrun -l "tekton.dev/pipelineRun=$good,tekton.dev/pipelineTask=notify" -o jsonpath='{.items[0].status.podName}')
log=$(k logs "$tr" -c step-send 2>/dev/null)
if ! echo "$log" | grep -qx 'env=prod'; then
  echo "❌ the notify step did not run for env=prod (log says: $(echo "$log" | grep '^env=' | head -1))"
  exit 1
fi
for t in slack-payments pager-oncall email-finance; do
  if ! echo "$log" | grep -qx "notified $t"; then
    echo "❌ no 'notified $t' line in the log of run $good"
    exit 1
  fi
done
if [ "$(echo "$log" | grep -c '^notified ')" != "3" ]; then
  echo "❌ the log has $(echo "$log" | grep -c '^notified ') notified lines, expected exactly 3 (one per target)"
  exit 1
fi
echo "✅ env=prod and all three targets were notified separately"
exit 0
exit 1
