# Common Mistakes — Manual Block

## Mistake 1: Force-deleting the pipeline run

**Wrong approach:** kubectl delete --force on a running TaskRun can leave orphaned pods

**Correct approach:** Cancel cleanly first, then recreate
