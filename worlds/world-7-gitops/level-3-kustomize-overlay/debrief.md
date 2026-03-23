# Wrong Overlay Applied

## Situation
Developer accidentally applied the production overlay to the staging cluster. Production replicas (10) running in staging. Resources: base/, overlays/staging/, overlays/production/

## Successful Fix
kubectl delete -k overlays/production kubectl apply -k overlays/staging

## What To Validate
Deployment replicas = 2 (staging), not 10 (production)

## Why It Matters
Review how the fix changed the cluster behavior for Wrong Overlay Applied.

## Concepts
Kustomize base/overlay pattern, kustomization.yaml, patches, strategic merge patch, replicas patch
