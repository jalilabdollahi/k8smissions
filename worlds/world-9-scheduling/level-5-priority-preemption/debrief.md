# Queue Jumped

## What Was Broken
The critical workload was assigned 'low-priority' PriorityClass. With cluster resources exhausted, it queued behind low-priority pods. These pods weren't preempted because the requesting pod had equal or lower priority.

## The Fix
Change priorityClassName to 'high-priority'. The scheduler will preempt lower-priority pods if needed to free resources.

## Why It Matters
PriorityClass with preemptionPolicy: Never allows priority ordering in the queue without preemption. Use this for batch jobs that should run after interactive workloads but without interrupting running pods.

## Pro Tip
Design a PriorityClass hierarchy: system-critical (cluster infrastructure), high (prod app), medium (staging), low (batch/dev). Assign appropriately to prevent priority inversion.

## Concepts
PriorityClass, preemption, pod priority, resource contention, scheduling queue
