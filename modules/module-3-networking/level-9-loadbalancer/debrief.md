# LoadBalancer Stuck Pending

## Situation
Service type LoadBalancer stays in <pending> on local kind cluster. No cloud provider to provision external IP.

## Successful Fix
Change to NodePort for local access

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for LoadBalancer Stuck Pending.

## Concepts
Service types, cloud provider integration, MetalLB for on-prem, kind limitations
