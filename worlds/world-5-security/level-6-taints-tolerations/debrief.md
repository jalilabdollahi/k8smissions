# Tainted Nodes

## Situation
All nodes tainted dedicated=gpu:NoSchedule. Regular app pods have no toleration — stuck in Pending.

## Successful Fix
Add tolerations: [{key: dedicated, operator: Equal, value: gpu, effect: NoSchedule}]

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Tainted Nodes.

## Concepts
Taints (NoSchedule, PreferNoSchedule, NoExecute), tolerations, taint-based eviction, node pools
