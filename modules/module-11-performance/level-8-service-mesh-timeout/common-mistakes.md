**Editing the ConfigMap and stopping there.** `kubectl edit configmap envoy-config` changes the file, and `kubectl get cm` shows the new value, but the running Envoy still holds `3s`. The 504s continue until the pod is restarted.

**Blaming the app.** Direct calls to the app container succeed, and the app has no timeouts of its own. Check where the 504 is generated: the Envoy log and its stats say so.

**Setting `timeout: 0s`.** It makes the 504s go away, but a backend that never answers now ties up the client for as long as it likes. The proxy is supposed to cut off hung requests; keep a finite value above the slowest real request (and below what your clients will wait).

**Removing the sidecar from the path.** Pointing the Service at port 9000 of the app passes the latency test but removes the proxy that the platform team depends on for limits and metrics. The validator checks that the requests go through Envoy's upstream cluster.
