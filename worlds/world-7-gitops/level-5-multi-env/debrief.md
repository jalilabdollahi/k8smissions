# Dev Config in Production

## Situation
Production deployment is using development values: debug logging enabled, replicas=1, no resource limits. Kustomize overlay wasn't applied correctly.

## Successful Fix
Apply production overlay which sets LOG_LEVEL=info, replicas=3, cpu limit=500m, memory limit=512Mi

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Dev Config in Production.

## Concepts
Environment promotion, config drift, GitOps single source of truth, Kustomize strategic merge patches
