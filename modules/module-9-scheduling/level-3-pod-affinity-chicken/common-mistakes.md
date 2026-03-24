# Common Mistakes — Chicken and Egg

## Mistake 1: Deploying the cache pod first as a workaround

**Wrong approach:** Starting a dummy tier:cache pod just to unblock scheduling — it adds an unnecessary workload

**Correct approach:** Use preferred affinity for non-critical co-location preferences
