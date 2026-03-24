# Node Pressure

## What Was Broken
The memory-hog pod had a memory limit of 2Gi and ran a command that allocated 1GB. The node hit memory eviction threshold and kubelet began evicting BestEffort/Burstable pods to reclaim memory.

## The Fix
Fix the memory limit to a realistic value and fix the command. Monitor with kubectl top pods.

## Why It Matters
Kubelet eviction order: BestEffort (no requests/limits), then Burstable (limits > requests), then Guaranteed (requests == limits). Set both requests and limits equal (Guaranteed QoS) for critical pods to survive evictions.

## Pro Tip
Set eviction thresholds in kubelet config: evictionHard: memory.available: 500Mi — kubelet evicts if available free memory drops below 500Mi. Check current thresholds: kubectl get node <name> -o yaml | grep evictionHard.

## Concepts
memory pressure, eviction, kubelet, QoS, eviction thresholds
