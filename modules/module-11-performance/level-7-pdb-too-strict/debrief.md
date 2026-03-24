# Deployment Stuck

## What Was Broken
PDB required all 3 replicas available (minAvailable: 3). A 3-replica Deployment = 0 allowed disruptions. Rolling update evicts one pod at a time — each eviction was blocked by the PDB.

## The Fix
Lower minAvailable to 2 (or use maxUnavailable: 1) to allow rolling updates while still ensuring high availability.

## Why It Matters
PDB sizing rule: minAvailable should be replicas - maxUnavailable (from rolling update strategy). If rollingUpdate maxUnavailable: 1, then PDB minAvailable: replicas-1. They should be consistent to allow updates to proceed.

## Pro Tip
Use percentage-based PDB for large Deployments: minAvailable: 75% means at least 75% of pods must be available. Scales automatically as replica count changes.

## Concepts
PodDisruptionBudget, minAvailable, maxUnavailable, rolling update, disruption budget
