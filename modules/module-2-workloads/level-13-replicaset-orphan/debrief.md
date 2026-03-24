# The Orphan

## What Was Broken
A ReplicaSet with no `ownerReferences` had been left behind after its parent Deployment was deleted. Without an owner, Kubernetes garbage collection never removes it. The RS continued maintaining 2 pod replicas indefinitely.

## The Fix
Delete the orphaned ReplicaSet with `kubectl delete replicaset <name>`. Kubernetes cascades the deletion to its pods.

## Why It Matters
Orphaned ReplicaSets happen when a Deployment is force-deleted or deleted with `--cascade=orphan`. Always check for lingering RS after cleaning up Deployments: `kubectl get rs -n <ns>`. The RS whose `DESIRED` matches pod count but has no Deployment parent is the culprit.

## Pro Tip
To find orphaned objects across types: `kubectl get replicaset,statefulset,daemonset -o json | jq '.items[] | select(.metadata.ownerReferences == null) | .metadata.name'`

## Concepts
ReplicaSet, ownerReferences, garbage collection, cascade deletion, Deployment
