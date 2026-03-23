# Common Mistakes — Class Not Found

## Mistake 1: Using old device plugin model

**Wrong approach:** Requesting nvidia.com/gpu in limits — this is the device plugin model, not DRA

**Correct approach:** DRA uses ResourceClaims; device plugins use extended resources in limits; don't mix them
