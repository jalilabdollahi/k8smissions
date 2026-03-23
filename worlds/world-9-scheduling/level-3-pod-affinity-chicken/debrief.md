# Chicken and Egg

## What Was Broken
The pod had requiredDuringScheduling podAffinity for a 'tier: cache' pod that didn't exist. The scheduler couldn't find any valid node — hard requirement, no matching pods.

## The Fix
Use preferredDuringScheduling for 'nice to have' co-location. Only use required when the workload genuinely cannot function without the affinity.

## Why It Matters
requiredDuringScheduling is the scheduling equivalent of a required toleration. Use it carefully. Prefer soft affinity (preferred) for optimization, hard affinity (required) only for functional requirements like accessing a local socket, NUMA memory.

## Pro Tip
Check scheduler decisions: kubectl describe pod <name> - the 'Events' section shows exactly why each node was rejected by the scheduler.

## Concepts
podAffinity, requiredDuringScheduling, preferredDuringScheduling, scheduling deadlock, affinity
