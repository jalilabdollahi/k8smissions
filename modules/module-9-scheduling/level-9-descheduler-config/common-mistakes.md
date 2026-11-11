## Fixing the first error and stopping there

Moving the plugin to `balance` makes the Job turn green, so it looks solved. The log still has no `Evicted pod` lines: the thresholds are the second problem, and only a Job that logs evictions counts.

## Raising `thresholds` above `targetThresholds`

The Descheduler rejects a policy where a threshold exceeds its target (underutilized would overlap overutilized). Keep thresholds clearly below the targets.

## Waiting for the CronJob to pick the change up

A Job reads the ConfigMap when it starts, and the CronJob uses `concurrencyPolicy: Forbid`, so a slow or failed run can delay the next one. Start a Job yourself with `kubectl create job --from=cronjob/descheduler`, and remember that deleting pods by hand is not what this level is about.
