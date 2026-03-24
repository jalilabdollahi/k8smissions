# NodePort Not Reachable

## Situation
NodePort service created, but the nodePort value is within the reserved range (<30000). Access fails.

## Successful Fix
Set nodePort: 30080 (or remove to let k8s assign)

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for NodePort Not Reachable.

## Concepts
NodePort range 30000-32767, external access, port forwarding
