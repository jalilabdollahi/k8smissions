# Hot Node

## What Was Broken
The Descheduler's LowNodeUtilization strategy had enabled: false. Without the descheduler, pods placed on a previously empty node never migrate as the cluster grows — imbalance accumulates.

## The Fix
Enable LowNodeUtilization strategy. The descheduler evicts pods from over-utilized nodes so the scheduler can place them on under-utilized nodes.

## Why It Matters
The Descheduler only evicts — it doesn't place pods. The scheduler places evicted pods. PodDisruptionBudgets limit max evictions per application. Combine both for safe rebalancing.

## Pro Tip
Descheduler strategies: LowNodeUtilization (balance load), RemoveDuplicates (spread replicas), RemovePodsViolatingInterPodAntiAffinity (fix anti-affinity violations since scheduling). Run as CronJob for continuous rebalancing.

## Concepts
Descheduler, LowNodeUtilization, pod eviction, rebalancing, node utilization
