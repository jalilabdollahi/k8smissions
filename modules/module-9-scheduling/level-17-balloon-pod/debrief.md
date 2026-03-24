# Reserved Space

## What Was Broken
A balloon pod (using the no-op pause image) had requests of 2000m CPU and 4Gi memory. It consumed scheduling capacity without doing any real work — a technique to prevent cluster autoscaler from removing nodes.

## The Fix
Delete or shrink the balloon pod. Real workloads should take priority over capacity reservation.

## Why It Matters
Balloon pods are a legitimate technique: low-priority pods (PriorityClass with low value) that hold capacity. When a real workload needs resources, the scheduler preempts the balloon. But they must be sized correctly and marked safe-to-evict.

## Pro Tip
The proper balloon pod pattern: use PriorityClass value=0 or negative, mark safe-to-evict=true annotation, size requests to the capacity you want to reserve. Don't use them in prod without understanding cluster autoscaler interaction.

## Concepts
balloon pods, pause container, capacity reservation, cluster autoscaler, PriorityClass
