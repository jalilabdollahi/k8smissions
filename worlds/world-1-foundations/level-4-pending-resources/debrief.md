# Too Greedy

## Situation
Pod stuck in Pending. It requests 100 CPUs — far more than any node has available.

## Successful Fix
Set cpu request to "100m" (100 millicores)

## What To Validate
Pod scheduled and Running

## Why It Matters
Explain requests vs limits, how scheduler uses requests, QoS classes (Guaranteed / Burstable / BestEffort)

## Concepts
resource requests, resource limits, scheduling, millicores
