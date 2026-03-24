# Running as Root

## Situation
Security scanner flags the pod — container runs as root (uid 0). Policy requires non-root. Pod fails with "container has runAsNonRoot and image will run as root".

## Successful Fix
Add securityContext: runAsNonRoot: true, runAsUser: 1000, allowPrivilegeEscalation: false

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Running as Root.

## Concepts
SecurityContext, runAsNonRoot, runAsUser, privilege escalation, CIS Kubernetes Benchmark
