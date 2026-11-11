#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
k() { kubectl -n "$NS" "$@"; }

for j in a b; do
  if ! k get job train-$j >/dev/null 2>&1; then
    echo "❌ Job train-$j is missing"
    exit 1
  fi
  comp=$(k get job train-$j -o jsonpath='{.spec.completions}')
  if [ "${comp:-0}" -ne 3 ]; then
    echo "❌ Job train-$j must keep completions: 3 (found ${comp:-none})"
    exit 1
  fi
done

fail=0
for j in a b; do
  done_c=$(k get job train-$j -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}')
  ok=$(k get job train-$j -o jsonpath='{.status.succeeded}')
  if [ "$done_c" != "True" ] || [ "${ok:-0}" -ne 3 ]; then
    echo "❌ train-$j: not complete yet (${ok:-0} of 3 pods succeeded)"
    fail=1
    continue
  fi
  passes=$(k logs -l job-name=train-$j --tail=-1 2>/dev/null | grep -c "barrier passed with 3 of 3 peers")
  if [ "$passes" -ne 3 ]; then
    echo "❌ train-$j: only $passes of 3 workers passed the barrier with all 3 peers"
    fail=1
    continue
  fi
  echo "✅ train-$j: Complete, 3 of 3 workers passed the barrier with all peers"
done
[ $fail -eq 0 ] && exit 0
exit 1
