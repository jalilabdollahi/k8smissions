# Quota Breached

## What Was Broken
The namespace had a `ResourceQuota` capping total CPU requests at 500m. The pod requested 400m CPU — leaving only 100m for all other pods. Any additional pod requesting >100m CPU was blocked.

## The Fix
Reduce the pod's `resources.requests` to fit within the remaining quota, or delete the over-requesting pod. Always right-size pods to actual usage, not worst-case estimates.

## Why It Matters
ResourceQuota enforces fairness in multi-tenant clusters. Without it, one team's runaway deployment starves others. Monitor quota usage with `kubectl describe quota -n <ns>`. Prometheus can alert when quota usage exceeds 80%.

## Pro Tip
ResourceQuota also limits: `pods`, `secrets`, `configmaps`, `services`, `persistentvolumeclaims`. Set quotas on all of these in shared namespaces.

## Concepts
ResourceQuota, namespace quota, CPU requests, memory limits, multi-tenancy
