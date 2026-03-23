# Common Mistakes — Anti-Affinity Trap

## Mistake 1: Reducing replicas to match node count

**Wrong approach:** Setting replicas: 2 to match available nodes — loses desired redundancy

**Correct approach:** Fix the anti-affinity to preferred; then all 3 replicas can run
