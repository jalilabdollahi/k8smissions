#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get cronjob close-report >/dev/null 2>&1; then
  echo "❌ CronJob close-report does not exist"
  exit 1
fi
susp=$(k get cronjob close-report -o jsonpath='{.spec.suspend}')
if [ "$susp" = "true" ]; then
  echo "❌ CronJob close-report is still suspended"
  exit 1
fi
echo "✅ close-report is not suspended"

found=""
for i in $(seq 1 24); do
  found=$(k get jobs -o json 2>/dev/null | python3 -c '
import json,sys
for j in json.load(sys.stdin)["items"]:
    refs=[r for r in j["metadata"].get("ownerReferences",[]) if r["kind"]=="CronJob" and r["name"]=="close-report"]
    manual=j["metadata"].get("annotations",{}).get("cronjob.kubernetes.io/instantiate")=="manual"
    done=any(c["type"]=="Complete" and c["status"]=="True" for c in j.get("status",{}).get("conditions",[]))
    if refs and not manual and done:
        print(j["metadata"]["name"]); break')
  [ -n "$found" ] && break
  sleep 3
done
if [ -z "$found" ]; then
  last=$(k get cronjob close-report -o jsonpath='{.status.lastScheduleTime}')
  echo "❌ no Job created by close-report's schedule has completed (last schedule: ${last:-never})"
  exit 1
fi
echo "✅ the schedule created Job $found and it Completed"
exit 0
exit 1
