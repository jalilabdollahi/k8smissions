# Cross-Namespace Dead End

## Situation
Frontend (namespace: frontend-ns) calls backend service using short name "backend-svc". Fails — wrong namespace.

## Successful Fix
DB_HOST=backend-svc.backend-ns.svc.cluster.local

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Cross-Namespace Dead End.

## Concepts
Cross-namespace DNS, FQDN format, namespace isolation
