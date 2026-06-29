## What went wrong

Prometheus uses a pod discovery mechanism that reads annotations to find scrape targets. Without the `prometheus.io/scrape: 'true'` annotation, the pod is invisible to Prometheus — it is never added to the scrape queue regardless of what port it exposes.

## Fix

Add the three Prometheus scrape annotations to the pod metadata:

```yaml
metadata:
  name: metrics-app
  namespace: k8smissions
  labels:
    app: metrics-app
  annotations:
    prometheus.io/scrape: 'true'
    prometheus.io/port: '9090'
    prometheus.io/path: /metrics
```

## Why this matters

Prometheus' annotation-based pod discovery is configured in the Prometheus `scrape_config` with a `kubernetes_sd_configs` block. When enabled, it watches all pods in the cluster and filters to those annotated with `prometheus.io/scrape: 'true'`. The `port` and `path` annotations tell Prometheus where to make the HTTP request. This pattern is the foundation of metrics-based observability: once annotations are in place, any Prometheus-compatible dashboard (Grafana) can display the metrics without any additional configuration. For more structured metric discovery, `ServiceMonitor` resources (from the Prometheus Operator) provide a Kubernetes-native alternative to annotations.