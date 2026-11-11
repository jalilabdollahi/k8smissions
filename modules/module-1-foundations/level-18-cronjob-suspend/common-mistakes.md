## Common mistakes

- **Fixing `suspend` and waiting.** The schedule fires at minute 1 of the hour, so nothing happens for up to an hour. Read the cron expression too.
- **Using `kubectl create job --from=cronjob/close-report`.** It proves the pod template works, but the Job is marked as a manual run and does not show that the schedule works.
- **Treating `* 1 * * *` as "every minute".** The first field is the minute, the second the hour; `* 1 * * *` runs every minute only during hour 1. Count the fields.
- **Deleting and recreating the CronJob without checking the cause.** The new object needs the same two corrections, or it stays silent too.
