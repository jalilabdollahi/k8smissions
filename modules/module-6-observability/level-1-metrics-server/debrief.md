## What was broken

The `capacity-report` script called `/apis/metrics.k8s.io/v1/...`. The cluster only serves `metrics.k8s.io/v1beta1`, so the API server answered `404 page not found` to every request. Nothing was wrong with metrics-server, with the RBAC, or with the pod.

## The evidence

`kubectl top pods` returned numbers, so the metrics pipeline worked end to end. `kubectl get apiservices` listed `v1beta1.metrics.k8s.io` with `Available=True` and no `v1`. The pod's log held a bare 404 rather than a 403, which separates "path does not exist" from "you may not read it".

## Why Kubernetes behaves this way

Metrics-server registers itself as an aggregated API through an `APIService` object, one per group and version. The API server routes only registered versions. `kubectl` discovers the version by itself, which is why it worked while a hand-written client with a hardcoded version did not. A mounted ConfigMap changes on disk, but a Python process reads its script once at startup, so the pod had to be restarted.

## The fix

Change the version in the script to `v1beta1` and run `kubectl rollout restart` on the Deployment.

## In production

Do not hardcode API versions in clients; use a client library that does discovery, and watch for deprecations with `kubectl get --raw /metrics | grep apiserver_requested_deprecated_apis`. Metrics API samples also lag: a new pod has no metrics for about a minute.

## Commands worth remembering

- `kubectl get apiservices`
- `kubectl api-versions` and `kubectl api-resources --api-group=metrics.k8s.io`
- `kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/<ns>/pods`
