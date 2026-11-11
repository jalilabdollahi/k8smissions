#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
CRD=backuppolicies.dba.acme.io

if ! kubectl get crd $CRD >/dev/null 2>&1; then
  echo "❌ the BackupPolicy CRD is missing"
  exit 1
fi

# 1. the DBA policies exist with their original values
bad=0
for row in "nightly-db 14 warm" "hourly-wal 7 hot" "weekly-archive 90 cold"; do
  set -- $row
  got=$(k get backuppolicy "$1" -o jsonpath='{.spec.retentionDays}/{.spec.tier}' 2>/dev/null)
  if [ "$got" != "$2/$3" ]; then
    echo "❌ BackupPolicy $1 is missing or its values changed (found '${got:-nothing}')"
    bad=1
  fi
done
sched=$(k get backuppolicy hourly-wal -o jsonpath='{.spec.schedule}' 2>/dev/null)
if [ "$bad" = 0 ] && [ "$sched" != "*/20 * * * *" ]; then
  echo "❌ hourly-wal schedule was changed (found '$sched')"
  bad=1
fi
[ "$bad" = 0 ] && echo "✅ the three DBA policies exist with their original values"
[ "$bad" = 0 ] || exit 1

# 2. the sync Job finished
if [ "$(k get job policy-sync -o jsonpath='{.status.succeeded}' 2>/dev/null)" != "1" ]; then
  echo "❌ Job policy-sync has not completed"
  exit 1
fi
echo "✅ Job policy-sync completed"

# 3. validation is still enforced, and sensible values are still accepted
try() {  # try <retentionDays> <schedule> <tier>: prints "ok" or "rejected"
  if k create --dry-run=server -f - >/dev/null 2>&1 <<Y
apiVersion: dba.acme.io/v1
kind: BackupPolicy
metadata: {name: probe-policy}
spec: {retentionDays: $1, schedule: "$2", tier: $3}
Y
  then echo ok; else echo rejected; fi
}
fail=0
[ "$(try 0 '0 2 * * *' warm)" = rejected ] || { echo "❌ a policy with retentionDays 0 is accepted"; fail=1; }
[ "$(try -5 '0 2 * * *' warm)" = rejected ] || { echo "❌ a policy with negative retentionDays is accepted"; fail=1; }
[ "$(try 7 'whenever you like' warm)" = rejected ] || { echo "❌ a schedule that is not cron is accepted"; fail=1; }
[ "$(try 7 '0 2 * * *' plasma)" = rejected ] || { echo "❌ an unknown tier is accepted"; fail=1; }
[ "$fail" = 0 ] && echo "✅ the schema still rejects invalid policies"
[ "$(try 7 '*/5 * * * *' warm)" = ok ] || { echo "❌ a valid policy with a step schedule (*/5) is rejected"; fail=1; }
[ "$(try 3 '15 */6 * * 1' cold)" = ok ] || { echo "❌ a valid policy with retentionDays 3 is rejected"; fail=1; }
[ "$fail" = 0 ] || exit 1
echo "✅ valid policies are accepted"
exit 0
exit 1
