# Wrong Probe, Wrong Job

## Situation
A liveness probe is checking /api/v1/ready (readiness logic). When the app is warming up, liveness kills and restarts it — infinite loop. The fix is to use readiness for warmup checks.

## Successful Fix
Move the slow check to readinessProbe, use a lightweight /healthz for livenessProbe

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Wrong Probe, Wrong Job.

## Concepts
Liveness vs readiness vs startup probe responsibilities, probe endpoints, startupProbe to delay liveness checks
