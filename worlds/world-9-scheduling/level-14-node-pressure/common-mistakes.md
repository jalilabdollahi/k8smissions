# Common Mistakes — Pressure Evictions

## Mistake 1: Adding more memory limit when already causing pressure

**Wrong approach:** Increasing limit to 4Gi — a higher limit doesn't help if the node runs out of memory

**Correct approach:** Fix the actual memory usage first; right-size the limit after profiling
