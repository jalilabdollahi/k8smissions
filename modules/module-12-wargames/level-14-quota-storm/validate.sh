#!/bin/bash
CI=ci
k() { kubectl -n "$CI" "$@"; }
ok()  { echo "✅ $*"; }
bad() { echo "❌ $*"; }
fail=0

if ! k get resourcequota ci-quota >/dev/null 2>&1; then bad "ResourceQuota ci-quota is gone; the limits stay"; exit 1; fi
jobs_hard=$(k get resourcequota ci-quota -o jsonpath='{.spec.hard.count/jobs\.batch}')
cpu_hard=$(k get resourcequota ci-quota -o jsonpath='{.spec.hard.requests\.cpu}')
if [ "$jobs_hard" = 20 ] && [ "$cpu_hard" = 1 ]; then ok "ci-quota keeps its limits (20 Jobs, 1 CPU)"; else bad "ci-quota limits were changed (jobs=$jobs_hard cpu=$cpu_hard)"; exit 1; fi

for d in ci-retrier release-driver; do
  n=$(k get deploy "$d" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  [ "${n:-0}" -ge 1 ] || { bad "Deployment $d must keep running"; fail=1; }
done
[ "$fail" = 0 ] && ok "ci-retrier and release-driver are running"

for r in release-v40 release-v41; do
  k get job "$r" >/dev/null 2>&1 || { bad "Job $r was deleted; releases are kept"; fail=1; }
done

# the stuck run must be stopped
running=$(k get pods -l job-name=flaky-suite -o json 2>/dev/null | jq '[.items[] | select(.status.phase=="Running" or .status.phase=="Pending")] | length')
if [ "${running:-0}" = 0 ]; then ok "flaky-suite is no longer running"; else bad "flaky-suite still has a running pod"; fail=1; fi

# release-v42 appears (driver creates it once quota allows) and completes
for i in $(seq 1 10); do k get job release-v42 >/dev/null 2>&1 && break; sleep 2; done
if k get job release-v42 >/dev/null 2>&1; then
  if k wait --for=condition=complete job/release-v42 --timeout=40s >/dev/null 2>&1; then ok "release-v42 completed"; else bad "release-v42 exists but has not completed"; fail=1; fi
else
  bad "release-v42 was never created (quota still full?)"; fail=1
fi

# new retry Jobs must expire by themselves
good=""
for i in $(seq 1 10); do
  good=$(k get jobs -l created-by=ci-retrier -o json 2>/dev/null | jq -r '[.items[] | select(.metadata.name | startswith("retry-old-") | not) | select(.spec.ttlSecondsAfterFinished != null and .spec.ttlSecondsAfterFinished >= 1 and .spec.ttlSecondsAfterFinished <= 120)] | length')
  [ "${good:-0}" -ge 1 ] && break
  sleep 3
done
if [ "${good:-0}" -ge 1 ]; then ok "new retry Jobs carry a TTL of 120s or less"; else bad "no new retry Job with a ttlSecondsAfterFinished of 1-120 seconds yet"; fail=1; fi

used=$(k get resourcequota ci-quota -o jsonpath='{.status.used.count/jobs\.batch}')
if [ "${used:-20}" -le 17 ]; then ok "quota has headroom ($used of 20 Jobs used)"; else bad "quota still nearly full ($used of 20 Jobs used)"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
