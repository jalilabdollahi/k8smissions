# Bad Update — Roll Back!

## Situation
Deployment updated to a non-existent image (nginx:broken-tag). All pods in ImagePullBackOff. Must rollback.

## Successful Fix
kubectl rollout undo deployment/rollback-app -n k8smissions

## What To Validate
All pods Running on previous revision

## Why It Matters
Deployment revision history, --to-revision flag, change-cause

## Concepts
kubectl rollout undo/history/status, deployment revision, annotations
