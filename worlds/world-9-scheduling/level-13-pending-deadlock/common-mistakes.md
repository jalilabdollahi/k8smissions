# Common Mistakes — Scheduler Deadlock

## Mistake 1: Deleting the webhook immediately

**Wrong approach:** Deleting the webhook removes security policy — understand the webhook's purpose first

**Correct approach:** Change to failurePolicy: Ignore temporarily, then fix the webhook service properly
