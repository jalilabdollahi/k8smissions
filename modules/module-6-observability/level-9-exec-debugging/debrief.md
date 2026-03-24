# Diagnose the Live Pod

## Situation
Pod is Running but app returns 500 errors. No logs. Must exec into container and inspect the filesystem/config.

## Successful Fix
kubectl exec -it <pod> -- /bin/sh cat /app/config.json → find wrong DB_HOST value Patch the ConfigMap and restart pod

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Diagnose the Live Pod.

## Concepts
kubectl exec, ephemeral containers (kubectl debug), live debugging, configuration inspection
