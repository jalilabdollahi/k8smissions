# Common Mistakes — SLO Breach Alert

## Mistake 1: Removing the liveness probe entirely

**Wrong approach:** No liveness probe = dead pods never restart automatically

**Correct approach:** Lower the failureThreshold; don't remove the probe — it's critical for self-healing
