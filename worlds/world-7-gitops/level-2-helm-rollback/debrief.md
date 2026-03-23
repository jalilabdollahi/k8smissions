# Bad Release — Roll Back Helm

## Situation
Helm release "webapp" was upgraded and all pods started crashing (bad config in the new chart version). Must rollback.

## Successful Fix
helm rollback webapp 1 -n k8smissions

## What To Validate
helm history webapp shows rollback, pods Running on v1

## Why It Matters
Review how the fix changed the cluster behavior for Bad Release — Roll Back Helm.

## Concepts
helm history, helm rollback, helm get manifest, revision history, atomic deploys
