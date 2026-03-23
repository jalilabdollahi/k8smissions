# Common Mistakes — The Flood

## Mistake 1: Deleting all the pods manually

**Wrong approach:** Manually deleting pods without fixing the CronJob — new pods appear immediately

**Correct approach:** Fix concurrencyPolicy first, then clean up stale pods

## Mistake 2: Using Replace when idempotency matters

**Wrong approach:** Replace kills the current run; if the job is a DB migration this causes partial writes

**Correct approach:** Use Forbid for non-idempotent jobs that must not overlap
