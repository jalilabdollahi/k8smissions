# Forbidden!

## Situation
App pod crashes with "pods is forbidden: User 'system:serviceaccount: k8smissions:app-sa' cannot list resource 'pods'". ServiceAccount exists but has no Role/RoleBinding.

## Successful Fix
Create Role (verbs: get, list, watch on pods) + RoleBinding

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
ClusterRole vs Role, why default SA should have no permissions

## Concepts
RBAC, Role, RoleBinding, ServiceAccount, least privilege
