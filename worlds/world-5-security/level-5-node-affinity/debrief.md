# Node Affinity Mismatch

## Situation
Pod requires nodeAffinity for node with label zone=gpu-zone. No nodes have that label. Pod stuck in Pending.

## Successful Fix
Either remove affinity OR label a node: kubectl label node <name> zone=gpu-zone

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Node Affinity Mismatch.

## Concepts
requiredDuringSchedulingIgnoredDuringExecution, preferredDuringScheduling, labelSelector, matchExpressions
