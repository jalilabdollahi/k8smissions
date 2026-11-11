## Changing the DBA values

Editing `sync.py` so the policies fit the schema (retention 30, schedule `0 * * * *`) makes the Job pass, but the DBAs asked for 14 days and every 20 minutes. The validator compares every value with the original. The schema is the thing that is wrong, not the data.

## Deleting the schema or switching validation off

Removing the `pattern` and the `minimum` (or the whole `openAPIV3Schema`) lets the policies in and breaks the platform team's reason for tightening in the first place. Keep a minimum of 1 and a pattern that still refuses text that is not a cron expression.

## Stopping after the first fix

After the `minimum` is lowered the Job will still be failing, now on `hourly-wal`. The Job stops at the first rejection, so always re-read the log after each change and keep going until the policies exist.
