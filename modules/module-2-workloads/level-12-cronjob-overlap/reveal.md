## What went wrong

`concurrencyPolicy: Allow` + a 120-second job on a 60-second schedule = each minute starts a new job while the last one is still running. After 10 minutes there are 10 concurrent pods. After an hour, 60. The cluster eventually runs out of resources.

## Fix

In manifest.yaml:

```yaml
spec:
  concurrencyPolicy: Forbid
```

## The three concurrencyPolicy values

- `Allow` — run concurrent jobs (the default; fine if jobs are short and idempotent)
- `Forbid` — skip the new run if the previous one is still running
- `Replace` — cancel the previous run and start a new one

For jobs that must not run in parallel (database exports, report generators), always use `Forbid`.