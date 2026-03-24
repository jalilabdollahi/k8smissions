# Node Under Pressure

## Situation
Pods randomly evicted from a node. Node shows MemoryPressure condition = True.

## Successful Fix
kubectl describe node → identify pressure condition Identify and remove / limit high-memory pods OR cordon node and reschedule workloads

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Node Under Pressure.

## Concepts
Node conditions (MemoryPressure, DiskPressure, PIDPressure), eviction threshold, cordon/drain, node lifecycle
