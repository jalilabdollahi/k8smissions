## What was broken

`audit-gw` is a NodePort Service with `externalTrafficPolicy: Local`, which keeps the real client address by sending traffic only to pods on the node it arrived at. Both pods had been placed on one worker by a leftover `podAffinity` on the hostname, so the other worker had no local endpoint and silently dropped connections.

## The evidence

`kubectl get pods -o wide` showed both pods on the same node, while the Service YAML showed `externalTrafficPolicy: Local`. A call to the pod-less node timed out instead of being refused, because kube-proxy drops, not rejects, in that case. The response body (`caller=...`) is what the auditors read: it shows the address nginx sees.

## Why Kubernetes behaves this way

With `Cluster` (the default) a node may forward NodePort traffic to any pod, so it must masquerade the source to get replies back through itself; the pod sees the node's address. `Local` avoids the extra hop and the masquerade, at the cost that every node you advertise must host an endpoint. The two settings trade reachability for source-address fidelity, and no Service-side setting gives both.

## The fix

Fix the placement: remove the affinity that groups the pods and add a `topologySpreadConstraints` on `kubernetes.io/hostname`. Switching to `Cluster` passes the reachability check and fails the source check. A required `podAntiAffinity` also separates the pods, but it counts the old ReplicaSet's pods during the rollout and can leave the new pods Pending.

## In production

Load balancers use the Service's `healthCheckNodePort` to send traffic only to nodes with endpoints, which hides this failure. A DaemonSet is a common choice for per-node gateways.

## Commands worth remembering

- `kubectl get pods -l <selector> -o wide`
- `kubectl get svc <name> -o jsonpath='{.spec.externalTrafficPolicy}'`
- `kubectl explain pod.spec.topologySpreadConstraints`
