# Common Mistakes — Never Ready

## Mistake 1: Using the same path for readiness and liveness

**Wrong approach:** Both probes check /healthz — liveness restarts, readiness removes. If / is up but /healthz 404s both probes fail

**Correct approach:** Use separate paths: readiness on /ready (checks dependencies), liveness on /live (just is-process-alive)

## Mistake 2: Setting initialDelaySeconds too low

**Wrong approach:** Low delay causes probes to fail before app fully starts, triggering restart loops

**Correct approach:** Set initialDelaySeconds to be longer than your slowest observed startup time
