# Phantom Capacity

## What Was Broken
The pod requested 5Gi from a 6Gi node. But allocatable memory (after kubelet and system reservations) was only ~4.5Gi. Kubernetes correctly rejected the pod for exceeding available allocatable space.

## The Fix
Size requests against allocatable memory, not node capacity. Reserve 10-15% headroom for node overhead.

## Why It Matters
kubelet calculates allocatable: Allocatable = Capacity - kube-reserved - system-reserved - eviction-threshold. On a 6Gi node with 500Mi reserved, allocatable might be ~5.3Gi — but existing pod usage further reduces what's available.

## Pro Tip
Always check: kubectl describe node | grep -A10 'Allocated resources' to see current consumption on each node alongside their allocatable limits.

## Concepts
allocatable, capacity, kube-reserved, system-reserved, eviction threshold
