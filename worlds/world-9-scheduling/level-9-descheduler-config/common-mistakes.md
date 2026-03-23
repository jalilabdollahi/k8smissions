# Common Mistakes — Hot Node

## Mistake 1: Manually deleting pods to rebalance

**Wrong approach:** kubectl delete pod repeatedly to force rescheduling — disruptive and doesn't stay balanced

**Correct approach:** Use the Descheduler for automated, controlled rebalancing
