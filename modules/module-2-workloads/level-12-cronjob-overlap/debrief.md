# The Flood

## What Was Broken
The CronJob's `concurrencyPolicy: Allow` (the default) lets new jobs start regardless of whether the previous one finished. The job sleeps 120s but fires every minute — so jobs pile up geometrically.

## The Fix
Set `concurrencyPolicy: Forbid` to skip new runs while one is active, or `Replace` to cancel the running job and start fresh. `Forbid` is safest for batch processors that shouldn't run in parallel.

## Why It Matters
CronJob flooding is a real production incident pattern. A slow downstream (DB under load) makes jobs run longer → more overlap → more DB load → positive feedback loop. Monitor `kubectl get pods` count from CronJob labels.

## Pro Tip
Add `successfulJobsHistoryLimit: 3` and `failedJobsHistoryLimit: 1` to prevent thousands of completed/failed Job objects accumulating in etcd.

## Concepts
CronJob, concurrencyPolicy, Forbid, Replace, Allow, batch pile-up
