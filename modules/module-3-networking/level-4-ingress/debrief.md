# Ingress Path Mismatch

## Situation
Ingress created for path /api but the backend service is exposed at /v1/api. All requests return 404.

## Successful Fix
Update Ingress path to /v1/api  OR add path rewriting annotation

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Ingress Path Mismatch.

## Concepts
Ingress rules, pathType (Exact/Prefix/ImplementationSpecific), backend service, nginx-ingress annotations
