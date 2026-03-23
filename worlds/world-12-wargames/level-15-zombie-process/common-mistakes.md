# Common Mistakes — Zombie Pod

## ❌ Only adding liveness probe
Liveness restarts the pod, but between the liveness failure and restart, traffic still goes to the zombie. Add readiness too.

## ❌ Too aggressive probe settings
initialDelaySeconds too low causes healthy pods to be killed during startup.
