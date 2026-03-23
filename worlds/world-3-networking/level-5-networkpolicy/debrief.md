# NetworkPolicy Too Strict

## Situation
A NetworkPolicy blocks all ingress traffic to the backend. Frontend can't reach backend even though both are healthy.

## Successful Fix
Add ingress rule allowing traffic from frontend pod selector

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for NetworkPolicy Too Strict.

## Concepts
NetworkPolicy, default-deny, ingress rules, podSelector, namespaceSelector
