## What was broken

CronJob `close-report` had two faults. Its `spec.suspend` was `true`, left over from an incident, so the controller created nothing. And its schedule `1 * * * *` means minute 1 of every hour, not every minute, so even an active CronJob would create a Job once an hour.

## The evidence

`kubectl get cronjob` printed `SUSPEND True` and `LAST SCHEDULE <none>`: the CronJob had never fired. After flipping suspend, `kubectl describe cronjob` and the manifest showed the cron expression, and reading its five fields (minute, hour, day of month, month, day of week) showed it fired only at minute 1.

## Why Kubernetes behaved this way

The CronJob controller creates a Job whenever the schedule says one is due and `suspend` is false; a suspended CronJob keeps its history but is silent. The field order of a cron expression starts with the minute, so `1 * * * *` and `* * * * *` look alike but behave very differently. Jobs created by the controller carry an owner reference to the CronJob; a manual `kubectl create job --from=cronjob/...` is just a test.

## The fix

`kubectl patch cronjob close-report -p '{"spec":{"suspend":false,"schedule":"* * * * *"}}'`. The next Job appears at the next minute boundary and runs to Complete.

## In production

Record why something was suspended, and who resumes it, in the ticket (here an annotation did). A minute-long cadence needs a `concurrencyPolicy` (`Forbid` here) and history limits so Jobs do not pile up. Cron times are in UTC unless `timeZone` is set.

## Commands worth remembering

- `kubectl get cronjob` (SUSPEND, LAST SCHEDULE)
- `kubectl patch cronjob <name> -p '{"spec":{"suspend":false}}'`
- `kubectl get jobs --watch`
