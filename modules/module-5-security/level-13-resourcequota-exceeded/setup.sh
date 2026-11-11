#!/bin/bash
# A nightly CronJob that keeps 20 finished runs, eight of which already exist,
# and an object-count quota that was filled by them.
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

k apply -f - <<'YAML'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: price-sync
spec:
  schedule: "0 3 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 20
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        metadata:
          labels: {app: price-sync}
        spec:
          restartPolicy: Never
          containers:
          - name: sync
            image: busybox:1.36
            command: ["sh", "-c", "echo synced 1832 prices"]
YAML

for i in 1 2 3 4 5 6 7 8; do
  k create job "price-sync-2711$i" --from=cronjob/price-sync >/dev/null
done
for i in 1 2 3 4 5 6 7 8; do
  k wait --for=condition=complete "job/price-sync-2711$i" --timeout=90s >/dev/null || exit 1
done

k apply -f - <<'YAML'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-counts
spec:
  hard:
    count/pods: "10"
YAML
# wait until the quota controller has counted the 8 finished pods
for i in $(seq 1 30); do
  used=$(k get quota object-counts -o jsonpath='{.status.used.count/pods}' 2>/dev/null)
  [ "${used:-0}" -ge 8 ] && exit 0
  sleep 1
done
echo "quota did not report usage" >&2
exit 1
