# The Aggregation Gap

## What Was Broken
The `operator-role` ClusterRole uses `aggregationRule` to auto-collect rules from ClusterRoles with label `rbac.example.io/aggregate-to-operator: true`. The source ClusterRole had the wrong label (`aggregate-to-viewer`) so the permissions were never aggregated.

## The Fix
Add the correct label to the source ClusterRole matching the `clusterRoleSelectors` in the aggregating role.

## Why It Matters
ClusterRole aggregation is how Kubernetes builds the built-in `view`, `edit`, and `admin` roles. Adding label `rbac.authorization.k8s.io/aggregate-to-view: 'true'` to any ClusterRole automatically extends the `view` role. Operators use this pattern to add CRD permissions without modifying system roles.

## Pro Tip
Verify aggregation worked: `kubectl get clusterrole operator-role -o yaml` should show the merged rules in `.rules[]` — Kubernetes fills this in automatically when the selector matches.

## Concepts
ClusterRole, aggregationRule, RBAC aggregation, label selector, built-in roles
