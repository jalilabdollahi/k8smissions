# Common Mistakes — No Room

## Mistake 1: Setting requests: {} empty

**Wrong approach:** No resource requests means pods count as zero — the scheduler doesn't account for them accurately

**Correct approach:** Always set resource requests; use VPA to auto-tune them
