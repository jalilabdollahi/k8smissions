#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get cronjob data-processor >/dev/null 2>&1; then
  echo "❌ CronJob data-processor does not exist"
  exit 1
fi
if [ "$(k get cronjob data-processor -o jsonpath='{.spec.suspend}')" = "true" ]; then
  echo "❌ data-processor is suspended; the batch must keep running"
  exit 1
fi
sched=$(k get cronjob data-processor -o jsonpath='{.spec.schedule}')
if [ "$sched" != "* * * * *" ]; then
  echo "❌ the schedule changed to '$sched'; the batch team wants every minute"
  exit 1
fi
policy=$(k get cronjob data-processor -o jsonpath='{.spec.concurrencyPolicy}')
if [ -z "$policy" ] || [ "$policy" = "Allow" ]; then
  echo "❌ nothing stops a new run from starting while the previous one is still going"
  exit 1
fi
echo "✅ data-processor is scheduled every minute and not suspended"

active_pods() {  # STATUS column is Terminating for pods being deleted, so those are not counted
  k get pods -l app=data-processor --no-headers 2>/dev/null \
    | awk '$3=="Running" || $3=="Pending" || $3=="ContainerCreating" || $3=="PodInitializing" || $3 ~ /^Init:/ {c++} END {print c+0}'
}
n=$(active_pods)
if [ "$n" -gt 1 ]; then
  echo "❌ $n data-processor pods are running at the same time"
  exit 1
fi
echo "✅ no more than one data-processor pod is running"

# Prove the CronJob keeps working: a run must exist, or the next minute must start one.
for _ in $(seq 33); do
  if [ "$(active_pods)" -ge 1 ]; then
    echo "✅ data-processor is running its schedule"
    n=$(active_pods)
    if [ "$n" -gt 1 ]; then echo "❌ $n pods running at once"; exit 1; fi
    exit 0
  fi
  sleep 2
done
echo "❌ data-processor never started a new run within a minute"
exit 1
