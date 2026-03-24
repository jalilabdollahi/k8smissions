# Common Mistakes — Phantom Capacity

## Mistake 1: Adding more replicas to spread load

**Wrong approach:** Scaling the Deployment — 5Gi request on any single node still fails

**Correct approach:** Fix the request size first; scaling doesn't help if the individual pod request is too large
