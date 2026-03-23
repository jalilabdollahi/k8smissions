# Common Mistakes — Slow Admission

## Mistake 1: Increasing timeoutSeconds to avoid failures

**Wrong approach:** Raising timeout to 60s — maximum is 30s and higher timeouts make performance worse

**Correct approach:** Fix the webhook's internal performance; don't compensate with long timeouts
