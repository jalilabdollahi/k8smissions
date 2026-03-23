# Restart Storm

## What Was Broken
The liveness probe had `failureThreshold: 1` — a single missed check triggered an immediate restart. Even a momentary CPU spike causing the probe to run slowly was enough to restart the pod.

## The Fix
Set `failureThreshold` to 3 (the Kubernetes default). This allows three consecutive failures before the pod is restarted, tolerating transient slowdowns.

## Why It Matters
Kubernetes default probe settings: `initialDelaySeconds: 0`, `periodSeconds: 10`, `successThreshold: 1`, `failureThreshold: 3`, `timeoutSeconds: 1`. Only override when you understand the implications. failureThreshold: 1 makes sense for fast-fail health checks on external dependencies, rarely for the main process.

## Pro Tip
Use `kubectl get events --field-selector reason=Killing -n <ns>` to find pods restarted by liveness probes. The message will say 'Liveness probe failed'.

## Concepts
liveness probe, failureThreshold, probe tuning, restart storm, CrashLoopBackOff
