## What was broken

Pod `report-builder` asked for `cpu: "1500"`. Kubernetes reads a bare number as whole CPU cores, so the pod requested 1500 cores. No node in the cluster has anything close to that, so the scheduler never found a place for it and the pod stayed `Pending`.

## The evidence

`kubectl get pod` showed `Pending` with no node. `kubectl logs` returned nothing because no container had ever been created. `kubectl describe pod` ended with a `FailedScheduling` event: `Insufficient cpu` for the workers, plus an untolerated taint for the control plane. `kubectl describe node` listed an Allocatable CPU of a few cores at most.

## Why Kubernetes behaved this way

The scheduler compares the pod's requests, not its actual use, to what is left of each node's Allocatable. A pod that fits nowhere is retried forever; nothing in the cluster will shrink it for you. Units matter: `500m` is half a core, `0.5` is the same, `500` is five hundred cores.

## The fix

Write the request in the unit you meant, `500m`. Fields under `spec.containers[*].resources` cannot be changed on a running pod, so delete and recreate it. Removing the request would get the pod scheduled, but then it reserves nothing and can be starved by its neighbours.

## In production

Requests are the capacity plan. Review them against `kubectl top` after a week of real usage. Newer Kubernetes versions can resize some pod resources in place, but this is not the default behaviour yet and not for every field.

## Commands worth remembering

- `kubectl describe pod <pod>` (FailedScheduling events)
- `kubectl describe node <node>` (Allocatable and Allocated resources)
- `kubectl get events --sort-by=.lastTimestamp`
