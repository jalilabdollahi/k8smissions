# Zero-Downtime Gone Wrong

## Situation
Deployment strategy has maxUnavailable: 100% causing all pods to be terminated before new ones start — full outage.

## Successful Fix
Set maxUnavailable: 1 (or "25%") and maxSurge: 1

## What To Validate
Rolling update completes with at least 1 pod always Running

## Why It Matters
Recreate vs RollingUpdate, surge vs unavailable tradeoffs

## Concepts
RollingUpdate strategy, maxUnavailable, maxSurge, Recreate
