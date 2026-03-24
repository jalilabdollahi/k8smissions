# Common Mistakes — Deployment Takes Hours

## Mistake 1: Using Recreate strategy for speed

**Wrong approach:** Recreate terminates all pods then starts new ones — complete downtime during deployment

**Correct approach:** RollingUpdate with high maxSurge gives both speed and zero-downtime
