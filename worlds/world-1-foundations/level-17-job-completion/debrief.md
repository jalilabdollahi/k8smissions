# One-Shot Task

## What Was Broken
The Job's container ran `/scripts/init-db.sh` which doesn't exist in the busybox image. Exit code 127 (command not found). With `backoffLimit: 2` Kubernetes retried twice then marked the Job Failed.

## The Fix
Fix the command to something that exits 0. In real scenarios build an image that contains the script, or use an initContainer pattern for database migrations.

## Why It Matters
Jobs are for one-off tasks: DB migrations, batch processing, certificate rotation. A failed Job stays in Failed state permanently after exceeding backoffLimit — it does not auto-delete. Check `kubectl get job` and `kubectl logs` on the completed/failed pods.

## Pro Tip
Use `kubectl get pods -l job-name=<name>` to find a Job's pods — the Job name is added as a label automatically. For failed jobs, `kubectl get job -o jsonpath='{.status.conditions}'` shows exactly why it failed.

## Concepts
Job, backoffLimit, restartPolicy, exit codes, batch workloads
