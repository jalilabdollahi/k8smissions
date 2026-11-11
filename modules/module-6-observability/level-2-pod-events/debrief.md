## What was broken

The Deployment's pod template names `serviceAccountName: billing-sa`, but no such ServiceAccount exists in the namespace. Admission rejects every pod the ReplicaSet tries to create, so no pod ever exists.

## The evidence

`kubectl get pods` was empty, so `describe pod` and `kubectl logs` had nothing to work on. `kubectl get deploy` showed `0/2`. The reason was an event of type Warning, reason `FailedCreate`, attached to the ReplicaSet (`kubectl describe rs`), reading `serviceaccount "billing-sa" not found`. Events belong to the object whose controller hit the problem, not to the Deployment you applied.

## Why Kubernetes behaves this way

The chain is Deployment, ReplicaSet, Pod. The ReplicaSet controller calls the API to create pods and, when the call fails, records an event on itself and retries with a growing delay. That backoff is why a fix can take a little while to show. Nothing is deleted or rolled back; the controller keeps trying to reach the desired state.

## The fix

Create the missing ServiceAccount. Pointing the template at `default` would start the pods but change the identity the workload runs under, and creating pods by hand would leave the Deployment at `0/2`.

## In production

Create service accounts together with the workloads that use them (same chart or Kustomization), and alert on `FailedCreate` events. Events expire after about an hour, so read them early.

## Commands worth remembering

- `kubectl get events --sort-by=.lastTimestamp`
- `kubectl describe rs -l <selector>`
- `kubectl get events --field-selector type=Warning`
