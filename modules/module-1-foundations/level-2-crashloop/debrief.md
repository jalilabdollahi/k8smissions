## What was broken

Pod `rates-proxy` has two containers: `app`, a small python server meant to sit behind the proxy, and `edge`, an nginx that listens on 80 and forwards to `127.0.0.1:8080`. Somebody started the app on port 80 instead of 8080. Containers in a pod share one network namespace, so the app took port 80 first and nginx could not bind it.

## The evidence

`READY 1/2` pointed at one container. `kubectl logs <pod>` without `-c` showed the app, which was fine and misleading, because kubectl picks the first container. `kubectl logs <pod> -c edge` showed `bind() to 0.0.0.0:80 failed (98: Address in use)`, and `describe pod` showed `edge` in `CrashLoopBackOff` with a growing restart count.

## Why Kubernetes behaved this way

A pod is one network identity: one IP, one set of ports, one `localhost`. That is what makes sidecars and proxies work, and it is also why two containers cannot listen on the same port. Because the pod never became fully Ready, the Service had no endpoints for it.

## The fix

Start the app on the port the proxy forwards to (8080). The change goes into the Deployment's pod template, so the rollout creates new pods with no back-off history.

## In production

Decide the port map of a multi-container pod up front and write it in the manifest comments. Back-off for a crashing container grows up to five minutes, so after a fix `kubectl delete pod` (or a rollout) gets you a fresh start faster than waiting.

## Commands worth remembering

- `kubectl logs <pod> -c <container>` and `--all-containers`
- `kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[*].name}'`
- `kubectl exec <pod> -c <container> -- netstat -ltn`
