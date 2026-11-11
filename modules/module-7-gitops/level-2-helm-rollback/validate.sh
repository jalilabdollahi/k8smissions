#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

hist=$(helm -n "$NS" history webapp -o json 2>/dev/null)
read -r phase rev first <<<"$(echo "$hist" | python3 -c '
import json,sys
h=json.load(sys.stdin)
print(h[-1]["status"], h[-1]["revision"], h[0]["revision"])' 2>/dev/null)"
if [ "${first:-}" != "1" ]; then
  echo "❌ Release history of webapp is gone or incomplete (a reinstall loses it)"
  exit 1
fi
if [ "$phase" != "deployed" ] || [ "${rev:-0}" -le 4 ]; then
  echo "❌ Helm release webapp: latest revision ${rev:-none} is '${phase:-missing}'"
  exit 1
fi
echo "✅ Helm release webapp is deployed at revision $rev, history kept"

ready=$(k get deploy webapp -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment webapp: ${ready:-0} of 2 pods Ready"
  exit 1
fi
restarts=$(k get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '{s+=$1} END {print s+0}')
if [ "$restarts" -ne 0 ]; then
  echo "❌ webapp pods have restarted $restarts times"
  exit 1
fi
echo "✅ 2 webapp pods Ready and not restarting"

sleep 10
restarts=$(k get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '{s+=$1} END {print s+0}')
ready=$(k get deploy webapp -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$restarts" -ne 0 ] || [ "${ready:-0}" -ne 2 ]; then
  echo "❌ webapp is not stable: $restarts restarts, ${ready:-0} Ready after 10s"
  exit 1
fi

out=$(k exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 http://webapp; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^webapp v2: checkout ready$')
if [ "$good" -ne 20 ]; then
  echo "❌ webapp: only $good of 20 requests returned the last working payload"
  exit 1
fi
echo "✅ webapp: 20 of 20 requests returned 'webapp v2: checkout ready'"
exit 0
exit 1
