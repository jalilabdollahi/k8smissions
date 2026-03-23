# Lost in Transit

## What Was Broken
The NodePort Service used `externalTrafficPolicy: Local`. When traffic arrives at a node that has no matching pod, kube-proxy drops it immediately — no forwarding, no error. This causes intermittent failures depending on which node the load balancer routes to.

## The Fix
Change `externalTrafficPolicy: Cluster` (the default). kube-proxy then forwards traffic across nodes to any healthy pod, using SNAT.

## Why It Matters
`Local` is valuable when client IP preservation matters (logs, geo-filtering) and pods are DaemonSet-deployed (one per node). `Cluster` is safer for Deployments with fewer replicas than nodes. Know the trade-off before choosing.

## Pro Tip
Check `kubectl describe endpoints <svc-name>` to see which nodes have pods. If pods are on 2/5 nodes with Local policy, 60% of traffic silently drops.

## Concepts
Service, NodePort, externalTrafficPolicy, Local, Cluster, SNAT, client IP
