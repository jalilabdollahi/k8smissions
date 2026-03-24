# Common Mistakes — Sudden Eviction

## Mistake 1: Adding NoSchedule toleration only

**Wrong approach:** NoSchedule prevents new pods from landing but doesn't stop eviction of running pods

**Correct approach:** NoExecute toleration is needed to prevent eviction of running pods
