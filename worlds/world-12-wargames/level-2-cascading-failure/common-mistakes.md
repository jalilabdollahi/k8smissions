# Common Mistakes — Domino Effect

## ❌ Restarting the wrong service
When multiple services are unhealthy, triage from the bottom of the dependency chain upward.

## ❌ Not checking deployment replicas
Pods won't exist if replicas:0 — don't only look at pod status.
