## What was broken

`quote-api` ran http-echo with `-listen=127.0.0.1:5678`. The server answered fine, but only to clients inside the pod's own network namespace. Service traffic is delivered to the pod IP, so every connection was refused even though the pod was Running and the Service had an endpoint.

## The evidence

Nothing in Kubernetes objects said anything was wrong: the pod was Ready (there was no probe to say otherwise) and the endpoint existed. The image contains one static binary and no shell, so `kubectl exec` fails. An ephemeral container added with `kubectl debug --target=echo` shares the pod's network namespace and, with `--target`, its PID namespace. There `netstat -ltn` showed the socket on `127.0.0.1`, `wget localhost:5678` succeeded, and `/proc/1/cmdline` showed the flag that caused it.

## Why Kubernetes behaves this way

A Service is only a routing rule to `podIP:targetPort`. It cannot know which address the process bound. Loopback is private to the pod, so a loopback-only server is reachable only from its own containers. Ephemeral containers exist for exactly this: you cannot change a running pod's containers, but you can add a debugging one without restarting anything.

## The fix

Make the server listen on all interfaces (`-listen=:5678`) in the pod template. Changing the Service port would not help, because the problem is the bind address, not the port.

## In production

Add a readiness probe that connects from the kubelet's side (tcpSocket or httpGet against the pod IP); it would have caught this at rollout time. Many servers ship with a loopback default for safety.

## Commands worth remembering

- `kubectl debug <pod> -it --image=busybox:1.36 --target=<container>`
- `netstat -ltn` and `cat /proc/1/cmdline | tr '\0' ' '`
- `kubectl get endpoints <svc>` (an endpoint proves selection, not reachability)
