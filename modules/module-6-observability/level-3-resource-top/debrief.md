# Who's Eating All the CPU?

## Situation
Node is under CPU pressure. Multiple pods running. Find the CPU-hungry pod and scale it down or limit it.

## Successful Fix
Use kubectl top pods to identify the culprit Add resources.limits.cpu: "200m" to the greedy pod

## What To Validate
Node CPU back under 70%, other pods healthy

## Why It Matters
Review how the fix changed the cluster behavior for Who's Eating All the CPU?.

## Concepts
kubectl top, resource limits vs requests, noisy-neighbor, LimitRange to enforce defaults
