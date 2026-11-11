1. `kubectl get cronjob close-report` shows `SUSPEND True` and `LAST SCHEDULE <none>`.
2. Unsuspending alone is not enough: the schedule `1 * * * *` means minute 1 of every hour, so the first Job could be up to an hour away.
3. Patch both: `kubectl patch cronjob close-report -p '{"spec":{"suspend":false,"schedule":"* * * * *"}}'`.
4. At the start of the next minute a Job named `close-report-<number>` appears and completes; `LAST SCHEDULE` gets a time.
