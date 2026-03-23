# Common Mistakes — Slow Memory Leak

## Mistake 1: Restarting the pod on a schedule

**Wrong approach:** CronJob to delete the pod every hour — hides the leak, doesn't fix it

**Correct approach:** Set a memory limit to contain blast radius; then profile and fix the actual leak
