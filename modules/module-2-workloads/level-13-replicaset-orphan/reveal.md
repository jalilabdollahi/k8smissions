## What went wrong

When a Deployment is deleted normally, Kubernetes garbage-collects the ReplicaSets it owned and the pods those ReplicaSets managed. But this ReplicaSet has no ownerReferences — either it was created directly (not via a Deployment), or ownership was severed. Without an owner, Kubernetes does not clean it up automatically.

## Fix

```bash
kubectl delete replicaset legacy-app-7d8f9 -n k8smissions
```

Deleting the ReplicaSet also deletes the pods it controls.

## Why this matters

Orphaned ReplicaSets are a common leftover from manual operations or failed migrations. They consume resources silently. `kubectl get replicasets -n <namespace>` should be part of any namespace audit — look for ReplicaSets with no corresponding Deployment.