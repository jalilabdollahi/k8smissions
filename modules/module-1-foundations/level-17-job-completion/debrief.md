## What was broken

Job `nightly-import` runs three shards one after another, each taking about 12 seconds plus pod start-up. Its spec carried `activeDeadlineSeconds: 25`, a total time budget for the whole Job. After about 25 seconds Kubernetes stopped it with `DeadlineExceeded`, after two shards and while the third was running or about to start.

## The evidence

Pods showed `Completed` and `kubectl logs` showed `shard 1 ok` and `shard 2 ok`, so nothing looked broken. `kubectl describe job nightly-import` listed a `Failed` condition with reason `DeadlineExceeded`, and `kubectl get job -o yaml` showed the deadline of 25 seconds.

## Why Kubernetes behaved this way

`activeDeadlineSeconds` is measured from the moment the Job starts, not per pod, and includes the time between pods. When it passes, the controller terminates the running pods, stops creating new ones and marks the Job `Failed`. That is a final state: a Job controller never starts a failed Job again, and the deadline field cannot be raised after the fact.

## The fix

Delete the Job and recreate it with a deadline that covers all three shards with margin (or none, if `backoffLimit` is enough protection). Keep the manifest in Git; that makes the recreate a one-line change.

## In production

Choose a deadline from measured run times and add headroom for slow image pulls and node pressure. Use `backoffLimit` for retries and `ttlSecondsAfterFinished` to clean up; use a CronJob for the nightly schedule. Alert on Failed Jobs, because the pods look healthy.

## Commands worth remembering

- `kubectl describe job <name>`
- `kubectl get job <name> -o jsonpath='{.status.conditions}'`
- `kubectl logs job/<name>` and `kubectl logs -l job-name=<name>`
