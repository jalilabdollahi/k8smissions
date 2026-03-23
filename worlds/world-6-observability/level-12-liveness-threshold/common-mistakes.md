# Common Mistakes — Restart Storm

## Mistake 1: Removing liveness probe entirely

**Wrong approach:** Deleting the probe to stop restarts — now stuck/deadlocked pods are never recovered

**Correct approach:** Fix the probe thresholds; don't remove liveness probes from long-running services

## Mistake 2: Setting timeoutSeconds too low

**Wrong approach:** timeoutSeconds: 1 but probe command takes 2s under load — causes false failures

**Correct approach:** Set timeoutSeconds above your 99th-percentile probe response time
