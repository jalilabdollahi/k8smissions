# Suspended Schedule

## What Was Broken
The CronJob had `spec.suspend: true`. This pauses the schedule without deleting the CronJob — useful during maintenance windows, but easy to forget.

## The Fix
Set `spec.suspend: false` (or remove the field — false is the default). The CronJob fires on its next scheduled tick.

## Why It Matters
CronJob suspension is a real production tool. The problem is that it is invisible at a glance. `kubectl get cronjob` shows a SUSPEND column but it is easy to miss. Always check `kubectl describe cronjob` when a CronJob produces no Jobs.

## Pro Tip
You can manually trigger a CronJob without waiting for the schedule: `kubectl create job --from=cronjob/<name> manual-run-1 -n <ns>`. Useful for testing or catch-up runs after a suspension.

## Concepts
CronJob, suspend, batch/v1, schedule, manual trigger
