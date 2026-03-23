# Common Mistakes — Uneven Spread

## Mistake 1: Using podAntiAffinity instead

**Wrong approach:** podAntiAffinity with requiredDuringScheduling blocks all placement when replicas > nodes

**Correct approach:** TopologySpreadConstraint is more flexible for HA — use affinity for hard co-location rules
