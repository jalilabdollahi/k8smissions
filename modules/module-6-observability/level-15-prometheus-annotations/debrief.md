## What was broken

The `prometheus.io/*` annotations existed, but on the `payments-api` Deployment's own metadata. The scraper discovers pods, and a pod only has the annotations of its pod template. Even once moved, the copied values pointed to a port and path from a different framework (8080, `/actuator/prometheus`) while this app serves metrics on 9102 at `/metrics`.

## The evidence

`/targets` on prom-lite had no `payments-api` entry, but did list the scraper itself, so discovery worked. `kubectl get pod -o jsonpath='{.metadata.annotations}'` on a payments-api pod was empty. After the annotations were on the pods the target appeared as `down` with `HTTP Error 404: Not Found` and the URL it tried; the application's log and the pod's `ports` named the real port.

## Why Kubernetes behaves this way

`metadata` on a Deployment describes the Deployment; `spec.template.metadata` is copied onto every pod. Kubernetes never propagates object annotations to children. Annotations are also a `map[string]string`: an unquoted `true` or `9102` is a boolean or number in YAML, and the API server rejects it. A scrape annotation is only a convention: nothing in the cluster checks it, so a wrong port or path produces no error until a scraper tries it.

## The fix

Put `prometheus.io/scrape: "true"`, `prometheus.io/port: "9102"` and `prometheus.io/path: /metrics` in the pod template, then verify with the scraper's own view, not the manifest.

## In production

Prometheus's Kubernetes service discovery uses the same pod-level annotations through relabelling rules, or a `PodMonitor` with the Prometheus Operator. Alert on `up == 0` per job, which would have flagged the problem.

## Commands worth remembering

- `kubectl get pod <pod> -o jsonpath='{.metadata.annotations}'`
- `kubectl patch deploy <name> --type=merge -p '{"spec":{"template":{"metadata":{"annotations":{...}}}}}'`
- `kubectl get pod <pod> -o jsonpath='{.spec.containers[*].ports}'`
