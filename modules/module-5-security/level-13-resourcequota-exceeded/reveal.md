**Fix**

1. `kubectl -n k8smissions describe quota object-counts` shows `count/pods 10 / 10`; `get pods --field-selector=status.phase=Succeeded` shows 8 finished `price-sync` pods that count against it.
2. The CronJob keeps 20 finished Jobs (`successfulJobsHistoryLimit: 20`). Bound it:
   `kubectl -n k8smissions patch cronjob price-sync --type=merge -p '{"spec":{"successfulJobsHistoryLimit":2,"jobTemplate":{"spec":{"ttlSecondsAfterFinished":3600}}}}'`
3. Free the room now: `kubectl -n k8smissions get jobs -o name | xargs kubectl -n k8smissions delete` (pods are removed with their Jobs; the CronJob controller would also prune down to the new limit by itself).
4. The ReplicaSet backs off after repeated quota failures, so `kubectl -n k8smissions rollout restart deploy/catalog-web` gives it a fresh start; `rollout status` then shows 3 pods.

Do not raise the quota: it is the team's guard rail.
