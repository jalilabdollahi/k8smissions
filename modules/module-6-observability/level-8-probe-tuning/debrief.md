# App Takes 60s to Start

## Situation
A Java Spring Boot app takes ~60 seconds to start. Liveness probe fires at 10s, kills the pod, restart loop.

## Successful Fix
Option A: Increase initialDelaySeconds: 90 Option B (better): Add startupProbe with failureThreshold: 30, periodSeconds: 5 (= 150s max wait)

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for App Takes 60s to Start.

## Concepts
startupProbe, initialDelaySeconds, failureThreshold, periodSeconds, probe math, slow-start applications
