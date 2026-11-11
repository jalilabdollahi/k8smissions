## Deleting the pods

The Jobs notice and create replacement pods (or the CronJob keeps adding Jobs), so the number never drops. The pods are the last link in the chain; the Jobs and the policy are what to change.

## Suspending the CronJob

`suspend: true` stops new Jobs, but the batch no longer runs, and the check treats a suspended CronJob as failure. The goal is one run at a time, not none.

## Changing only the policy

`Forbid` or `Replace` prevent new pile-ups, but the four runs that already exist keep running to completion unless their Jobs are deleted.
