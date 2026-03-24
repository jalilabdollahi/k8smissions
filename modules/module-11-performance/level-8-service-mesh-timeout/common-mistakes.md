# Common Mistakes — Silent Timeout

## Mistake 1: Removing all timeouts from the VirtualService

**Wrong approach:** No timeout means requests can hang indefinitely — exhausting connection pools and cascading failures

**Correct approach:** Set realistic timeouts based on SLO requirements; never remove them entirely
