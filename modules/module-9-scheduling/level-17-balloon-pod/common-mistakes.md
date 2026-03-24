# Common Mistakes — Reserved Space

## Mistake 1: Leaving balloon pods with same priority as real workloads

**Wrong approach:** Balloon pod has same priority as real workloads — real pods can't preempt it

**Correct approach:** Balloon pods must have LOW priority so real workloads can displace them
