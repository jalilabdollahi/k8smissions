#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get job nightly-import >/dev/null 2>&1; then
  echo "❌ Job nightly-import does not exist"
  exit 1
fi

state=""
for i in $(seq 1 18); do
  failed=$(k get job nightly-import -o jsonpath='{.status.conditions[?(@.type=="Failed")].status}' 2>/dev/null)
  done_=$(k get job nightly-import -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null)
  if [ "$failed" = "True" ]; then state=failed; break; fi
  if [ "$done_" = "True" ]; then state=complete; break; fi
  sleep 3
done
if [ "$state" = "failed" ]; then
  reason=$(k get job nightly-import -o jsonpath='{.status.conditions[?(@.type=="Failed")].reason}')
  echo "❌ Job nightly-import is Failed ($reason)"
  exit 1
fi
if [ "$state" != "complete" ]; then
  echo "❌ Job nightly-import is not Complete yet ($(k get job nightly-import -o jsonpath='{.status.succeeded}')/3 succeeded)"
  exit 1
fi
succ=$(k get job nightly-import -o jsonpath='{.status.succeeded}')
if [ "${succ:-0}" -ne 3 ]; then
  echo "❌ Job nightly-import has $succ of 3 completions"
  exit 1
fi
echo "✅ Job nightly-import is Complete with 3 of 3 completions"

logs=$(k logs -l job-name=nightly-import --tail=-1 2>/dev/null)
for s in 1 2 3; do
  if ! echo "$logs" | grep -q "shard $s ok"; then
    echo "❌ no 'shard $s ok' in the Job's pod logs"
    exit 1
  fi
done
echo "✅ shards 1, 2 and 3 are all imported"
exit 0
exit 1
