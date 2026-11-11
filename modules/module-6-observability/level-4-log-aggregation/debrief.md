## What was broken

`quote-service` runs two containers, `metrics-proxy` and `app`, and both were configured to listen on port 8080. Containers in a pod share one network namespace, so only one of them can own the port. The sidecar started first and kept it; the app slept through its warm-up, tried to bind, failed with `Address already in use` and exited, and the kubelet restarted it, forever.

## The evidence

`kubectl logs quote-service` with no `-c` returns the log of the pod's default container, here the healthy proxy, which is why everything looked fine. `kubectl get pod` showed restarts on the `app` container only. `kubectl logs -c app --previous` showed the real error from the run that had just crashed, because the current run had barely started.

## Why Kubernetes behaves this way

A pod is one network identity: one IP, one port space. Sidecars are convenient exactly because they share it, and that is also how they collide. The kubelet restarts failed containers individually with a back-off, so the sidecar stayed up while the app looped.

## The fix

Give the sidecar its own port (or move the app and update the Service's `targetPort`). Either side may move; the validator checks that each answers on a separate port.

## In production

Reserve a documented port range for sidecars, name your container ports, and check `kubectl logs --all-containers --prefix` first when a multi-container pod restarts. Log shippers keep `--previous` data only until the container is restarted again.

## Commands worth remembering

- `kubectl logs <pod> -c <container> --previous`
- `kubectl logs <pod> --all-containers --prefix`
- `kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[*].restartCount}'`
