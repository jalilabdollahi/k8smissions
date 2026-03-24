# Common Mistakes — Suspended Schedule

## Mistake 1: Deleting and recreating

**Wrong approach:** Deleting the CronJob to fix it — this also deletes job history and LAST SCHEDULE time

**Correct approach:** Use kubectl patch or kubectl edit to change just the suspend field

## Mistake 2: Expecting immediate execution after unsuspend

**Wrong approach:** Setting suspend:false then expecting a Job in seconds

**Correct approach:** CronJob waits for the next schedule tick. Use kubectl create job --from=cronjob/<name> to trigger immediately
