# The Noisy Neighbour

## What Was Broken
A LimitRange required all containers to have explicit resource limits. The pod only had `requests` but no `limits` — the LimitRange rejected the pod with a Forbidden error.

## The Fix
Add `limits` to the container's `resources` block. Values must be within the LimitRange's `max`. Pods with no resources at all inherit the LimitRange defaults, but pods with partial resources (requests only) are still rejected.

## Why It Matters
LimitRanges prevent a single container monopolising node resources. They are a safety net for multi-tenant namespaces. Set them on dev namespaces to catch engineers who forget limits before deploying to production where ResourceQuota may block them entirely.

## Pro Tip
Check LimitRanges with `kubectl describe limitrange -n <ns>`. If a pod is rejected, the error message tells you exactly which constraint was violated.

## Concepts
LimitRange, resource requests, resource limits, namespace policy, multi-tenancy
