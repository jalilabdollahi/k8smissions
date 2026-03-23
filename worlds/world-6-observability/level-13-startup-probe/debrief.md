# The Slow Starter

## What Was Broken
The liveness probe had only 10s initial delay and killed the container after ~40s total (10 + 3×10). The app needed 120s to create `/tmp/ready`. Every boot attempt was killed mid-startup.

## The Fix
Add a `startupProbe` with `failureThreshold × periodSeconds` exceeding the max startup time. While the startupProbe is running, the liveness probe is disabled — once startupProbe passes, liveness takes over.

## Why It Matters
startupProbe was added in Kubernetes 1.16 specifically for this problem. Before it, engineers set enormous `initialDelaySeconds` on liveness probes — this delays problem detection during restarts after genuine failures. startupProbe separates 'booting' from 'running health check'.

## Pro Tip
Formula: `startupProbe.failureThreshold × startupProbe.periodSeconds` = max startup window. For an app that boots in up to 120s: `failureThreshold: 30, periodSeconds: 5` gives a 150s window.

## Concepts
startupProbe, liveness probe, slow boot, initialDelaySeconds, probe hierarchy
