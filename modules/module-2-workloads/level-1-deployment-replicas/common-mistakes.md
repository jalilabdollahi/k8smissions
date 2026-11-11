## Staring at `kubectl get pods`

There are no pods to look at, so `get pods`, `describe pod` and `logs` all come back empty. When a Deployment shows `0/N` with no pods, go down the ownership chain: Deployment, then ReplicaSet.

## Deleting and re-applying the Deployment

A new Deployment creates a new ReplicaSet with the same pod template, so it fails with exactly the same error. The cause is the missing object, not the Deployment.

## Scaling the Deployment up and down

The replica count is already 3 and the controller is already trying. Scaling does not remove the reason the API server refuses the pods.
