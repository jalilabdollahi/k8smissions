## What was broken

`status-page` was a NodePort Service with an automatically chosen port, which the runbook and firewall could not use. Pinning it to 30080 fails because the decommissioned Service `legacy-status` still owns that port.

## The evidence

The patch fails with `provided port is already allocated`. That message does not name the owner, so you have to search: `kubectl get svc -A` shows a second Service with `80:30080/TCP`, labelled `decommissioned=true` and with no endpoints.

## Why Kubernetes behaves this way

The API server keeps a cluster-wide allocation map for the node port range (30000-32767 by default). Every NodePort Service takes a port from it, whether or not any pod is behind the Service. An empty, forgotten Service holds its port forever, and kube-proxy opens that port on every node.

## The fix

Release first, then claim: delete (or move) `legacy-status`, then set `nodePort: 30080` on `status-page`. The order matters because the allocation check happens when you write the Service.

## In production

Leave `nodePort` unset unless an outside party depends on a number, and record pinned ports somewhere. Before deleting a Service, check that nothing outside the cluster still sends traffic to its port. A cloud load balancer or firewall rule often does.

## Commands worth remembering

- `kubectl get svc -A -o wide`
- `kubectl get svc -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name} {.spec.ports[*].nodePort}{"\n"}{end}'`
- `kubectl explain service.spec.ports`
