# Maintenance is Stuck

## Situation
PodDisruptionBudget requires minAvailable: 5 but Deployment only has 2 replicas. Node drain fails.

## Successful Fix
Set PDB minAvailable: 1 OR scale Deployment replicas to 6+

## What To Validate
kubectl drain succeeds without error

## Why It Matters
PDB purpose for cluster upgrades, availability guarantees

## Concepts
PodDisruptionBudget, voluntary disruption, node drain, minAvailable vs maxUnavailable
