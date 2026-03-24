# Critical Pods Can't Schedule

## Situation
Cluster at capacity with low-priority dev pods. Critical API pod can't schedule (Insufficient CPU).

## Successful Fix
Create PriorityClass "high-priority" (value: 1000000) and assign to critical pod spec

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Critical Pods Can't Schedule.

## Concepts
PriorityClass, preemption, pod priority values, PriorityClass.globalDefault, scheduling order
