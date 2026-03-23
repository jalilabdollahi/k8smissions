# ArgoCD Out of Sync

## Situation
ArgoCD application shows "OutOfSync" and "Degraded". Git has updated manifests but ArgoCD auto-sync is disabled. Additionally, the target namespace doesn't exist in the cluster.

## Successful Fix
kubectl create namespace webapp-prod argocd app sync webapp-app  OR  enable auto-sync in app spec

## What To Validate
argocd app get webapp-app → Synced, Healthy

## Why It Matters
Review how the fix changed the cluster behavior for ArgoCD Out of Sync.

## Concepts
ArgoCD Application CRD, sync status, health status, auto-sync, self-heal, prune, GitOps principles
