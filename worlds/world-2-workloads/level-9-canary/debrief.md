# Off-Balance Canary

## Situation
Canary deployment exists but replica ratio is 50/50 instead of 90/10. Too much traffic going to the untested canary.

## Successful Fix
stable: replicas: 9, canary: replicas: 1 (10% canary)

## What To Validate
90% requests hit stable, ~10% hit canary

## Why It Matters
Canary via replicas vs Ingress weights, progressive delivery, feature flags

## Concepts
Canary deployments, traffic splitting via replicas, gradual rollout, risk management
