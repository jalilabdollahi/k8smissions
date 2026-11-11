## What was broken

`settlement-gateway` copied its probes from the web-service template: `httpGet /healthz` and `/ready`. Neither container serves HTTP. `tcp-echo` speaks a line protocol and answered the kubelet's `GET` with `ERR unknown command`, which the kubelet rejected as a malformed response. `ticker` listens on no port, so its probes were refused outright.

## The evidence

`kubectl describe pod` printed `Liveness probe failed` and `Readiness probe failed` events with different messages per container: an HTTP parse error for one and `connection refused` for the other. The `tcp-echo` log also recorded the odd commands it received (`'GET /healthz HTTP/1.1'`), which shows exactly what the kubelet sent.

## Why Kubernetes behaves this way

The kubelet runs probes itself, with the handler you configure. httpGet counts only a 2xx or 3xx HTTP reply as success; tcpSocket succeeds when the connection opens; exec succeeds when the command exits 0; grpc needs a server that implements the gRPC health protocol. A failed liveness probe restarts the container and a failed readiness probe removes it from Services, so the wrong handler produces both symptoms.

## The fix

Use tcpSocket for the listener, and an exec probe for the port-less worker that checks the heartbeat file its loop refreshes. An exec probe such as `true` would always pass but proves nothing, so the validator runs your command and looks for the heartbeat.

## In production

Choose the handler by what proves the process is doing its job, not by what is easiest to type. Use gRPC probes for gRPC servers; a tcpSocket probe only proves something accepted the connection.

## Commands worth remembering

- `kubectl explain pod.spec.containers.livenessProbe`
- `kubectl describe pod <pod>`
- `kubectl exec <pod> -c <container> -- <probe command>; echo $?`
