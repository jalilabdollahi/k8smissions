# Blocked Deploy

## What Was Broken
The deploy-sa ServiceAccount existed but had no RBAC permissions to create or update Deployments. The kubectl apply step in the Task received 403 Forbidden.

## The Fix
Create a Role granting the needed verbs and bind it to the SA via RoleBinding.

## Why It Matters
CI/CD pipeline ServiceAccounts need more permissions than regular app SAs: create, update, delete for Deployments, Services, ConfigMaps at minimum. Scope to the deployment namespace only.

## Pro Tip
Generate a least-privilege role from your actual pipeline: run with --dry-run, capture all the 403 errors, build the role from those. Then audit quarterly.

## Concepts
Tekton, RBAC, ServiceAccount, deploy permissions, 403 Forbidden
