## What was broken

HPA `web-backend` could not compute CPU utilisation, so it showed `<unknown>/50%` and never scaled. The pod has two containers: the busy `web` container, which has a CPU request, and a `log-forwarder` sidecar, which does not.

## The evidence

`describe hpa` carried the line `missing request for cpu in container log-forwarder of Pod ...` in a `FailedGetResourceMetric` event, and the condition `ScalingActive` was `False`. Meanwhile `kubectl top pods` worked, which ruled out metrics-server.

## Why Kubernetes behaves this way

Utilisation is a ratio: current usage over the requested amount. With a `Resource` metric the HPA computes it for the whole pod, which means it needs a request from every container. A single container with no request makes the ratio undefined and the HPA refuses to guess, rather than scaling on partial data.

## The fix

Give the sidecar a small CPU request. Setting a request only on `web` would change nothing, because `web` was never the problem. After the new pod reports metrics, the HPA sees well over 50% and scales out.

## In production

Put requests on every container, including sidecars and init-style helpers, and consider a LimitRange default so nothing is forgotten. If one container should drive scaling, use a `ContainerResource` metric to target it directly. Also remember that the HPA owns `replicas`; do not manage them by hand.

## Commands worth remembering

- `kubectl describe hpa <name>`
- `kubectl top pods --containers`
- `kubectl set resources deployment <name> -c <container> --requests=cpu=<n>`
