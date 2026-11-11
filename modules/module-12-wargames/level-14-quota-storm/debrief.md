**What was broken.** Two quotas were exhausted by two different things. `count/jobs.batch` was full of finished test Jobs that nothing removed, because `ci-retrier` creates its Jobs without a TTL. `requests.cpu` was mostly held by `flaky-suite`, a run stuck waiting for a database for hours, so even with a free Job slot the pod of `release-v42` could not be admitted.

**The evidence.** `describe resourcequota ci-quota` lists Used and Hard for both limits. The release driver's log printed `exceeded quota: ci-quota, requested: count/jobs.batch=1, used: 20, limited: 20`, and later the Job's events showed `exceeded quota ... requests.cpu`. `get jobs --show-labels` separated the audit-trail releases from retries.

**Why Kubernetes behaved this way.** ResourceQuota is enforced at admission: an object that would exceed a limit is rejected, and the controller that tried to create it simply retries. Finished Jobs keep counting (and keep their pods) until someone deletes them, unless `ttlSecondsAfterFinished` makes the TTL controller do it. Pods belong to their Job, so removing pods by hand changes nothing.

**The fix.** Give the retrier's Jobs a short TTL first, then delete the finished retry Jobs by label (not the releases), and delete the stuck `flaky-suite` so its CPU request and Job slot are released.

**In production.** Set `ttlSecondsAfterFinished` and `activeDeadlineSeconds` on every CI Job, keep history with `successfulJobsHistoryLimit` on CronJobs, alert on quota usage above 80%, and give release pipelines their own namespace or `PriorityClass`.

**Commands to remember.** `kubectl describe resourcequota`, `kubectl get jobs --show-labels`, `kubectl delete job -l <selector>`, `kubectl set env deploy/<name> VAR=value`.
