# Common Mistakes — Queue Jumped

## Mistake 1: Using node affinity to reserve nodes

**Wrong approach:** Dedicating nodes via affinity for critical pods — complex and inflexible

**Correct approach:** PriorityClass with preemption is simpler and dynamic
