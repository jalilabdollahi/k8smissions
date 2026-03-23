# Slow Memory Leak

## What Was Broken
No memory limit on the leaky pod. Over time, the pod consumed all available node memory, triggering node memory pressure. kubelet evicted other pods to reclaim memory — the leaky pod was the cause but innocent pods paid the price.

## The Fix
Add a memory limit. The limit caps blast radius: when the leak fills the limit, only this pod is OOMKilled, not other pods on the node.

## Why It Matters
Memory leak debugging: kubectl top pod over time, heap dumps (app-specific), memory profilers. Short-term: memory limit + OOMKill gives a natural restart cycle. Long-term: fix the leak.

## Pro Tip
Set memory alert: if a pod's memory usage is consistently above 80% of its limit, you'll hit OOMKill. Alert at 80% and investigate before it becomes an incident.

## Concepts
memory leak, OOMKilled, memory limit, node pressure, blast radius
