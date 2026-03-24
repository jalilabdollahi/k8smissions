# Too Eager

## Situation
Pods receive traffic immediately on start before they finish initializing, causing 502 errors. No readiness probe defined.

## Successful Fix
Add readinessProbe httpGet /ready port 8080 with initialDelaySeconds: 10, periodSeconds: 5

## What To Validate
Pods show Ready 1/1 only after startup; no 502s during rollout

## Why It Matters
How readiness controls service endpoints, graceful rollouts

## Concepts
readinessProbe vs livenessProbe, pod readiness gates, service endpoint management
