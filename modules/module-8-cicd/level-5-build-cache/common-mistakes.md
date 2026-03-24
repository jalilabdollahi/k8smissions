# Common Mistakes — No Cache Hit

## Mistake 1: Using emptyDir for cache

**Wrong approach:** Using emptyDir for the cache workspace — emptyDir is deleted after the TaskRun

**Correct approach:** Use a PVC for cache workspaces so data persists between runs
