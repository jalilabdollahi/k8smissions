# Runbook: DB Migration Rollout

## Situation
Player must execute a safe database migration rollout: 1. Scale down app to 0 replicas 2. Apply DB migration job (initContainer pattern) 3. Verify migration job completes successfully 4. Scale app back up All while maintaining data integrity and namespace quota.

## Successful Fix
Fix Job spec, run in correct order, validate each step

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Runbook: DB Migration Rollout.

## Concepts
Kubernetes Jobs, initContainers for DB migration, runbook execution, ordered operations, Job completions/backoffLimit
