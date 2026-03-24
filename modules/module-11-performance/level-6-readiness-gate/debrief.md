# Traffic to Cold Pods

## What Was Broken
No readiness probe was defined. Kubernetes marked new pods as Ready as soon as the container started. The JVM and Spring Boot needed 25-30 seconds to initialize — all requests during this window received 503 errors.

## The Fix
Add a readiness probe with appropriate initialDelaySeconds to delay traffic until the app is truly ready.

## Why It Matters
For apps with variable startup times, use startupProbe instead of initialDelaySeconds. startupProbe runs until it succeeds, then readinessProbe takes over. This handles 'sometimes slow to start' scenarios without setting initialDelaySeconds too high.

## Pro Tip
Production readiness endpoint: expose /health/ready that checks all dependencies (DB connection, cache, config loaded). Return 503 if any critical dependency is unavailable — this prevents traffic to a degraded pod.

## Concepts
readiness probe, initialDelaySeconds, traffic routing, JVM startup, health checks
