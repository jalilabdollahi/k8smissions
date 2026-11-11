## What was broken

`data-processor` fires every minute and each run lasts about three minutes. With `concurrencyPolicy: Allow`, the default, the CronJob starts a new Job on schedule no matter what is still running, so the runs stacked up and used more memory every minute.

## The evidence

`get cronjob` showed several active Jobs, `get jobs` listed runs created one minute apart that were all unfinished, and `get pods` showed one pod per Job. `kubectl explain cronjob.spec.concurrencyPolicy` describes the three behaviours.

## Why Kubernetes behaves this way

The CronJob controller only creates Jobs; it never looks at what they do. Pods belong to Jobs, and Jobs belong to the CronJob through `ownerReferences`, so deleting a pod just makes the Job start another one. Only deleting the Job removes its pods for good.

## The fix

Set `concurrencyPolicy` to `Forbid` (skip the new run while one is active) or `Replace` (cancel the old run for the new one), then delete the stale Jobs. Suspending would also stop the flood, but also stops the batch, which the team did not accept.

## In production

Choose the policy from the workload: `Forbid` for jobs that must finish, `Replace` for idempotent ones that only need the newest data. Also set `activeDeadlineSeconds` so a stuck run cannot block `Forbid` forever, and alert when scheduled runs are skipped.

## Commands worth remembering

- `kubectl get cronjob,jobs,pods`
- `kubectl explain cronjob.spec.concurrencyPolicy`
- `kubectl delete job <name>`
