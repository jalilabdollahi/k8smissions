# Dead Endpoints

## Situation
Service has endpoints but traffic still fails. Pods are Running but not Ready — missing readiness probe.

## Successful Fix
Add readinessProbe httpGet /ready port 8080

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Dead Endpoints.

## Concepts
Readiness probe, endpoint slice, Not Ready pods, traffic routing only to Ready pods
