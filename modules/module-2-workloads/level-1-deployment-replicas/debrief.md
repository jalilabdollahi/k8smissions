## What was broken

Deployment `reports` asked for pods running as ServiceAccount `reports-sa`, but that ServiceAccount was never created (it was in a different manifest that did not get applied). The API server's admission step rejects a pod whose ServiceAccount does not exist, so the pods were never created at all.

## The evidence

`kubectl get deployment` showed `0/3` with no explanation, and `kubectl get pods` was empty, so `describe pod` had nothing to describe. The reason was on the ReplicaSet: a `FailedCreate` warning, `serviceaccount "reports-sa" not found`, repeated with growing gaps.

## Why Kubernetes behaves this way

A Deployment does not create pods; it owns a ReplicaSet, and the ReplicaSet creates pods. When creation is refused, the error is an Event on the ReplicaSet, not on the Deployment and not on a pod that never existed. The controller keeps retrying with back-off, which is why the fix needs no restart.

## The fix

Create the ServiceAccount: `kubectl create serviceaccount reports-sa`. The next retry succeeds and all three pods start.

## In production

Ship the ServiceAccount in the same manifest set (or chart) as the workload that uses it, and alert on `kube_deployment_status_replica_unavailable` rather than waiting for a dashboard to go blank. Missing ConfigMaps and Secrets fail differently (the pod exists but sticks in `ContainerCreating`), so remember which objects block creation and which block starting.

## Commands worth remembering

- `kubectl get rs` and `kubectl describe rs <name>`
- `kubectl get events --sort-by=.lastTimestamp`
- `kubectl create serviceaccount <name>`
