# No Room

## What Was Broken
The pod requested 100Gi memory — far beyond any node's allocatable memory. The scheduler checked every node and found Insufficient memory on all of them.

## The Fix
Reduce requests to match actual workload needs. Profile memory usage with kubectl top pods to set accurate requests.

## Why It Matters
Resource requests determine scheduling placement. Resource limits determine cgroup enforcement. Always set requests close to actual usage (P95 of observed consumption). Over-requesting wastes capacity; under-requesting causes scheduling drift to busy nodes.

## Pro Tip
Check actual usage: kubectl top pods -n <ns>. For new workloads start with no limits, observe with top, then set requests at P95 and limits at 2x P99.

## Concepts
resource requests, allocatable memory, Insufficient memory, scheduling, profiling
