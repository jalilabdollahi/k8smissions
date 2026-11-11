## What was broken

Two unrelated mistakes sat on one Service. The Ingress `gateway` referenced backend port `web`, a name the Service does not have, so ingress-nginx had no upstream and returned 503. And the Service's `metrics` port had been copied from a StatsD example with `protocol: UDP`, so TCP connections to `gateway:9090` were refused even though the pods listen on 9090 over TCP.

## The evidence

`kubectl describe ingress gateway` showed `web` in the backend with an error about the missing port, and the controller log said the Service has no port named `web`. `kubectl get svc gateway -o yaml` showed `protocol: UDP` on the second port, easy to miss because everything else (name, port, targetPort) was right.

## Why Kubernetes behaves this way

Ports on a Service are identified by name and number plus protocol. A multi-port Service requires names, and consumers (Ingress backends, other Services' `targetPort`s, ServiceMonitors) refer to them. kube-proxy programs the rules per protocol, so a UDP Service port never accepts a TCP connection. Neither object reports an error: both are valid objects with the wrong meaning.

## The fix

Point the Ingress at `http` (or number 80) and set `protocol: TCP` on `metrics`. Deleting the metrics port would satisfy the Ingress and break monitoring.

## In production

Name every port of a multi-port Service and reference by name consistently. Add a synthetic check for each port that matters, not just the user-facing one.

## Commands worth remembering

- `kubectl describe ingress <name>`
- `kubectl get svc <name> -o jsonpath='{range .spec.ports[*]}{.name}{" "}{.port}{"/"}{.protocol}{"\n"}{end}'`
- `kubectl logs -n ingress-nginx deploy/ingress-nginx-controller`
