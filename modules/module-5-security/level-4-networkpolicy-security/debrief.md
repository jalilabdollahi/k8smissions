# Locked Down Too Hard

## Situation
Security team applied default-deny-all NetworkPolicy. Frontend → backend → database chain all broken.

## Successful Fix
Add specific allow rules: - frontend → backend on port 8080 - backend → database on port 5432

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Locked Down Too Hard.

## Concepts
NetworkPolicy default-deny, ingress/egress, podSelector, namespaceSelector, port-specific rules, defense in depth
