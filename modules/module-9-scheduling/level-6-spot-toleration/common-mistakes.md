# Common Mistakes — Spot Survivor

## Mistake 1: Running spot-only workloads without fallback

**Wrong approach:** Not tolerating on-demand taints — entire service goes down when spot nodes are reclaimed

**Correct approach:** Always design for spot eviction with on-demand fallback for critical paths
