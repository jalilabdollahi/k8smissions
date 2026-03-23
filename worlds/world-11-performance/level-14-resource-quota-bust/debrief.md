# Namespace Full

## What Was Broken
The namespace hit its ResourceQuota ceiling. All CPU requests in the namespace summed to 4 cores — no new pod could be scheduled. Existing pods had over-provisioned CPU requests (asking for more than they use).

## The Fix
Raise the quota ceiling or reduce existing pod requests using VPA recommendations. Both approaches are valid depending on whether the cluster has capacity.

## Why It Matters
ResourceQuota protects cluster capacity from namespace sprawl. For multi-tenant clusters: set per-namespace quotas based on team SLAs. For single-team: quotas serve as a safety net against runaway scaling.

## Pro Tip
LimitRange + ResourceQuota: use LimitRange to set default requests/limits for pods (so developers don't accidentally create pods without resource specs), and ResourceQuota to cap total namespace consumption.

## Concepts
ResourceQuota, namespace quota, resource requests, LimitRange, capacity planning
